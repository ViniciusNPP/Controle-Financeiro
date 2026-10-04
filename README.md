# Meu Financeiro

Aplicativo para controlar finanças pessoais no Windows e Android. Ele permite registrar receitas e despesas, organizar categorias, visualizar histórico e analisar o comportamento financeiro com gráficos.

## O que faz

* Registra entradas e saídas
* Lançamentos recorrentes (automáticos)
* Edição e exclusão de lançamentos
* Adicionar e editar categorias
* 21 categorias predefinidas
* Visualização histórico com filtros
* Ver gráficos por períodos personalizáveis

## Mecânicas principais

### &#x20;Lançamentos recorrentes

Para gastos e ganhos que se repetem (aluguel, salário, assinaturas, mensalidades...), você cadastra o lançamento **uma única vez** e o app cria os próximos automaticamente, na data certa, sem você precisar lembrar. É possível escolher a frequência (diária, semanal, mensal ou anual) e se ela termina em uma data ou nunca termina. Tudo é acompanhado e editado na aba '**Recorrente'**.

Veja o passo a passo em **'Adicionar lançamento'** e em **'Recorrente'**.

### &#x20;Gráficos interativos

Gráficos de barras e de pizza com períodos personalizáveis, filtro por categoria e atalhos para abrir o Histórico já filtrado (clique duplo nas barras, clique longo nas fatias).

### &#x20;Histórico com filtro rápido

Filtros por data, tipo, categoria e valor que já atualizam a lista enquanto você digita, além de ordenação por data, valor ou categoria.

## Como usar

### 1\. Instalação

#### Windows

1. Execute o arquivo "controle\_financeiro\_app.exe"
2. Siga todas as instruções de instalação e mude conforme o que queira. Recomendado criar atalho para maior facilidade de acesso.
3. Clique no aplicativo.exe criado após a instalação para abrir o aplicativo. Ou procure "Controle Financeiro" na barra de pesquisa do Windows e clique para abri-lo.

#### Android

1. Execute o arquivo "Controle-Financeiro.apk"
2. No celular, habilite a opção "Instalar apps desconhecidos" do aplicativo em que você está instalando o app
3. Desabilite a opção "Bloqueador automático" em Segurança e privacidade -> Bloqueador automático para o Android permitir a instalação do app
4. Na janela que abrir, clique em "Mais detalhes"
5. Clique em "Instalar assim mesmo"
6. Clique em abrir para abrir app
7. Pode habilitar novamente o "Bloqueador automático", não atrapalhará em nada o aplicativo depois que ele for instalado

### 2\. Adicionar lançamento

1. Selecione a data clicando sobre o campo de data
2. Selecione o tipo clicando sobre o texto "Entrada" ou "Saída"
3. Selecione a categoria clicando sobre o campo de categoria que ficará disponível assim que selecionar o tipo
4. OPCIONAL: Selecione a descrição clicando sobre o campo de descrição e escreva brevemente o que é a despesa
5. Adicione o valor clicando no campo com o valor padrão de R$0,00
6. OPCIONAL: Para tornar o lançamento recorrente, ative o botão **Recorrente** ao lado do campo de categoria (veja **'como configurar'**)
7. Após todos os campos obrigatórios serem preenchidos, clique no botão Salvar lançamento.

#### Configurando a recorrência

Ao ativar o botão **Recorrente**, abre uma janela para configurar a repetição:

1. **Repetir:** escolha a frequência (Diariamente, Semanalmente, Mensalmente ou Anualmente).
2. **A partir de:** escolha a data em que a recorrência começa.
3. **Termina em:** escolha a data em que a recorrência acaba. Ela sempre fica pelo menos um dia depois da data de início.
4. **Indeterminado:** ative para que a recorrência não tenha data de término (o campo "Termina em" fica desativado).
5. Clique em **Salvar** na janela para confirmar a configuração. Se clicar em **Cancelar** ou fechar no **X**, o botão Recorrente volta a ficar desativado.
6. Preencha o restante do lançamento e clique em **Salvar lançamento**.

> ⚠️ Se a data de início for hoje, o lançamento de hoje é criado na hora e o próximo já fica agendado. Se for uma data futura, só a recorrência é criada, e o lançamento aparece no Histórico quando a data chegar.
> Se você sair da aba Adicionar sem salvar, a recorrência que estava sendo configurada é descartada.

### 3\. Exportar e importar dados

No computador o aplicativo os dados automaticamente em um arquivo `dados\_financeiro.json`, guardado localmente. Somente no celular é necessário exportar para salvar os dados no arquivo mencionado.

**Para exportar:**

1. Clique em "Sincronização"
2. Na aba que abrir, clique no botão "Exportar dados"
3. Selecione o local onde deseja salvar o arquivo `.json`

**Para importar:**

1. Clique em "Sincronização"
2. Na aba que abrir, clique no botão "Importar dados"
3. Procure o arquivo `dados\_financeiro.json` e selecione-o

