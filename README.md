# Gamer & Cell — Dashboard

Dashboard HTML (sem servidor próprio) que mostra os totais mensais de 2026 a partir da
planilha `FECHAMENTO CONSERTO LT 2026.xlsx` **e** permite cadastrar novos lançamentos
direto pelo navegador, salvando no Firebase (Firestore) — os dados aparecem em tempo real
em qualquer aparelho logado. Tem controle de acesso por usuário: **Administrador** (vê e
cadastra tudo, inclusive outros usuários) e **Somente Leitura** (só visualiza).

## Arquivos

- `index.html` — a página do dashboard (login, gráficos, tabela, lançamentos, configurações)
- `logo.jpeg` — logo da Gamer & Cell usada no login e no cabeçalho
- `data.js` — totais extraídos da planilha Excel (histórico "oficial", gerado pelo script abaixo)
- `export_data.ps1` — script que lê a planilha e regrava o `data.js`
- `firebase-config.js` — credenciais do SEU projeto Firebase (você preenche, ver abaixo)

## Configurar o Firebase (uma vez só)

1. Acesse **console.firebase.google.com** e crie um projeto novo (gratuito, plano Spark).
2. **Build → Authentication → Sign-in method** → ative **E-mail/senha**.
3. **Build → Firestore Database → Create database** → modo **produção** → região mais
   próxima (ex: `southamerica-east1`).
4. Configurações do projeto (ícone de engrenagem) → **Seus apps** → `</>` (Web) → registra
   um app → copia o bloco `firebaseConfig` pro arquivo `firebase-config.js` desta pasta.

## Controle de acesso (Administrador x Somente Leitura)

O dashboard guarda, para cada usuário logado, um documento na coleção `usuarios` do
Firestore (`usuarios/{uid}` com os campos `email` e `role`: `admin` ou `leitura`). As
**regras de segurança** do Firestore são o que realmente impede um usuário "Somente
Leitura" de cadastrar ou apagar dados — esconder o botão na tela não seria suficiente.

**1. Publique estas regras** (Firestore Database → aba **Rules** → colar e clicar em
**Publish**):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null &&
        exists(/databases/$(database)/documents/usuarios/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.role == 'admin';
    }
    function hasAccess() {
      return request.auth != null &&
        exists(/databases/$(database)/documents/usuarios/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.role in ['admin','leitura'];
    }

    match /lancamentos/{doc} {
      allow read: if hasAccess();
      allow write: if isAdmin();
    }

    match /usuarios/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
  }
}
```

**2. Cadastre o PRIMEIRO administrador manualmente** (depois disso, todos os outros
usuários podem ser criados pelo próprio dashboard, em **⚙️ Configurações**):

- Firestore Database → aba **Dados** → **Iniciar coleção**
- ID da coleção: `usuarios`
- ID do documento: cole o UID do seu usuário (veja em **Authentication → Users**, coluna
  "User UID" — para a conta que você já criou, o UID é `YNfj9BjDDYWXkV1sTGwH6HKDPc53`)
- Campos do documento:
  - `email` (string) — o e-mail que você usa para entrar no dashboard
  - `role` (string) — `admin`
- Salvar.

> ⚠️ **Sem esses dois passos, ninguém consegue entrar no dashboard** (nem ver, nem
> cadastrar nada) — as regras exigem que todo usuário logado tenha um documento em
> `usuarios` com um papel válido.

## Como usar no dia a dia

- **Cadastrar um conserto:** clique em **+ Novo Lançamento** (só aparece para
  Administradores), preencha Mês, OS, Valor, Forma(s) de Pagamento (pode dividir entre mais
  de uma), Custo da Peça e Custo Alex. Salvar grava no Firebase e atualiza o dashboard na
  hora, em qualquer aparelho logado.
- **Excluir um lançamento:** na tabela "Últimos lançamentos", clique em **Excluir**
  (só Administradores veem esse botão).
- **Gerenciar usuários:** clique em **⚙️ Configurações** (só aparece para Administradores).
  Lá você cadastra um novo usuário (e-mail + senha inicial + papel) ou remove o acesso de
  alguém. Criar um usuário ali NÃO desconecta a sua sessão de admin.
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
