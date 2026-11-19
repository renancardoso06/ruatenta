SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT 1. Registro: protocolo, status e prioridade
DECLARE
    v_id    NUMBER;
    v_prot  VARCHAR2(20);
    v_stat  OCORRENCIAS.STATUS%TYPE;
    v_prio  OCORRENCIAS.PRIORIDADE%TYPE;
    v_hist  NUMBER;
BEGIN
    PKG_RUATENTA.PR_REGISTRAR_OCORRENCIA(1, 1, 'Buraco grande em frente ao numero 200',
        -23.5614, -46.6559, 'Rua das Flores, 200', v_id, v_prot);

    IF NOT REGEXP_LIKE(v_prot, '^RUA-[0-9]{4}-[0-9]{6}$') THEN
        RAISE_APPLICATION_ERROR(-20900, 'Protocolo fora do formato: ' || v_prot);
    END IF;
    SELECT STATUS, PRIORIDADE INTO v_stat, v_prio FROM OCORRENCIAS WHERE ID = v_id;
    IF v_stat <> 'ABERTA' OR v_prio <> 'BAIXA' THEN
        RAISE_APPLICATION_ERROR(-20900, 'Estado inicial inesperado: ' || v_stat || '/' || v_prio);
    END IF;
    SELECT COUNT(*) INTO v_hist FROM HISTORICO_OCORRENCIA WHERE OCORRENCIA_ID = v_id;
    IF v_hist <> 1 THEN
        RAISE_APPLICATION_ERROR(-20900, 'Historico deveria ter 1 linha, tem ' || v_hist);
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  ' || v_prot || ' ABERTA/BAIXA, historico inicial gravado pela trigger');
END;
/

