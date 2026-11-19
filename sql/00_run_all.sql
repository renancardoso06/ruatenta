-- Execute este script de dentro da pasta sql/.
SET ECHO OFF
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT 01 tabelas
@01_ddl.sql
PROMPT 02 dados iniciais
@02_dados_iniciais.sql
PROMPT 03 package PKG_RUATENTA
@03_package.sql
PROMPT 04 triggers
@04_triggers.sql

PROMPT Verificacao de compilacao
DECLARE
    v_qtd NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_qtd FROM USER_OBJECTS WHERE STATUS = 'INVALID';
    IF v_qtd > 0 THEN
        FOR r IN (SELECT NAME, TYPE, LINE, TEXT FROM USER_ERRORS ORDER BY NAME, SEQUENCE) LOOP
            DBMS_OUTPUT.PUT_LINE(r.TYPE || ' ' || r.NAME || ' linha ' || r.LINE || ': ' || r.TEXT);
        END LOOP;
        RAISE_APPLICATION_ERROR(-20999, v_qtd || ' objeto(s) invalido(s) apos a compilacao');
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK  todos os objetos PL/SQL compilados e validos');
END;
/

PROMPT 05 testes
@05_teste.sql
EXIT
