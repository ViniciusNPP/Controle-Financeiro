# Meu Financeiro — App de controle financeiro

App em Flutter (Windows + Android) para controlar receitas e despesas, com
gráficos e sincronização entre computador e celular via pasta do
Google Drive / OneDrive (sem precisar de servidor ou banco de dados ligado 24h).

Este pacote contém só o código-fonte (pasta `lib/`). Como não há Flutter SDK
neste ambiente onde o código foi gerado, **o projeto nunca foi compilado nem
testado rodando de verdade** — siga os passos abaixo com calma, e veja a
seção "Se algo der erro" no final.

---

## 1. Pré-requisitos

1. **Flutter SDK** — instale em https://docs.flutter.dev/get-started/install
   (escolha Windows). Depois de instalar, rode `flutter doctor` no terminal
   e resolva o que ele apontar como pendente.
2. **Para compilar o `.exe` do Windows**: Visual Studio 2022 (Community, é
   grátis) com a carga de trabalho **"Desenvolvimento para desktop com C++"**
   marcada na instalação. Sem isso, `flutter build windows` falha.
3. **Para compilar o `.apk` do Android**: Android Studio (ele já traz o
   Android SDK). Um celular Android com "Depuração USB" ativada (em
   Configurações → Opções do desenvolvedor) ou um emulador.

Rode `flutter doctor` e só siga em frente quando Windows e Android
aparecerem com ✓.

---

## 2. Criar o projeto e colocar o código dentro

```bash
flutter create controle_financeiro
cd controle_financeiro
```

Isso gera a estrutura padrão (pastas `android/`, `windows/`, `lib/` etc — o
Flutter cria tudo isso sozinho e é melhor deixar ele fazer, em vez de eu
tentar recriar esses arquivos de configuração na mão).

Agora:
1. **Apague** o `lib/main.dart` que o `flutter create` gerou.
2. **Copie a pasta `lib/` inteira** deste pacote para dentro do projeto
   (substituindo a que já existe).

## 3. Instalar as dependências

Dentro da pasta do projeto, rode:

```bash
flutter pub add provider fl_chart path_provider file_picker shared_preferences intl crypto google_fonts uuid
flutter pub add flutter_localizations --sdk=flutter
flutter pub get
```

Uso `flutter pub add` em vez de te entregar um `pubspec.yaml` com versões
fixas porque assim o Flutter sempre baixa as versões mais recentes e
compatíveis no momento em que você rodar — evita o risco de eu te passar um
número de versão desatualizado.

## 4. Permissão de internet (Android)

O app usa fontes do Google Fonts (baixadas uma vez e guardadas em cache) e
o seletor de arquivos. Abra `android/app/src/main/AndroidManifest.xml` e
confirme que existe, logo dentro da tag `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Se não existir, adicione essa linha.

## 5. Rodar e compilar

Testar no Windows:
```bash
flutter run -d windows
```

Testar no Android (com celular conectado ou emulador aberto):
```bash
flutter run
```

Gerar os arquivos finais:
```bash
flutter build windows   # gera o .exe em build/windows/x64/runner/Release/
flutter build apk       # gera o .apk em build/app/outputs/flutter-apk/
```

O `.exe` gerado depende de algumas DLLs que ficam na mesma pasta —
para instalar em outro PC, copie a pasta `Release` inteira, não só o `.exe`.

---

## 6. Como usar pela primeira vez

1. Abra o app no computador primeiro. Na tela de login, digite o email e a
   senha que você quer usar — como é o primeiro acesso, isso **cria sua
   conta** automaticamente.
2. Vá em **Sincronização** (na barra lateral) → **Escolher pasta** → navegue
   até uma pasta dentro do seu Google Drive ou OneDrive (ex: crie uma pasta
   "MeuFinanceiro" lá dentro). A partir daí, toda alteração é salva ali
   automaticamente.
3. Espere o Drive/OneDrive sincronizar essa pasta na nuvem (ícone de
   sincronização concluída).
4. Abra o app no celular. Na tela de login, toque em **"Já uso o app em
   outro aparelho? Importar dados"** e selecione o arquivo
   `dados_financeiro.json` dentro daquela pasta (pelo app do Drive/OneDrive
   no seletor de arquivos do Android). Depois, entre com o mesmo email e senha.
5. Dali em diante, no celular use o botão **Sincronização → Exportar/Importar**
   sempre que quiser mandar ou puxar as alterações — no Android isso é
   manual (o motivo técnico está na seção de limitações abaixo).

---

## 7. Limitações conhecidas (de propósito, dado o que foi pedido)

- **Sem verificação real de email**: só o formato é validado (ex:
  `nome@dominio.com`). Confirmar que a caixa de email existe de verdade
  exigiria um serviço de backend, o que foge do "sem banco de dados ligado
  24h" que você pediu.
- **Login é local, não é uma autenticação de verdade**: como não há
  servidor, a "conta" é só um email+senha (com senha criptografada) salvo
  no próprio arquivo de dados. Serve para organizar o uso pessoal, não para
  proteger dados sensíveis de terceiros.
- **Sincronização no Android é manual** (botões Exportar/Importar), enquanto
  no Windows é automática. Isso acontece porque o Android não deixa um app
  escrever silenciosamente e repetidamente numa pasta do Drive/OneDrive sem
  reabrir o seletor de arquivos — é uma trava de segurança do próprio
  sistema, não uma limitação meramente técnica que dá pra contornar fácil.
- **iOS não foi gerado**: compilar pra iPhone exige um Mac com Xcode e
  conta de desenvolvedor Apple.
- **Categorias só podem ser adicionadas**, não editadas ou apagadas (não
  foi pedido, mas é uma extensão natural se você quiser depois).
- Todo o código foi escrito sem rodar `flutter analyze` ou compilar de
  verdade (ambiente sem SDK do Flutter). É bem provável que funcione como
  descrito, mas pequenos ajustes de sintaxe podem ser necessários.

---

## 8. Se algo der erro

- **Erro de versão ao rodar `flutter pub get`**: rode
  `flutter pub upgrade --major-versions` para deixar o Flutter resolver as
  versões compatíveis automaticamente.
- **`flutter build windows` falha**: quase sempre é o Visual Studio sem a
  carga "Desenvolvimento para desktop com C++". Reabra o instalador do
  Visual Studio e marque essa opção.
- **Erro relacionado a `google_fonts` sem internet**: na primeira execução
  o app precisa baixar as fontes (Sora e Inter). Depois disso funciona
  offline.
- **O seletor de pasta no Android não mostra o Google Drive/OneDrive**:
  confirme que o app oficial do Drive ou OneDrive está instalado no
  celular — é ele quem disponibiliza a pasta pro seletor de arquivos.
- Qualquer outro erro de compilação: copie a mensagem de erro e me mostre
  aqui que eu ajusto o arquivo correspondente.
