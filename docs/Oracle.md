# Execução do banco Oracle

O script `sql/00_run_all.sql` não cria usuários, não abre uma conexão e não altera o schema atual da sessão. Como os objetos nos arquivos SQL não especificam um proprietário, eles são criados no schema do usuário conectado quando o script é executado.

O comando PowerShell que usa `system/$ORACLE_PASSWORD@//localhost:1521/XEPDB1` conecta como `SYSTEM`; portanto, nesse caso, tabelas, sequência, package e triggers ficam no schema `SYSTEM`. Para criar esses objetos em `RUATENTA_APP`, o usuário deve existir previamente e o SQL*Plus deve estar conectado como `RUATENTA_APP` ao executar `sql/00_run_all.sql`.

O script `sql/01_ddl.sql` apaga e recria as tabelas e a sequência do schema conectado. Isso descarta os dados que já existiam nesses objetos; em seguida, os demais scripts carregam dados iniciais e executam os testes.
