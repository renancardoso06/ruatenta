--------------------------------------------------------------------------------
-- RuAtenta - Script 3: PACKAGE PKG_RUATENTA (rotinas PL/SQL)
--
-- Automatiza os processos centrais da solucao:
--   FN_GERAR_PROTOCOLO            -> numero unico de acompanhamento
--   PR_REGISTRAR_OCORRENCIA       -> registro de solicitacao (valida, gera
--                                    protocolo, define prioridade inicial)
--   PR_ATUALIZAR_STATUS           -> acompanhamento do atendimento (valida a
--                                    transicao e registra o historico)
--   PR_APOIAR_OCORRENCIA          -> apoio da comunidade (evita duplicidade)
--   FN_ESTA_ATRASADA              -> verifica prazo vencido da ocorrencia
--   FN_TEMPO_MEDIO_RESOLUCAO      -> indicador: dias medios ate a resolucao
--   PR_INDICADORES_POR_CATEGORIA  -> indicadores por categoria (REF CURSOR)
--   PR_OCORRENCIAS_ATRASADAS      -> lista as ocorrencias fora do prazo
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_RUATENTA AS

    -- Observacao a ser gravada no historico pela trigger no proximo UPDATE de
    -- status. E preenchida e limpa por PR_ATUALIZAR_STATUS.
    G_OBSERVACAO VARCHAR2(300);

    -- Apoios necessarios para subir a prioridade (usados pela trigger)
    C_APOIOS_MEDIA CONSTANT NUMBER := 5;
    C_APOIOS_ALTA  CONSTANT NUMBER := 10;

    FUNCTION FN_GERAR_PROTOCOLO RETURN VARCHAR2;

    PROCEDURE PR_REGISTRAR_OCORRENCIA (
        p_cidadao_id    IN  NUMBER,
        p_categoria_id  IN  NUMBER,
        p_descricao     IN  VARCHAR2,
        p_latitude      IN  NUMBER,
        p_longitude     IN  NUMBER,
        p_endereco      IN  VARCHAR2,
        p_ocorrencia_id OUT NUMBER,
        p_protocolo     OUT VARCHAR2
    );

    PROCEDURE PR_ATUALIZAR_STATUS (
        p_ocorrencia_id IN NUMBER,
        p_novo_status   IN VARCHAR2,
        p_observacao    IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE PR_APOIAR_OCORRENCIA (
        p_ocorrencia_id IN  NUMBER,
        p_cidadao_id    IN  NUMBER,
        p_total_apoios  OUT NUMBER
    );

    FUNCTION FN_ESTA_ATRASADA (
        p_ocorrencia_id IN NUMBER
    ) RETURN NUMBER;

    FUNCTION FN_TEMPO_MEDIO_RESOLUCAO (
        p_categoria_id IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE PR_INDICADORES_POR_CATEGORIA (
        p_cursor OUT SYS_REFCURSOR
    );

    PROCEDURE PR_OCORRENCIAS_ATRASADAS (
        p_cursor OUT SYS_REFCURSOR
    );

END PKG_RUATENTA;
/

CREATE OR REPLACE PACKAGE BODY PKG_RUATENTA AS

    e_nao_encontrado   EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_nao_encontrado,   -20101);
    e_transicao        EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_transicao,        -20104);
    e_apoio_duplicado  EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_apoio_duplicado,  -20105);

    -- Ordem do fluxo de atendimento (indice maior = etapa mais avancada)
    FUNCTION f_ordem_status (p_status IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        RETURN CASE p_status
                   WHEN 'ABERTA'       THEN 1
                   WHEN 'EM_ANALISE'   THEN 2
                   WHEN 'EM_ANDAMENTO' THEN 3
                   WHEN 'RESOLVIDA'    THEN 4
                   ELSE NULL
               END;
    END f_ordem_status;

    ----------------------------------------------------------------------------
    FUNCTION FN_GERAR_PROTOCOLO RETURN VARCHAR2 IS
    BEGIN
        RETURN 'RUA-' || TO_CHAR(SYSDATE, 'YYYY') || '-'
               || LPAD(SEQ_PROTOCOLO.NEXTVAL, 6, '0');
    END FN_GERAR_PROTOCOLO;

    ----------------------------------------------------------------------------
    PROCEDURE PR_REGISTRAR_OCORRENCIA (
        p_cidadao_id    IN  NUMBER,
        p_categoria_id  IN  NUMBER,
        p_descricao     IN  VARCHAR2,
        p_latitude      IN  NUMBER,
        p_longitude     IN  NUMBER,
        p_endereco      IN  VARCHAR2,
        p_ocorrencia_id OUT NUMBER,
        p_protocolo     OUT VARCHAR2
    )
    IS
        v_qtd        NUMBER;
        v_prioridade CATEGORIAS.PRIORIDADE_PADRAO%TYPE;
    BEGIN
        SELECT COUNT(*) INTO v_qtd FROM CIDADAOS WHERE ID = p_cidadao_id;
        IF v_qtd = 0 THEN
            RAISE_APPLICATION_ERROR(-20101, 'Cidadao ' || p_cidadao_id || ' nao encontrado');
        END IF;

        BEGIN
            SELECT PRIORIDADE_PADRAO INTO v_prioridade
              FROM CATEGORIAS WHERE ID = p_categoria_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20102, 'Categoria ' || p_categoria_id || ' nao encontrada');
        END;

        IF p_descricao IS NULL OR LENGTH(TRIM(p_descricao)) < 5 THEN
            RAISE_APPLICATION_ERROR(-20106, 'Descricao obrigatoria (minimo 5 caracteres)');
        END IF;

        p_protocolo := FN_GERAR_PROTOCOLO;

        INSERT INTO OCORRENCIAS (PROTOCOLO, CIDADAO_ID, CATEGORIA_ID, DESCRICAO,
                                 LATITUDE, LONGITUDE, ENDERECO, PRIORIDADE)
        VALUES (p_protocolo, p_cidadao_id, p_categoria_id, TRIM(p_descricao),
                p_latitude, p_longitude, p_endereco, v_prioridade)
        RETURNING ID INTO p_ocorrencia_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PR_REGISTRAR_OCORRENCIA;

    ----------------------------------------------------------------------------
    PROCEDURE PR_ATUALIZAR_STATUS (
        p_ocorrencia_id IN NUMBER,
        p_novo_status   IN VARCHAR2,
        p_observacao    IN VARCHAR2 DEFAULT NULL
    )
    IS
        v_status_atual OCORRENCIAS.STATUS%TYPE;
        v_novo         OCORRENCIAS.STATUS%TYPE := UPPER(TRIM(p_novo_status));
    BEGIN
        BEGIN
            SELECT STATUS INTO v_status_atual
              FROM OCORRENCIAS WHERE ID = p_ocorrencia_id
               FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20101,
                    'Ocorrencia ' || p_ocorrencia_id || ' nao encontrada');
        END;

        IF f_ordem_status(v_novo) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20104, 'Status invalido: ' || p_novo_status);
        END IF;
        -- so avanca no fluxo: ABERTA > EM_ANALISE > EM_ANDAMENTO > RESOLVIDA
        IF f_ordem_status(v_novo) <= f_ordem_status(v_status_atual) THEN
            RAISE_APPLICATION_ERROR(-20104,
                'Transicao invalida: ' || v_status_atual || ' -> ' || v_novo);
        END IF;

        G_OBSERVACAO := p_observacao;

        UPDATE OCORRENCIAS
           SET STATUS       = v_novo,
               RESOLVIDO_EM = CASE WHEN v_novo = 'RESOLVIDA' THEN SYSTIMESTAMP END
         WHERE ID = p_ocorrencia_id;

        G_OBSERVACAO := NULL;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            G_OBSERVACAO := NULL;
            ROLLBACK;
            RAISE;
    END PR_ATUALIZAR_STATUS;

    ----------------------------------------------------------------------------
    PROCEDURE PR_APOIAR_OCORRENCIA (
        p_ocorrencia_id IN  NUMBER,
        p_cidadao_id    IN  NUMBER,
        p_total_apoios  OUT NUMBER
    )
    IS
        v_qtd NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_qtd FROM OCORRENCIAS WHERE ID = p_ocorrencia_id;
        IF v_qtd = 0 THEN
            RAISE_APPLICATION_ERROR(-20101,
                'Ocorrencia ' || p_ocorrencia_id || ' nao encontrada');
        END IF;

        BEGIN
            INSERT INTO APOIOS (OCORRENCIA_ID, CIDADAO_ID)
            VALUES (p_ocorrencia_id, p_cidadao_id);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                RAISE_APPLICATION_ERROR(-20105,
                    'Cidadao ' || p_cidadao_id || ' ja apoiou a ocorrencia ' || p_ocorrencia_id);
        END;

        -- a trigger TRG_OCORRENCIAS_PRIORIDADE reavalia a prioridade
        UPDATE OCORRENCIAS SET QTD_APOIOS = QTD_APOIOS + 1
         WHERE ID = p_ocorrencia_id
        RETURNING QTD_APOIOS INTO p_total_apoios;

        COMMIT;
    EXCEPTION
        WHEN e_apoio_duplicado THEN
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PR_APOIAR_OCORRENCIA;

    ----------------------------------------------------------------------------
    FUNCTION FN_ESTA_ATRASADA (
        p_ocorrencia_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_atrasada NUMBER;
    BEGIN
        SELECT CASE
                   WHEN o.STATUS <> 'RESOLVIDA'
                    AND CAST(SYSTIMESTAMP AS DATE) > CAST(o.CRIADO_EM AS DATE) + c.PRAZO_DIAS
                   THEN 1 ELSE 0
               END
          INTO v_atrasada
          FROM OCORRENCIAS o
          JOIN CATEGORIAS c ON c.ID = o.CATEGORIA_ID
         WHERE o.ID = p_ocorrencia_id;
        RETURN v_atrasada;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20101,
                'Ocorrencia ' || p_ocorrencia_id || ' nao encontrada');
    END FN_ESTA_ATRASADA;

    ----------------------------------------------------------------------------
    FUNCTION FN_TEMPO_MEDIO_RESOLUCAO (
        p_categoria_id IN NUMBER DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_media NUMBER;
    BEGIN
        SELECT ROUND(AVG(CAST(RESOLVIDO_EM AS DATE) - CAST(CRIADO_EM AS DATE)), 2)
          INTO v_media
          FROM OCORRENCIAS
         WHERE STATUS = 'RESOLVIDA'
           AND (p_categoria_id IS NULL OR CATEGORIA_ID = p_categoria_id);
        RETURN NVL(v_media, 0);
    END FN_TEMPO_MEDIO_RESOLUCAO;

    ----------------------------------------------------------------------------
    PROCEDURE PR_INDICADORES_POR_CATEGORIA (
        p_cursor OUT SYS_REFCURSOR
    )
    IS
    BEGIN
        OPEN p_cursor FOR
            SELECT c.NOME                                             AS CATEGORIA,
                   COUNT(o.ID)                                        AS TOTAL,
                   NVL(SUM(CASE WHEN o.STATUS = 'RESOLVIDA' THEN 1 END), 0) AS RESOLVIDAS,
                   CASE WHEN COUNT(o.ID) = 0 THEN 0
                        ELSE ROUND(100 * NVL(SUM(CASE WHEN o.STATUS = 'RESOLVIDA' THEN 1 END), 0)
                                   / COUNT(o.ID), 1)
                   END                                                AS PERCENTUAL_RESOLVIDAS,
                   NVL(SUM(o.QTD_APOIOS), 0)                          AS TOTAL_APOIOS
              FROM CATEGORIAS c
              LEFT JOIN OCORRENCIAS o ON o.CATEGORIA_ID = c.ID
             GROUP BY c.ID, c.NOME
             ORDER BY TOTAL DESC, c.NOME;
    END PR_INDICADORES_POR_CATEGORIA;

    ----------------------------------------------------------------------------
    PROCEDURE PR_OCORRENCIAS_ATRASADAS (
        p_cursor OUT SYS_REFCURSOR
    )
    IS
    BEGIN
        OPEN p_cursor FOR
            SELECT o.PROTOCOLO, c.NOME AS CATEGORIA, g.NOME AS ORGAO, o.STATUS,
                   o.PRIORIDADE,
                   TRUNC(CAST(SYSTIMESTAMP AS DATE) - CAST(o.CRIADO_EM AS DATE)) AS DIAS_ABERTA,
                   c.PRAZO_DIAS
              FROM OCORRENCIAS o
              JOIN CATEGORIAS c ON c.ID = o.CATEGORIA_ID
              JOIN ORGAOS     g ON g.ID = c.ORGAO_ID
             WHERE o.STATUS <> 'RESOLVIDA'
               AND CAST(SYSTIMESTAMP AS DATE) > CAST(o.CRIADO_EM AS DATE) + c.PRAZO_DIAS
             ORDER BY DIAS_ABERTA DESC;
    END PR_OCORRENCIAS_ATRASADAS;

END PKG_RUATENTA;
/
