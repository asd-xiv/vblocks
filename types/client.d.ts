/**
 * Types for the files that `../defaults/webpack.config.js` loads on `import`.
 *
 * @example
 * // tsconfig.json
 * { "compilerOptions": { "types": ["@asd14/vblocks/client"] } }
 */

declare module "*.module.css" {
  /** Class names by their camelCase key, eg. `styles["myClass"]` for `.my-class`. */
  const classNames: { readonly [key: string]: string }

  export default classNames
}

declare module "*.css" {}

declare module "*.jpg" {
  /** The URL of the image, a `data:` URL when the build inlines it. */
  const url: string

  export default url
}

declare module "*.gif" {
  /** The URL of the image, a `data:` URL when the build inlines it. */
  const url: string

  export default url
}

declare module "*.png" {
  /** The URL of the image, a `data:` URL when the build inlines it. */
  const url: string

  export default url
}

declare module "*.svg" {
  /** The URL of the image, a `data:` URL when the build inlines it. */
  const url: string

  export default url
}

declare module "*.woff" {
  /** The URL of the font, a `data:` URL in a single-file build. */
  const url: string

  export default url
}

declare module "*.woff2" {
  /** The URL of the font, a `data:` URL in a single-file build. */
  const url: string

  export default url
}

declare module "*.ttf" {
  /** The URL of the font, a `data:` URL in a single-file build. */
  const url: string

  export default url
}

declare module "*.eot" {
  /** The URL of the font, a `data:` URL in a single-file build. */
  const url: string

  export default url
}

declare module "*.md" {
  import type { ComponentType } from "react"

  /**
   * The Markdown document as a React component. VBlocks compiles `.md` with MDX,
   * so it takes the same `components` as an `.mdx` import.
   *
   * The `code` component of `components` also receives the meta of a code block
   * as props, eg. `file: "src/app.tsx"` for a block that opens with
   * `tsx file="src/app.tsx"`.
   *
   * @example
   * import Notes from "./notes.md"
   *
   * <Notes components={{ h1: Title }} />
   */
  const MDXContent: ComponentType<{
    components?: Record<string, ComponentType<Record<string, unknown>>>
  }>

  export default MDXContent
}

declare module "*.mdx" {
  import type { ComponentType } from "react"

  /**
   * The MDX document as a React component. `components` replaces the element
   * MDX renders for a tag, eg. `{ h1: Title }`.
   *
   * The `code` component of `components` also receives the meta of a code block
   * as props, eg. `file: "src/app.tsx"` for a block that opens with
   * `tsx file="src/app.tsx"`.
   *
   * @example
   * import Intro from "./intro.mdx"
   *
   * <Intro components={{ h1: Title }} />
   */
  const MDXContent: ComponentType<{
    components?: Record<string, ComponentType<Record<string, unknown>>>
  }>

  export default MDXContent
}

declare module "*?raw" {
  /**
   * The text of the file, as Vite's `?raw` gives it. No loader changes it.
   *
   * @example
   * import { Variants } from "./variants.js"
   * import variantsSource from "./variants.tsx?raw"
   *
   * <Variants />
   * <pre>{variantsSource}</pre>
   */
  const source: string

  export default source
}

declare const process: {
  /**
   * The `.env` variables Webpack writes into the bundle. The browser has no
   * other part of Node's `process`.
   *
   * @example
   * const apiUrl = process.env["API_URL"]
   */
  env: Record<string, string | undefined>
}
