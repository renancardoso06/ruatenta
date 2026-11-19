--------------------------------------------------------------------------------
-- RuAtenta - Script 2: dados de referencia (orgaos, categorias, cidadaos)
-- As ocorrencias NAO sao inseridas aqui: sao criadas pela procedure
-- PR_REGISTRAR_OCORRENCIA, para que protocolo, historico e prioridade sigam as
-- regras reais do sistema.
--------------------------------------------------------------------------------
INSERT INTO ORGAOS (ID, NOME) VALUES (1, 'Zeladoria Urbana');
INSERT INTO ORGAOS (ID, NOME) VALUES (2, 'Iluminacao Publica');
INSERT INTO ORGAOS (ID, NOME) VALUES (3, 'Limpeza Urbana');
INSERT INTO ORGAOS (ID, NOME) VALUES (4, 'Defesa Civil');

INSERT INTO CATEGORIAS (ID, NOME, ORGAO_ID, PRAZO_DIAS, PRIORIDADE_PADRAO) VALUES (1, 'Buraco na via',          1, 15, 'BAIXA');
INSERT INTO CATEGORIAS (ID, NOME, ORGAO_ID, PRAZO_DIAS, PRIORIDADE_PADRAO) VALUES (2, 'Iluminacao com defeito', 2,  7, 'MEDIA');
INSERT INTO CATEGORIAS (ID, NOME, ORGAO_ID, PRAZO_DIAS, PRIORIDADE_PADRAO) VALUES (3, 'Lixo ou entulho',        3, 10, 'BAIXA');
INSERT INTO CATEGORIAS (ID, NOME, ORGAO_ID, PRAZO_DIAS, PRIORIDADE_PADRAO) VALUES (4, 'Calcada danificada',     1, 30, 'BAIXA');
INSERT INTO CATEGORIAS (ID, NOME, ORGAO_ID, PRAZO_DIAS, PRIORIDADE_PADRAO) VALUES (5, 'Alagamento ou bueiro',   4,  3, 'ALTA');

INSERT INTO CIDADAOS (ID, NOME, BAIRRO) VALUES (1, 'Maria Silva',     'Jardim Primavera');
INSERT INTO CIDADAOS (ID, NOME, BAIRRO) VALUES (2, 'Carlos Pereira',  'Vila Nova');
INSERT INTO CIDADAOS (ID, NOME, BAIRRO) VALUES (3, 'Ana Oliveira',    'Centro');
INSERT INTO CIDADAOS (ID, NOME, BAIRRO) VALUES (4, 'Joao Santos',     'Jardim Primavera');
INSERT INTO CIDADAOS (ID, NOME, BAIRRO) VALUES (5, 'Paula Souza',     'Vila Nova');
INSERT INTO CIDADAOS (ID, NOME, BAIRRO) VALUES (6, 'Renan Cardoso',   'Centro');

COMMIT;
