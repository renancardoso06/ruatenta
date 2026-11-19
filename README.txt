================================================================================
RUATENTA - Global Solution 2 (CitizenTech)
FIAP - Sistemas de Informacao - Turma 3SIOA
Renan Cardoso da Costa (RM 557918) e Victor Vieira Borges (RM 557922)
================================================================================

1. O QUE E
----------
Aplicativo mobile (Flutter) para o cidadao registrar e acompanhar problemas
urbanos do seu bairro: buraco na via, iluminacao com defeito, lixo ou entulho,
calcada danificada e alagamento. Cada registro gera um numero de protocolo,
tem orgao responsavel e prazo, e pode ser apoiado pelos vizinhos, o que aumenta
sua prioridade. Um painel de indicadores mostra quantas ocorrencias foram
resolvidas e em quanto tempo.

Problema: reclamacoes sobre o espaco publico se perdem em canais dispersos e o
cidadao nao sabe se o problema foi visto nem quando sera resolvido.
Publico: moradores de areas urbanas, com atencao a acessibilidade (calcadas e
iluminacao afetam idosos e pessoas com deficiencia).

ODS relacionados (ONU):
 - ODS 11 - Cidades e Comunidades Sustentaveis: melhora a conservacao do espaco
   publico e a seguranca e acessibilidade do deslocamento nas cidades.
 - ODS 16 - Paz, Justica e Instituicoes Eficazes: transparencia e
   acompanhamento publico do atendimento (indicadores e prazos).

2. FUNCIONALIDADES (alem de login/cadastro, que o app nao exige)
----------------------------------------------------------------
 1) Registrar ocorrencia: categoria, descricao, local (GPS ou toque no mapa),
    foto opcional e protocolo (RUA-AAAA-NNNNNN).
 2) Mapa de ocorrencias: pinos por categoria, com filtro; resolvidas em cinza.
 3) Acompanhar: minhas ocorrencias e as da comunidade, busca por protocolo,
    linha do tempo de status, aviso de "fora do prazo" e apoio dos vizinhos.
 4) Indicadores: total, % resolvidas, tempo medio de resolucao, atrasadas e
    detalhamento por categoria.

3. ESTRUTURA DO REPOSITORIO
---------------------------
 lib/models/        modelos (Ocorrencia, Categoria, Status, Prioridade, ...)
 lib/data/          persistencia (interface + local + memoria para testes)
 lib/state/         OcorrenciasController: regras de negocio (ChangeNotifier)
 lib/services/      LocalizacaoService (GPS sob demanda)
 lib/screens/       telas (mapa, registrar, acompanhar, detalhe, indicadores)
 lib/widgets/       componentes reutilizaveis (chips, item de lista)
 test/              testes automatizados das regras de negocio
 sql/               camada Oracle: tabelas, package PKG_RUATENTA, triggers, testes
 docs/              documentacao completa, DER e MER

4. COMO EXECUTAR O APP
----------------------
Requisitos: Flutter 3.27 ou superior, Android Studio com emulador (ou aparelho).

 1. Gerar as pastas de plataforma (uma unica vez), na raiz do repositorio:
      flutter create --org br.fiap --project-name ruatenta --platforms android,ios .
    (se o comando criar test/widget_test.dart, apague esse arquivo)
 2. Android: em android/app/src/main/AndroidManifest.xml, dentro de <manifest>
    e antes de <application>, incluir:
      <uses-permission android:name="android.permission.INTERNET"/>
      <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
      <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
 3. iOS (se for usar): em ios/Runner/Info.plist incluir NSLocationWhenInUseUsageDescription,
    NSCameraUsageDescription e NSPhotoLibraryUsageDescription com um texto explicativo.
 4. flutter pub get
 5. flutter run

No primeiro uso o app carrega 6 ocorrencias de demonstracao na regiao da Av.
Paulista (SP). O botao "Recarregar dados de demonstracao" (aba Indicadores)
restaura esses dados. O botao "Modo demonstracao" no detalhe da ocorrencia
simula a resposta do orgao responsavel (em producao, quem muda o status e o
orgao).

Testes automatizados das regras de negocio:
      flutter analyze
      flutter test

5. COMO EXECUTAR A CAMADA ORACLE (PL/SQL)
-----------------------------------------
Banco: Oracle XE 21 em Docker.
      docker run -d --name oracle-xe -p 1521:1521 \
        -e ORACLE_PASSWORD=<senha_sys> -e APP_USER=RUATENTA_APP \
        -e APP_USER_PASSWORD=<senha_app> gvenzl/oracle-xe:21-slim
Aguarde o banco ficar pronto (docker logs oracle-xe) e execute, dentro da
pasta sql/:
      sqlplus RUATENTA_APP/<senha_app>@//localhost:1521/XEPDB1 @00_run_all.sql
O script cria as tabelas, os dados iniciais, o package PKG_RUATENTA e as
triggers, verifica se nao ha objetos invalidos e roda 05_teste.sql, que valida
cada regra (a execucao termina com "Todos os testes da camada Oracle passaram").

6. JUSTIFICATIVAS TECNICAS
--------------------------
 - Flutter/Dart: uma base de codigo para Android e iOS, interface Material 3
   com componentes de acessibilidade (Semantics, areas de toque amplas).
 - Provider + ChangeNotifier: gerenciamento de estado simples e leve; a tela
   so reconstroi quando o estado muda e o controller e descartado pelo Provider.
 - shared_preferences: persistencia local em JSON, suficiente para o prototipo
   e sem servidor; isolada atras da interface OcorrenciaRepository, de modo que
   trocar por uma API/Oracle nao exige mudar as telas.
 - flutter_map + OpenStreetMap: mapa sem chave de API paga, com atribuicao.
 - geolocator: GPS lido uma unica vez e sob demanda (sem stream aberto).
 - image_picker: foto reduzida na captura (largura maxima e qualidade) para
   economizar memoria e armazenamento.
 - Oracle PL/SQL: regras de negocio criticas (protocolo, fluxo de status,
   prioridade por apoios, prazos e indicadores) ficam no banco, garantindo a
   mesma regra para qualquer cliente (app, web, API). As mesmas regras estao
   espelhadas no OcorrenciasController do app e cobertas por testes nos dois
   lados.

7. LIMITACOES CONHECIDAS
------------------------
 - Nesta versao o app grava os dados no proprio aparelho. A camada Oracle esta
   modelada, implementada e testada a parte; a integracao app <-> Oracle (via
   API REST) e o proximo passo.
 - O status das ocorrencias e atualizado pelo "Modo demonstracao", que simula o
   orgao publico; nao ha integracao com sistemas de prefeituras.
 - Sem login: o aparelho e identificado por um codigo anonimo gerado no
   primeiro uso (evita apoios duplicados, mas nao impede quem reinstala o app).

Documentacao completa (classes, memoria, DER/MER, rotinas PL/SQL): pasta docs/.
