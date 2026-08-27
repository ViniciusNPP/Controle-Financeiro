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

#### Windows

1. Execute o arquivo "controle\_financeiro\_app.exe"
2. Siga todas as instruções de instalação e mude conforme o que queira. Recomendado criar atalho para maior facilidade de acesso.
3. Clique no aplicativo.exe criado após a instalação para abrir o aplicativo. Ou procure "Controle Financeiro" na barra de pesquisa do Windows e clique para abri-lo.

#### Android

1. Execute o arquivo "app-arm64-v8a-release.apk"
2. No celular, habilite a opção "Instalar apps desconhecidos" do aplicativo em que você está instalando o app
3. Desabilite a opção "Bloqueador automático" em Segurança e privacidade -> Bloqueador automático para o Android permitir a instalação do app
4. Na janela que abrir, clique em "Mais detalhes"
5. Clique em "Instalar assim mesmo"
6. Clique em abrir para abrir app
7. Pode habilitar novamente o "Bloqueador automático", não atrapalhará em nada o aplicativo depois que ele for instalado

### 2\. Adicionar um lançamento

1. Selecione a data clicando sobre o campo de data
2. Selecione o tipo clicando sobre o texto "Entrada" ou "Saída"
3. Selecione a categoria clicando sobre o campo de categoria que ficará disponível assim que selecionar o tipo
4. OPCIONAL: Selecione a descrição clicando sobre o campo de descrição e escreva brevemente o que é a despesa
5. Adicione o valor clicando no campo com o valor padrão de R$0,00
6. Após todos os campos obrigatórios serem preenchidos, clique no botão Salvar lançamento.

### 3\. Salvar, exportar e importar dados

O app salva os dados automaticamente em um arquivo `dados_financeiro.json`, guardado localmente no computador. Não é necessário salvar manualmente.

**Para exportar:**

1. Clique em "Sincronização"
2. Na aba que abrir, clique no botão "Exportar dados"
3. Selecione o local onde deseja salvar o arquivo `.json`

**Para importar:**

1. Clique em "Sincronização"
2. Na aba que abrir, clique no botão "Importar dados"
3. Procure o arquivo `dados_financeiro.json` e selecione-o

> ⚠️ *\\\*\\\Atenção:\\\*\\\* importar um arquivo \\\*\\\*substitui completamente\\\*\\\* os dados atuais do app pelos dados do arquivo selecionado. Essa ação não pode ser desfeita. Se quiser apenas combinar dados de dois dispositivos sem perder nada, use a opção de "Escolher pasta" descrita abaixo.

**Sincronização automática por pasta (opcional):**

Essa opção foi criada para fácil acesso do arquivo .json do computador para o celular, então se o uso for somente no computador ou no celular, não há necessidade de usar essa opção. A não ser que queira salvar em aplicativos como Google Drive e OneDrive.

No computador, também é possível escolher uma pasta (por exemplo, dentro do Google Drive ou OneDrive) para que o app sincronize automaticamente a cada alteração, combinando os dados sem substituí-los. Essa opção fica disponível na mesma aba de "Sincronização", em "Escolher pasta".

## Observações importantes

* O app usa um arquivo local para armazenamento, então os dados ficam salvos no computador ou no dispositivo onde o app foi usado.
* Para compartilhar os dados entre dispositivos, use as opções de exportar/importar, ou a sincronização automática por pasta.

### 4\. Mecânicas

#### Gráficos
1. Ao clicar nos botões 'Mensal' e 'Anual' altera o tipo de filtro dos dados mostrados no gráfico
    1.1. Mensal: Filtra os dados no período do mês escolhido na barra cinza, bimestral, trimestral, semestral e todo o período em meses que se tem lançamentos.
    1.2. Anual: Filtra os dados no período do ano escolhido na barra cinza ou de todo o período em anos que se tem lançamentos.
    1.3. Personalizado: Essa opção permite selecionar um período específico de tempo para filtrar os dados, no filtro 'Mensal' o período de meses e em 'Anual' o período de anos.
