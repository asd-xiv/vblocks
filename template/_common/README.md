# _common

`vblocks init` copies these files before the template's own. A template's file
of the same path replaces the common one.

`vblocks init` runs each common hook, then the template's hook of the same name.
The template's hook does not replace the common one.

## Plumbing

The files of the [project folder](../../docs/REFERENCE.md#domain-vocabulary):

```text
package.json    # the scripts, React, TypeScript and the browserslist field
_gitignore      # node_modules, dist and .env
```

**Hooks**:

1. [`post-init-plumbing.sh`](post-init-plumbing.sh) runs in the project folder,
   after the copy:
   - Renames `_gitignore` to `.gitignore`. npm leaves every `.gitignore` out of
     the published VBlocks package
   - Sets the `name` in `package.json` to the name of the project folder
   - Sets `devDependencies.@asd14/vblocks` to the version that runs `init`

## App

The files of the [app folder](../../docs/REFERENCE.md#domain-vocabulary):

```text
src/
├── index.tsx      # mounts App, and the Agentation toolbar in development.
│                  # App comes from ./index.app.tsx, which each template adds
├── index.html     # the #root element
└── index.css      # the global CSS, a Webpack entry of its own
.env.example       # AGENTATION_ENDPOINT, commented out
tsconfig.json      # extends @asd14/ts-config, maps @self/* to src/*
```

- `src/index.tsx` mounts the app
- Each `src/index.<concern>.tsx` defines one concern of it, eg. `index.app.tsx`
  defines App

**Hooks**:

1. [`post-init-app.sh`](post-init-app.sh) runs in the app folder, after the
   copy:
   - Adds `agentation` to the `devDependencies` of the nearest `package.json`,
     the one of the project folder