> ⚠️ ***Atenção***: importar um arquivo ***substitui completamente*** os dados atuais do app pelos dados do arquivo selecionado. Essa ação não pode ser desfeita. Se quiser apenas combinar dados de dois dispositivos sem perder nada, use a opção de "Escolher pasta" descrita abaixo.

**Sincronização automática por pasta (opcional):**

Disponível somente no computador, é usada para que o app sincronize automaticamente a cada alteração (adição, remoção e edição de lançamentos, categorias ou recorrências), combinando os dados sem substituí-los. Essa opção fica disponível na mesma aba de "Sincronização", em "Escolher pasta".

## Observações importantes

* O app usa um arquivo local para armazenamento, então os dados ficam salvos no computador ou no dispositivo onde o app foi usado.
* Para compartilhar os dados entre dispositivos, use as opções de exportar/importar, ou a sincronização automática por pasta no computador.
* Os lançamentos das recorrências são criados quando o aplicativo é aberto. Se o app ficar alguns dias sem ser aberto, todos os lançamentos atrasados são criados de uma vez, cada um com a sua data correta.

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

1. Clicar no botão '+' abre uma janela para adicionar uma nova categoria do tipo das categorias exibidas acima dele (o tipo da categoria exibidos estará no nome da coluna, podendo ser 'Categoria de entrada' ou 'Categoria de saída').
1.1. Preenche o campo com o nome da categoria e depois clique no botão 'Adicionar' para adicionar.
1.2. A janela não vai fechar após adicionar, então para sair basta clicar em qualquer lugar da tela fora da janela ou no botão 'Fechar'.
2. Clicar em uma categoria em específico vai abrir uma janela como a descrita no tópico de **Histórico do 2 ao 3**, mas com somente os campos 'Nome' e 'Tipo'
3. Se a largura do aplicativo for pequena, ao invés de ter duas colunas terá somente uma, para trocar de coluna basta clicar no botão '⇄'.

#### Recorrente

A aba **Recorrente** serve para acompanhar e gerenciar todos os lançamentos que se repetem automaticamente. Cada recorrência funciona como um "molde": quando a data chega, o app cria um lançamento normal no Histórico com o mesmo tipo, categoria, descrição e valor do molde, e a data do dia em que ele foi lançado. As recorrências são criadas na aba **Adicionar** (veja **'Configurando a recorrência'**).

1. A aba mostra duas listas:
1.1. **Em andamento:** recorrências que ainda vão gerar novos lançamentos, ordenadas pela próxima data mais próxima.
1.2. **Finalizadas:** recorrências cuja data de término já passou e que não geram mais lançamentos.
2. Cada recorrência mostra quatro informações:
2.1. **Nome:** a descrição do lançamento (se não tiver descrição, mostra o nome da categoria).
2.2. **Próxima:** a data em que o próximo lançamento será criado.
2.3. **Término:** a data em que a recorrência acaba, ou '-' se for indeterminada.
2.4. **Valor:** em **verde** para entradas e em **vermelho** para saídas.
3. Ao clicar em uma recorrência abre uma janela com **duas páginas**, que você alterna pelas setas **‹ ›** no topo da janela:
3.1. **Página 1:** os dados do lançamento (tipo, categoria, descrição e valor).
3.2. **Página 2:** as regras da recorrência (Repetir, A partir de, Próxima e Termina em).
4. Ao clicar em 'Editar' é possível alterar as informações das **duas páginas**, independente de qual delas estava aberta. Também é possível ativar ou desativar o 'Indeterminado' para definir ou remover a data de término. Para salvar clique no botão **verde** 'Salvar' ou **💾**. Para sair da edição sem salvar, clique em 'Voltar' ou **⬅**.
5. Ao clicar em 'Excluir' (e confirmar) a recorrência é removida e nenhum lançamento novo será criado.
6. Se a largura do aplicativo for pequena, ao invés de duas listas lado a lado, aparece somente uma, e para trocar entre 'Em andamento' e 'Finalizadas' basta clicar no botão '⇄'.

> ⚠️ Editar ou excluir uma recorrência **não altera** os lançamentos que ela já gerou: eles continuam no Histórico e devem ser editados ou excluídos por lá, individualmente.

## Licença

Este projeto está licenciado sob a **Creative Commons Atribuição-NãoComercial 4.0 Internacional (CC BY-NC 4.0)**.

Isso significa que qualquer pessoa pode usar, modificar e redistribuir este código livremente, **desde que**:

* Dê o devido crédito ao autor original;
* **Não** venda, comercialize ou lucre com o software ou qualquer versão modificada dele, sem autorização prévia e por escrito.

Consulte o arquivo **'LICENSE'** para os termos completos, ou veja o resumo oficial em:
https://creativecommons.org/licenses/by-nc/4.0/deed.pt\_BR

