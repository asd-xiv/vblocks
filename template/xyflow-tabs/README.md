# xyflow-tabs

One tab per diagram, each with its own details panel.

## App

The files of the [app folder](../../docs/REFERENCE.md#domain-vocabulary), next
to [the common ones](../_common/README.md#app):

```text
src/
├── index.app.tsx          # App: the header, tab bar and details panel, and the selected id
├── pages/
│   ├── build/
│   │   ├── diagram.tsx    # the nodes and edges of one tab, placed and sized in grid cells
│   │   └── details.tsx    # the panel for its selected node or edge
│   └── serve/             # the same two files
├── ui/zoom-level.tsx      # the zoom of the diagram, as a percentage, and a button
│                          # that centers the diagram at 100%
├── utils/grid.ts          # CELL_SIZE and toPixels
└── index.css              # replaces the common one: Tailwind and the xyflow styles
postcss.config.js          # replaces the VBlocks default: Tailwind, and cssnano in production
```

**Hooks**:

1. [`post-init-app.sh`](post-init-app.sh) runs in the app folder, after the
   copy:
   - Adds `@xyflow/react` to the `dependencies` of the nearest `package.json`,
     the one of the [project folder](../../docs/REFERENCE.md#domain-vocabulary)
   - Adds `tailwindcss`, `@tailwindcss/postcss` and `cssnano` to its
     `devDependencies`
   - Sets the page title in `src/index.html` to `xyflow-tabs :: VBlocks`
