# Meu Financeiro

Aplicativo em Flutter para controlar finanças pessoais no Windows e Android. Ele permite registrar receitas e despesas, organizar categorias, visualizar histórico e analisar o comportamento financeiro com gráficos.

## O que o app faz

- Registrar entradas e saídas
- Organizar transações por categoria
- Visualizar histórico com filtros
- Ver gráficos por período e categoria
- Salvar os dados localmente em um arquivo JSON dentro da pasta do projeto
- Exportar/importar os dados para sincronizar entre dispositivos

## Como usar

### 1. Abrir o app no computador

Se você já tiver o executável gerado, basta abrir o arquivo:

- Windows: `build/windows/x64/runner/Release/controle_financeiro.exe`

> Para usar o app sem Flutter, você precisa ter o executável compilado previamente. Depois que ele existir, não é necessário instalar o Flutter para rodá-lo.

### 2. Usar o app pela primeira vez

1. Abra o app.
2. Adicione suas categorias, se quiser.
3. Cadastre transações de entrada ou saída.
4. Acompanhe o histórico e os gráficos na barra lateral.

### 3. Salvar e importar dados

O app salva os dados em um arquivo JSON localizado em:

- `data/dados_financeiro.json`

Esse arquivo é usado para persistir as informações localmente. Também é possível exportar e importar esse arquivo manualmente pelo app, caso você queira transferir os dados para outro aparelho.

## Como rodar com Flutter

### Pré-requisitos

- Flutter SDK instalado
- Para Windows: Visual Studio 2022 com a carga "Desenvolvimento para desktop com C++"
- Para Android: Android Studio e um dispositivo/emulador

### Rodar no Windows

```bash
flutter run -d windows
```

### Rodar no Android

```bash
flutter run
```

### Gerar executável e APK

Windows:

```bash
flutter build windows
```

Android:

```bash
flutter build apk
```

Os arquivos gerados ficam em pastas semelhantes a:

- Windows: `build/windows/x64/runner/Release/`
- Android: `build/app/outputs/flutter-apk/`

## Observações importantes

- O app usa um arquivo local para armazenamento, então os dados ficam salvos no computador ou no dispositivo onde o app foi usado.
- Para compartilhar os dados entre dispositivos, use as opções de exportar/importar no app.
- Em Windows, o executável pode precisar da pasta inteira de release para funcionar corretamente. Não copie apenas o `.exe`.

## Se algo der erro

- Se `flutter doctor` mostrar problemas, resolva-os antes de continuar.
- Se `flutter build windows` falhar, verifique se o Visual Studio foi instalado com a carga de desenvolvimento para desktop com C++.
- Se o app não abrir após a compilação, confirme se a pasta `Release` inteira foi copiada junto com o executável.
