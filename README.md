# RuAtenta

App para o cidadão registrar problemas da rua, como buraco, poste apagado, lixo, calçada quebrada e alagamento, e acompanhar até serem resolvidos.

Projeto da Global Solution 2 (CitizenTech) da FIAP, ligado às ODS 11 (cidades sustentáveis) e 16 (instituições eficazes).

**Grupo:** Renan Cardoso da Costa (RM 557918) e Victor Vieira Borges (RM 557922) , turma 3SIOA

## O que o app faz

- Mostra no mapa as ocorrências da região
- Registra uma ocorrência com foto e local, e gera um protocolo (ex.: RUA-2026-000001)
- Permite acompanhar o andamento pelo protocolo: aberta, em análise, em andamento, resolvida
- Deixa outras pessoas apoiarem a ocorrência. Com 5 apoios a prioridade sobe para média, com 10 para alta
- Tem uma tela de indicadores por categoria, com prazo e tempo médio de resolução

## Como rodar
```

flutter pub get

flutter run

flutter test

```
O banco Oracle está na pasta `sql/` (tabelas, package PKG_RUATENTA e triggers). O script `00_run_all.sql` roda tudo na ordem.

## Limitações

- O app guarda os dados no próprio aparelho e ainda não conversa com o Oracle. O próximo passo seria uma API entre os dois.
- O botão "Modo demonstração" simula a resposta do órgão responsável.
- Não há login: cada aparelho tem um identificador anônimo.

A documentação completa está em `docs/`.
