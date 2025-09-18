[![Release](https://github.com/asd-xiv/vblocks/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/asd-xiv/vblocks/actions/workflows/release.yml)
[![npm version](https://img.shields.io/npm/v/@asd14/vblocks.svg)](https://www.npmjs.com/package/@asd14/vblocks)

# @asd14/vblocks

> 📜 POSIX + 📦 Webpack, an unlikely story!

Zero-config Webpack wrapper for React applications with opinionated defaults and
modern toolchain integration.

## Features

- **Zero Configuration** - Works out of the box with sensible defaults
- **Convention over Configuration** - Smart project structure detection
- **Modern Toolchain** - SWC, TailwindCSS, PostCSS, CSS Modules, MDX support
- **Flexible Configuration** - Project configs override defaults when present
- **Development Experience** - Hot reload, React Refresh, bundle analysis
- **Production Ready** - Optimized builds with code splitting and caching

<!-- vim-markdown-toc GFM -->

- [Installation](#installation)
  - [Peer Dependencies](#peer-dependencies)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Configuration](#configuration)
  - [Supported Configuration Files](#supported-configuration-files)
  - [Configuration Override Example](#configuration-override-example)
- [Commands](#commands)
  - [`vblocks serve`](#vblocks-serve)
  - [`vblocks build`](#vblocks-build)
  - [`vblocks eject webpack`](#vblocks-eject-webpack)
- [Features in Detail](#features-in-detail)
  - [CSS Modules Support](#css-modules-support)
  - [Asset Handling](#asset-handling)
  - [Environment Variables](#environment-variables)
  - [Path Aliases](#path-aliases)
- [License](#license)

<!-- vim-markdown-toc -->

## Installation

```sh
npm install --save-dev @asd14/vblocks
```

### Peer Dependencies

This package requires and assumes you already installed:

```json
{
  "peerDependencies": {
    "react": "^18 || ^19",
    "react-dom": "^18 || ^19"
  }
}
```

## Usage

### Quick Start

```sh
# Start development server
npx vblocks serve

# Build for production
npx vblocks build

# View webpack configuration
npx vblocks eject webpack
```

### Project Structure

VBlocks expects a standard React project structure:

```
your-project/
├── src/
│   ├── index.tsx          # Application entry point
│   ├── index.html         # HTML template
│   ├── index.css          # Global styles (optional)
│   └── public/
│       ├── favicon.svg    # Favicon (optional)
│       └── robots.txt     # Robots file (optional)
├── .env                   # Environment variables (optional)
└── dist/                  # Build output
```

## How It Works

VBlocks is a **POSIX shell script wrapper** around Webpack that:

1. **Detects configuration files** - Uses project configs when available, falls
   back to defaults
2. **Sets environment variables** - Passes config paths to Webpack via env vars
3. **Proxies commands** - `build` and `serve` are passed directly to `webpack`
   with custom parameters
4. **Provides configuration inspection** - `eject` outputs configuration content
   for review

## Configuration

Project files take precedence over defaults:

1. **Project configs** (in your project root) - highest priority
2. **Default configs** (from vblocks package) - fallback

### Supported Configuration Files

- `webpack.config.js` - Webpack configuration
- `postcss.config.js` - PostCSS configuration
- `tailwind.config.js` - TailwindCSS configuration
- `.swcrc` - SWC configuration

### Configuration Override Example

Create any of these files in your project root to customize behavior:

```js
// tailwind.config.js - customize TailwindCSS
export default {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: "#your-color"
      }
    }
  }
}
```

## Commands

### `vblocks serve`

**Proxies to**:
`npx webpack serve --config $VB_WEBPACK_CONFIG --env entryDir=$PROJECT_DIR ...`

Starts development server with:

- Hot Module Replacement
- Automatic browser opening
- Bundle analyzer (non-opening)
- Error overlay
- History API fallback for SPAs

### `vblocks build`

**Proxies to**:
`npx webpack build --config $VB_WEBPACK_CONFIG --env entryDir=$PROJECT_DIR ...`

Creates production build with:

- Minified assets
- Content hashing
- Optimized chunks
- Performance hints

### `vblocks eject webpack`

**Special command** - Outputs the webpack configuration to stdout for
inspection:

```sh
npx vblocks eject webpack > webpack.config.js
```

## Features in Detail

### CSS Modules Support

- **Global CSS** - `import './styles.css'`
- **Local CSS Modules** - `import styles from './component.module.css'`
- **camelCase exports** - `.my-class` becomes `styles.myClass`
- **Development-friendly naming** - includes class names in dev builds

### Asset Handling

- **Images** - Automatic optimization, inlined if < 10KB
- **Fonts** - Copied to `fonts/` directory
- **Favicon & Robots** - Automatically included in build

### Environment Variables

VBlocks automatically loads `.env` files in your project root:

```env
# .env
REACT_APP_API_URL=https://api.example.com
```

Access in your code:

```tsx
const apiUrl = process.env.REACT_APP_API_URL
```

### Path Aliases

Built-in alias for cleaner imports:

```tsx
// Instead of: import { Component } from '../../../components'
import { Component } from "@self/components"
```

## License

BSD 3-Clause
