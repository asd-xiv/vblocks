/**
 * Types for the files `../webpack.config.js` teaches `import` to load.
 *
 * @example
 * // tsconfig.json
 * { "compilerOptions": { "types": ["@asd14/vblocks/client"] } }
 */

declare module "*.module.css" {
  /**
   * Class names by their camelCase key, `.my-class` is `styles.myClass`.
   *
   * Typed `any` so `styles.myClass` passes `noPropertyAccessFromIndexSignature`.
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const classNames: any

  export default classNames
}

declare module "*.css" {}

/**
 * The URL of the image, a `data:` URL when the build inlines it.
 */
declare module "*.jpg" {
  const url: string

  export default url
}

declare module "*.gif" {
  const url: string

  export default url
}

declare module "*.png" {
  const url: string

  export default url
}

declare module "*.svg" {
  const url: string

  export default url
}

/**
 * The URL of the font, a `data:` URL in a single-file build.
 */
declare module "*.woff" {
  const url: string

  export default url
}

declare module "*.woff2" {
  const url: string

  export default url
}

declare module "*.ttf" {
  const url: string

  export default url
}

declare module "*.eot" {
  const url: string

  export default url
}

/**
 * The MDX document as a React component. `components` replaces the element
 * MDX renders for a tag, eg. `{ h1: Title }`.
 *
 * @example
 * import Intro from "./intro.mdx"
 *
 * <Intro components={{ h1: Title }} />
 */
declare module "*.mdx" {
  import type { ComponentType } from "react"

  const MDXContent: ComponentType<{
    components?: Record<string, ComponentType<Record<string, unknown>>>
  }>

  export default MDXContent
}

/**
 * The `.env` variables Webpack writes into the bundle. The browser has no
 * other part of Node's `process`.
 *
 * @example
 * const apiUrl = process.env["API_URL"]
 */
declare const process: {
  env: Record<string, string | undefined>
}
