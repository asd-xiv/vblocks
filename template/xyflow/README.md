# xyflow

One diagram, and a details panel for the selected node or edge.

## App

The files of the [app folder](../../docs/REFERENCE.md#domain-vocabulary), next
to [the common ones](../_common/README.md#app):

```text
src/
├── index.app.tsx       # App: the header, diagram and details panel, and the selected id
├── diagram.tsx         # the nodes and edges, placed and sized in grid cells
├── details.tsx         # the panel for the selected node or edge
├── utils/grid.ts       # CELL_SIZE and toPixels
└── index.css           # replaces the common one: Tailwind and the xyflow styles
postcss.config.js       # extends the VBlocks default: Tailwind in place of postcss-preset-env
```

**Hooks**:

1. [`post-init-app.sh`](post-init-app.sh) runs in the app folder, after the
   copy:
   - Adds `@xyflow/react` to the `dependencies` of the nearest `package.json`,
     the one of the [project folder](../../docs/REFERENCE.md#domain-vocabulary)
   - Adds `tailwindcss` and `@tailwindcss/postcss` to its `devDependencies`
   - Sets the page title in `src/index.html` to `xyflow :: VBlocks`
