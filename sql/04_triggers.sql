--------------------------------------------------------------------------------
-- RuAtenta - Script 4: TRIGGERS
--
-- TRG_OCORRENCIAS_HISTORICO  -> AUDITORIA: grava em HISTORICO_OCORRENCIA a
--                               criacao da ocorrencia e toda mudanca de status.
-- TRG_OCORRENCIAS_PRIORIDADE -> AUTOMACAO: sobe a prioridade conforme o numero
--                               de apoios da comunidade (5 = MEDIA, 10 = ALTA).
--------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER TRG_OCORRENCIAS_HISTORICO
AFTER INSERT OR UPDATE OF STATUS ON OCORRENCIAS
FOR EACH ROW
WHEN (OLD.STATUS IS NULL OR OLD.STATUS <> NEW.STATUS)
DECLARE
    v_observacao HISTORICO_OCORRENCIA.OBSERVACAO%TYPE;
BEGIN
    IF INSERTING THEN
        v_observacao := 'Ocorrencia registrada';
    ELSE
        v_observacao := NVL(PKG_RUATENTA.G_OBSERVACAO, 'Atualizacao de status');
    END IF;

    INSERT INTO HISTORICO_OCORRENCIA (OCORRENCIA_ID, STATUS_ANTIGO, STATUS_NOVO, OBSERVACAO)
    VALUES (
        :NEW.ID,
        :OLD.STATUS,
        :NEW.STATUS,
        v_observacao
    );
END TRG_OCORRENCIAS_HISTORICO;
/

CREATE OR REPLACE TRIGGER TRG_OCORRENCIAS_PRIORIDADE
BEFORE UPDATE OF QTD_APOIOS ON OCORRENCIAS
FOR EACH ROW
BEGIN
    IF :NEW.QTD_APOIOS >= PKG_RUATENTA.C_APOIOS_ALTA THEN
        :NEW.PRIORIDADE := 'ALTA';
    ELSIF :NEW.QTD_APOIOS >= PKG_RUATENTA.C_APOIOS_MEDIA AND :NEW.PRIORIDADE = 'BAIXA' THEN
        :NEW.PRIORIDADE := 'MEDIA';
    END IF;
END TRG_OCORRENCIAS_PRIORIDADE;
/