PROMPT 2. Validacoes de entrada
DECLARE
    v_id   NUMBER;
    v_prot VARCHAR2(20);
    PROCEDURE espera (p_codigo NUMBER, p_cat NUMBER, p_cid NUMBER, p_desc VARCHAR2) IS
    BEGIN
        PKG_RUATENTA.PR_REGISTRAR_OCORRENCIA(p_cid, p_cat, p_desc, -23.5, -46.6, NULL, v_id, v_prot);
        RAISE_APPLICATION_ERROR(-20900, 'Deveria ter levantado ' || p_codigo);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> p_codigo THEN
                RAISE_APPLICATION_ERROR(-20900,
                    'Esperado ' || p_codigo || ', obtido ' || SQLCODE || ' ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('OK  erro ' || p_codigo || ' levantado como esperado');
    END espera;
BEGIN
    espera(-20101, 1,   9999, 'Descricao valida');
    espera(-20102, 999, 1,    'Descricao valida');
    espera(-20106, 1,   1,    'ab');
END;
/

PROMPT 3. Status e historico
DECLARE
    v_id     NUMBER;
    v_prot   VARCHAR2(20);
    v_hist   NUMBER;
    v_resolv TIMESTAMP;
    v_obs    HISTORICO_OCORRENCIA.OBSERVACAO%TYPE;
BEGIN
    PKG_RUATENTA.PR_REGISTRAR_OCORRENCIA(2, 2, 'Poste apagado na esquina', -23.5, -46.6, NULL, v_id, v_prot);
    PKG_RUATENTA.PR_ATUALIZAR_STATUS(v_id, 'EM_ANALISE',   'Equipe tecnica avaliando');
    PKG_RUATENTA.PR_ATUALIZAR_STATUS(v_id, 'EM_ANDAMENTO', 'Equipe a caminho');
    PKG_RUATENTA.PR_ATUALIZAR_STATUS(v_id, 'RESOLVIDA',    'Lampada trocada');

    SELECT COUNT(*) INTO v_hist FROM HISTORICO_OCORRENCIA WHERE OCORRENCIA_ID = v_id;
    IF v_hist <> 4 THEN
        RAISE_APPLICATION_ERROR(-20900, 'Historico deveria ter 4 linhas, tem ' || v_hist);
    END IF;
    SELECT RESOLVIDO_EM INTO v_resolv FROM OCORRENCIAS WHERE ID = v_id;
    IF v_resolv IS NULL THEN
        RAISE_APPLICATION_ERROR(-20900, 'RESOLVIDO_EM deveria estar preenchido');
    END IF;
    SELECT OBSERVACAO INTO v_obs FROM HISTORICO_OCORRENCIA
     WHERE OCORRENCIA_ID = v_id AND STATUS_NOVO = 'EM_ANALISE';
    IF v_obs <> 'Equipe tecnica avaliando' THEN
        RAISE_APPLICATION_ERROR(-20900, 'Observacao inesperada: ' || v_obs);
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  4 etapas no historico e RESOLVIDO_EM preenchido');

    BEGIN
        PKG_RUATENTA.PR_ATUALIZAR_STATUS(v_id, 'ABERTA');
        RAISE_APPLICATION_ERROR(-20900, 'Retrocesso deveria ser recusado');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -20104 THEN
                RAISE_APPLICATION_ERROR(-20900, 'Esperado -20104, obtido ' || SQLCODE);
            END IF;
            DBMS_OUTPUT.PUT_LINE('OK  retrocesso de status recusado (ORA-20104)');
    END;
END;
/

PROMPT 4. Apoios e prioridade
DECLARE
    v_id    NUMBER;
    v_prot  VARCHAR2(20);
    v_total NUMBER;
    v_prio  OCORRENCIAS.PRIORIDADE%TYPE;
BEGIN
    PKG_RUATENTA.PR_REGISTRAR_OCORRENCIA(1, 3, 'Entulho acumulado na calcada', -23.5, -46.6, NULL, v_id, v_prot);

    FOR i IN 1 .. 4 LOOP
        PKG_RUATENTA.PR_APOIAR_OCORRENCIA(v_id, i + 1, v_total);
    END LOOP;
    SELECT PRIORIDADE INTO v_prio FROM OCORRENCIAS WHERE ID = v_id;
    IF v_prio <> 'BAIXA' THEN
        RAISE_APPLICATION_ERROR(-20900, 'Com 4 apoios deveria seguir BAIXA, esta ' || v_prio);
    END IF;

    PKG_RUATENTA.PR_APOIAR_OCORRENCIA(v_id, 6, v_total);
    SELECT PRIORIDADE INTO v_prio FROM OCORRENCIAS WHERE ID = v_id;
    IF v_total <> 5 OR v_prio <> 'MEDIA' THEN
        RAISE_APPLICATION_ERROR(-20900, 'Com 5 apoios deveria ser MEDIA: ' || v_total || '/' || v_prio);
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  5 apoios -> prioridade MEDIA (trigger)');

    BEGIN
        PKG_RUATENTA.PR_APOIAR_OCORRENCIA(v_id, 6, v_total);
        RAISE_APPLICATION_ERROR(-20900, 'Apoio duplicado deveria ser recusado');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -20105 THEN
                RAISE_APPLICATION_ERROR(-20900, 'Esperado -20105, obtido ' || SQLCODE);
            END IF;
            DBMS_OUTPUT.PUT_LINE('OK  apoio duplicado recusado (ORA-20105)');
    END;
END;
/

PROMPT 5. Prazo e indicadores
DECLARE
    v_id     NUMBER;
    v_prot   VARCHAR2(20);
    v_media  NUMBER;
    v_cur    SYS_REFCURSOR;
    v_cat    VARCHAR2(80);
    v_tot    NUMBER;
    v_res    NUMBER;
    v_pct    NUMBER;
    v_apo    NUMBER;
    v_n      NUMBER := 0;
    v_prot2  VARCHAR2(20);
    v_cat2   VARCHAR2(80);
    v_org    VARCHAR2(120);
    v_st     VARCHAR2(15);
    v_pr     VARCHAR2(10);
    v_dias   NUMBER;
    v_prazo  NUMBER;
    v_achou  BOOLEAN := FALSE;
BEGIN
    PKG_RUATENTA.PR_REGISTRAR_OCORRENCIA(3, 5, 'Bueiro entupido na avenida', -23.5, -46.6, NULL, v_id, v_prot);
    IF PKG_RUATENTA.FN_ESTA_ATRASADA(v_id) <> 0 THEN
        RAISE_APPLICATION_ERROR(-20900, 'Ocorrencia nova nao deveria estar atrasada');
    END IF;
    UPDATE OCORRENCIAS SET CRIADO_EM = SYSTIMESTAMP - INTERVAL '30' DAY WHERE ID = v_id;
    IF PKG_RUATENTA.FN_ESTA_ATRASADA(v_id) <> 1 THEN
        RAISE_APPLICATION_ERROR(-20900, 'Ocorrencia com 30 dias deveria estar atrasada');
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  FN_ESTA_ATRASADA: nova = 0, 30 dias = 1');

    PKG_RUATENTA.PR_OCORRENCIAS_ATRASADAS(v_cur);
    LOOP
        FETCH v_cur INTO v_prot2, v_cat2, v_org, v_st, v_pr, v_dias, v_prazo;
        EXIT WHEN v_cur%NOTFOUND;
        IF v_prot2 = v_prot THEN v_achou := TRUE; END IF;
    END LOOP;
    CLOSE v_cur;
    IF NOT v_achou THEN
        RAISE_APPLICATION_ERROR(-20900, 'Ocorrencia atrasada nao apareceu na lista');
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  PR_OCORRENCIAS_ATRASADAS lista o protocolo ' || v_prot);

    v_media := PKG_RUATENTA.FN_TEMPO_MEDIO_RESOLUCAO(2);
    IF v_media < 0 THEN
        RAISE_APPLICATION_ERROR(-20900, 'Tempo medio invalido: ' || v_media);
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  tempo medio de resolucao (Iluminacao) = ' || v_media || ' dias');

    PKG_RUATENTA.PR_INDICADORES_POR_CATEGORIA(v_cur);
    LOOP
        FETCH v_cur INTO v_cat, v_tot, v_res, v_pct, v_apo;
        EXIT WHEN v_cur%NOTFOUND;
        v_n := v_n + 1;
        DBMS_OUTPUT.PUT_LINE('    ' || RPAD(v_cat, 26) || ' total=' || v_tot
            || ' resolvidas=' || v_res || ' (' || v_pct || '%) apoios=' || v_apo);
    END LOOP;
    CLOSE v_cur;
    IF v_n <> 5 THEN
        RAISE_APPLICATION_ERROR(-20900, 'Esperadas 5 categorias nos indicadores, vieram ' || v_n);
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  indicadores devolveram as 5 categorias');
    ROLLBACK;
END;
/

PROMPT Todos os testes da camada Oracle passaram
