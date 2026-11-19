# Rodando o banco Oracle

O `sql/00_run_all.sql` cria os objetos no schema de quem estiver conectado. Ele não cria usuário nem troca de schema.

Nos nossos testes rodamos conectados como `SYSTEM`, no container Oracle XE, então tudo ficou nesse schema. Para usar o `RUATENTA_APP`, crie o usuário antes e conecte com ele.

Atenção: o `01_ddl.sql` apaga e recria as tabelas, então os dados que já existirem nesse schema são perdidos.