2. Nos gráficos de barras ao clicar no nome deles (Exemplo: 'Entradas: Todas ▾') abrirá uma lista de categorias, permitindo que filtre os valores daquela categoria naquele período de tempo escolhido.
3. Ao clicar duas vezes na barra em qualquer gráfico de barras, será redirecionado para a aba 'Histórico' mostrando todas as despesas daquela categoria, naquele mês ou ano daquele tipo categoria (entrada ou saída).
4. Nos gráficos de pizza ao passar o mouse em cima de uma fatia, ou clique longo no Android, mostra o valor daquela fatia.
5. Dois cliques na categoria na legenda oculta tal categoria no gráfico de pizza.
6. Clique simples na categoria 'Outros' no gráfico de pizza o expande mostrando as categorias escondidas e as insere no gráfico substituindo a categoria 'Outros'.
7. Clique longo ou toque longo no Android em qualquer categoria na legenda do gráfico de pizza redireciona para a aba 'Histórico' mostrando todas as despesas daquela categoria, naquele mês ou ano daquele tipo categoria (entrada ou saída).

#### Histórico
1. Na parte de filtros é possível aplicar um filtro de data, tipo, categoria e/ou valor preenchendo os devidos campos e logo após clicar no botão 'Adicionar filtro'.
    1.1. Data: Seleciona um período mensal, anual ou personalizado, basta mudar o modo do filtro clicando no botão na direita acima do retângulo cinza com o texto 'Meses' ou 'Anos' ou 'Personalizado'
    1.2. Tipo: Seleciona um dos dois tipos existentes, entradas para os débitos e saídas para as despesas.
    1.3. Categoria: Seleciona alguma categoria existente para ser filtrada, basta começar a digitar o nome da categoria que logo aparecerá como sugestão.
    1.4. Valor: Possível filtrar valores acima ou abaixo do colocado no campo da direita, filtrar entre os dois valores digitados nos dois campos e filtrar por valores exatamente iguais ao do campo da esquerda.
2. Ao clicar em qualquer lançamento vai abrir uma janela mostrando todas as informações daquele lançamento, dando opções de fechar a janela (botão 'X Cancelar' ou 'X'), excluir (botão '🗑️Excluir' ou '🗑️') que abrirá uma janela de confirmação e editar (botão '✏️ Editar' ou '✏️').
3. Ao clicar em 'Editar' você terá a permissão de editar todas as informações daquele lançamento (data, tipo, categoria, descrição e valor). Para salvar qualquer alteração clique no botão **verde** com o texto **'Salvar'** ou com o ícone **💾**. Caso queria voltar ou sair clique no botão **'Voltar'** ou **⬅** e depois **Cancelar** ou **X**, ou clique fora da janela.
4. Ao preencher os filtros, já será aplicado um filtro rápido que não ficará após mudar o tipo de filtro ou apagar o texto escrito.
5. Ao clicar no botão abaixo de 'Adicionar Filtro', a lista de lançamentos vai mudar baseado no que estiver escolhido
    1.1. Data (mais recente): Ordena pela data mais próxima da atual
    1.2. Data (mais antiga): Ordena pela data mais longe da atual
    1.3. Maior valor: Ordena pelo valor mais alto
    1.4. Menor valor: Ordena pelo valor mais baixo
    1.5. Categoria (A-Z): Ordena por ordem alfabética
    1.6. Categoria (Z-A): Ordena por ordem alfabética inversa

#### Categoria
1. Clicar no botão '+' abre uma janela para adicioar uma nova categoria do tipo das categorias exibidas acima dele (o tipo da categoria exibidos estará no nome da coluna, podendo ser 'Categoria de entrada' ou 'Categoria de saída').
    1.1. Preenche o campo com o nome da categoria e depois clique no botão 'Adicionar' para adicionar.
    1.2. A janela não vai fechar após adicionar, então para sair basta clicar em qualquer lugar da tela fora da janela ou no botão 'Fechar'.
2. Clicar em uma categoria em específico vai abrir uma janela como a descrita no tópico de **Histórico do 2 ao 3**, mas com somente os campos 'Nome' e 'Tipo'
3. Se a largura do aplicativo for pequena, ao invés de ter duas colunas terá somente uma, para trocar de coluna basta clicar no botão '⇄'.

## Licença

Este projeto está licenciado sob a **Creative Commons Atribuição-NãoComercial 4.0 Internacional (CC BY-NC 4.0)**.

Isso significa que qualquer pessoa pode usar, modificar e redistribuir este código livremente, **desde que**:

* Dê o devido crédito ao autor original;
* **Não** venda, comercialize ou lucre com o software ou qualquer versão modificada dele, sem autorização prévia e por escrito.

Consulte o arquivo [`LICENSE`](./LICENSE.md) para os termos completos, ou veja o resumo oficial em:
https://creativecommons.org/licenses/by-nc/4.0/deed.pt\_BR

