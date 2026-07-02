# Create Your First App On Your Phone

Build a tiny Next.js page, open it in your phone browser, push it to GitHub, and deploy it with Vercel.

This is the first complete loop: edit, run, open, commit, push, deploy.

## Create The App

Inside Ubuntu:

```sh
cd ~/projects
npx create-next-app@latest my-app
cd my-app
```

When the installer asks questions, the defaults are fine for a first app.

## Start A tmux Session

```sh
tmux new -s app
```

## Open The Editor

```sh
code .
```

or:

```sh
pc code .
```

## Run The Dev Server

Split tmux, then:

```sh
npm run dev
```

Open it:

```sh
open http://127.0.0.1:3000
```

or:

```sh
pc open http://127.0.0.1:3000
```

## Add OpenCode

Start OpenCode from the project folder:

```sh
ocode --auto
```

Do not start it from `/root`, `~`, or the whole `~/projects` folder.

## Save It With Git

```sh
git status
git add .
git commit -m "Create first phone app"
```

## Push To GitHub

Authenticate once:

```sh
gh auth login
```

Create a repo and push:

```sh
gh repo create my-app --private --source=. --remote=origin --push
```

For later changes:

```sh
git add .
git commit -m "Describe the change"
git push
```

Before every commit, check that you are not committing secrets:

```sh
git diff --cached
```

## Deploy With Vercel

Authenticate once:

```sh
vercel login
```

Link and deploy:

```sh
vercel link
vercel deploy --prod
```

## Optional: Add Neon Later

Do not add a database until the plain app deploys.

```sh
neon auth
neon projects create --name my-app
npm install @neondatabase/serverless
```

Never commit `.env.local` or a real database URL.
