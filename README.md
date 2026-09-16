# Gamer & Cell — Dashboard

Dashboard HTML (sem servidor próprio) que mostra os totais mensais de 2026 a partir da
planilha `FECHAMENTO CONSERTO LT 2026.xlsx` **e** permite cadastrar novos lançamentos
direto pelo navegador, salvando no Firebase (Firestore) — os dados aparecem em tempo real
em qualquer aparelho logado.

## Arquivos

- `index.html` — a página do dashboard (login, gráficos, tabela, botão "+ Novo Lançamento")
- `logo.jpeg` — logo da Gamer & Cell usada no login e no cabeçalho
- `data.js` — totais extraídos da planilha Excel (histórico "oficial", gerado pelo script abaixo)
- `export_data.ps1` — script que lê a planilha e regrava o `data.js`
- `firebase-config.js` — credenciais do SEU projeto Firebase (você preenche, ver abaixo)

O dashboard mostra a **soma** do que está no `data.js` (planilha) com os lançamentos salvos
no Firebase — então tudo que você cadastrar pelo botão já entra nos gráficos e KPIs na hora.

## Configurar o Firebase (uma vez só)

1. Acesse **console.firebase.google.com** e crie um projeto novo (gratuito, plano Spark).
2. No menu lateral, vá em **Build → Authentication** → aba **Sign-in method** → ative
   **E-mail/senha**.
3. Ainda em Authentication, aba **Users** → **Add user** → cadastre o e-mail e senha que
   você (e o Alex, se quiser) vão usar para entrar no dashboard.
4. Vá em **Build → Firestore Database** → **Create database** → modo **produção** →
   escolha a região mais próxima (ex: `southamerica-east1`).
5. Na aba **Rules** do Firestore, substitua pelo conteúdo abaixo e publique:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /lancamentos/{doc} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
   Isso garante que só quem estiver logado (passo 2/3) consegue ler ou gravar dados.
6. No ícone de engrenagem (canto superior esquerdo) → **Configurações do projeto** →
   role até **Seus apps** → clique no ícone `</>` (Web) → dê um nome (ex: "dashboard") →
   **Registrar app**. O Firebase mostra um bloco `firebaseConfig = {...}`.
7. Copie os valores para o arquivo `firebase-config.js` desta pasta, substituindo os
   `COLE_AQUI` / `SEU-PROJETO`.
8. Abra `index.html` de novo — a tela de login deve aparecer normalmente (sem o aviso
   amarelo de "Firebase não configurado").

> O conteúdo de `firebase-config.js` **não é secreto** — pode subir para o GitHub
> normalmente. Quem protege os dados são as regras do passo 5 (exige login) e as senhas
> criadas no passo 3.

## Como usar no dia a dia

- **Cadastrar um conserto:** clique em **+ Novo Lançamento**, preencha Mês, OS, Valor,
  Forma(s) de Pagamento (pode dividir entre mais de uma), Custo da Peça e Custo Alex — o
  resto (comissão, custo do cartão, lucro) é calculado igual à planilha. Salvar grava no
  Firebase e atualiza o dashboard na hora, em qualquer aparelho logado.
- **Excluir um lançamento:** na tabela "Últimos lançamentos", clique em **Excluir**.
- **Fechar o mês na planilha:** continue preenchendo a planilha Excel como sempre (ela
  continua sendo o "histórico oficial"). Depois de fechar um mês nela, rode
  `export_data.ps1` para atualizar o `data.js` — os lançamentos que você já tiver
  cadastrado pelo Firebase para aquele mês podem então ser apagados do dashboard (já
  estão contados na planilha) para não somar em dobro.

## Como atualizar os dados da planilha

1. Feche a planilha `FECHAMENTO CONSERTO LT 2026.xlsx` no Excel (se estiver aberta).
2. Clique com o botão direito em `export_data.ps1` → **Executar com o PowerShell**
   (ou abra um terminal PowerShell nesta pasta e rode `./export_data.ps1`).
3. O arquivo `data.js` é reescrito com os totais mais recentes.

## Como publicar atualizações no GitHub

1. Nesta pasta, rode:
   ```
   git add -A
   git commit -m "Atualiza dashboard"
   git push
   ```
2. O GitHub Pages atualiza sozinho em alguns minutos em
   `https://pdvfacil.github.io/conserto/`.

> Dica: no console do Firebase, em **Authentication → Settings → Authorized domains**,
> adicione `pdvfacil.github.io` para garantir que o login funcione no endereço do
> GitHub Pages.
