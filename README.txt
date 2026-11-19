RuAtenta

App para o cidadão registrar problemas da rua (buraco, poste apagado, lixo, calçada quebrada, alagamento) e acompanhar até serem resolvidos.
Global Solution 2 (CitizenTech), FIAP, turma 3SIOA.
Grupo: Renan Cardoso da Costa (RM 557918) e Victor Vieira Borges (RM 557922)
ODS: 11 (cidades e comunidades sustentáveis) e 16 (paz, justiça e instituições eficazes)

O que o app faz
- Mapa com as ocorrências da região, com filtro por categoria
- Registro de ocorrência com foto e local, gerando um protocolo (ex.: RUA-2026-000001)
- Acompanhamento pelo protocolo: aberta, em análise, em andamento, resolvida
- Apoio da comunidade: com 5 apoios a prioridade sobe para média, com 10 para alta
- Indicadores por categoria: total, resolvidas, prazo vencido e tempo médio de resolução

Como rodar
Precisa do Flutter 3.27 ou superior e de um emulador ou celular Android.
  flutter pub get
  flutter run
  flutter test

Banco Oracle
Fica na pasta sql/. Com um Oracle XE 21 rodando (usamos a imagem gvenzl/oracle-xe:21-slim no Docker, banco XEPDB1) e o usuário RUATENTA_APP criado, rode sql/00_run_all.sql. Ele cria as tabelas, carrega os dados iniciais, compila o package PKG_RUATENTA e os triggers e executa os testes.

Tecnologias e por que escolhemos
- Flutter: um código só para Android e iOS, com interface Material 3.
- Provider: gerência de estado simples, suficiente para o tamanho do app.
- shared_preferences: guarda os dados no aparelho. Fica atrás de uma interface (OcorrenciaRepository), então dá para trocar por uma API sem mexer nas telas.
- flutter_map com OpenStreetMap: mapa sem chave de API e sem custo.
- geolocator e image_picker: localização e foto (a foto é reduzida para 1024 px, qualidade 70).
- Oracle PL/SQL: as regras (protocolo, fluxo de status, prioridade por apoios, indicadores) também existem no banco, em package e triggers, para valerem independente do app.

Memória e eficiência
- dispose() nos controllers
- ListView.builder nas listas
- Image.file com cacheWidth
- no máximo 200 marcadores no mapa
- GPS lido uma vez, sem ficar escutando
- só a aba aberta é construída; widgets const sempre que possível

Limitações
- O app guarda os dados no aparelho e ainda não conversa com o Oracle. O próximo passo seria uma API entre os dois.
- O botão "Modo demonstração" simula a resposta do órgão responsável.
- Não há login: cada aparelho tem um identificador anônimo.

Estrutura
lib/ (models, data, state, services, screens, widgets), test/, sql/ e docs/
Descrição das classes e métodos, MER e DER: docs/RuAtenta_Documentacao.pdf
