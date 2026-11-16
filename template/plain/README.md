# plain

A "Hello World!" heading.

## App

The files of the [app folder](../../docs/REFERENCE.md#domain-vocabulary), next
to [the common ones](../_common/README.md#app):

```text
src/
└── index.app.tsx    # App: a "Hello World!" heading
```

**Hooks**:

1. [`post-init-app.sh`](post-init-app.sh) runs in the app folder, after the
   copy:
   - Sets the page title in `src/index.html` to `Hello World :: VBlocks`
