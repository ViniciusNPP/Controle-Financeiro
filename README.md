# Meu Financeiro

Aplicativo em Flutter para controlar finanças pessoais no Windows. Ele permite registrar receitas e despesas, organizar categorias, visualizar histórico e analisar o comportamento financeiro com gráficos.

## O que o app faz

* Registra entradas e saídas
* Edição e exclusão de lançamentos
* Adicionar e editar categorias
* 21 categorias predefinidas
* Visualização histórico com filtros
* Ver gráficos por períodos personalizáveis

## Como usar

### 1\. Instalar o aplicativo

1. Execute o arquivo "controle\_financeiro\_app.exe"
2. Siga todas as instruções de instalação e mude conforme o que queira. Recomendado criar atalho para maior facilidade de acesso.
3. Clique no aplicativo.exe criado após a instalação para abrir o aplicativo. Ou procure "Controle Financeiro" na barra de pesquisa do Windows e clique para abri-lo.

### 2\. Adicionar um lançamento

1. Selecione a data clicando sobre o campo de data
2. Selecione o tipo clicando sobre o texto "Entrada" ou "Saída"
3. Selecione a categoria clicando sobre o campo de categoria que ficará disponível assim que selecionar o tipo
4. Adicione o valor clicando no campo com o valor padrão de R$0,00
5. Após todos os campos serem preenchidos, clique no botão Salvar lançamento.

### 3\. Salvar, exportar e importar dados

O app salva os dados automaticamente em um arquivo `dados\_financeiro.json`, guardado localmente no computador. Não é necessário salvar manualmente.

**Para exportar:**

1. Clique em "Sincronização"
2. Na aba que abrir, clique no botão "Exportar dados"
3. Selecione o local onde deseja salvar o arquivo `.json`

**Para importar:**

1. Clique em "Sincronização"
2. Na aba que abrir, clique no botão "Importar dados"
3. Procure o arquivo `dados\_financeiro.json` e selecione-o

> ⚠️ \*\*Atenção:\*\* importar um arquivo \*\*substitui completamente\*\* os dados atuais do app pelos dados do arquivo selecionado. Essa ação não pode ser desfeita. Se quiser apenas combinar dados de dois dispositivos sem perder nada, use a opção de "Escolher pasta" descrita abaixo.

**Sincronização automática por pasta (opcional):**

Essa opção vai criada somente para uma atualização futura para celular Android, por não conseguir sincronizar os dados com os do computador. Ainda não existe o apk por que eu ainda não quis :)

No computador, também é possível escolher uma pasta (por exemplo, dentro do Google Drive ou OneDrive) para que o app sincronize automaticamente a cada alteração, combinando os dados sem substituí-los. Essa opção fica disponível na mesma aba de "Sincronização", em "Escolher pasta".

## Observações importantes

* O app usa um arquivo local para armazenamento, então os dados ficam salvos no computador ou no dispositivo onde o app foi usado.
* Para compartilhar os dados entre dispositivos, use as opções de exportar/importar, ou a sincronização automática por pasta.

## Licença

Este projeto está licenciado sob a **Creative Commons Atribuição-NãoComercial 4.0 Internacional (CC BY-NC 4.0)**.

Isso significa que qualquer pessoa pode usar, modificar e redistribuir este código livremente, **desde que**:

* Dê o devido crédito ao autor original;
* **Não** venda, comercialize ou lucre com o software ou qualquer versão modificada dele, sem autorização prévia e por escrito.

Consulte o arquivo [`LICENSE`](./LICENSE.md) para os termos completos, ou veja o resumo oficial em:
https://creativecommons.org/licenses/by-nc/4.0/deed.pt\_BR

