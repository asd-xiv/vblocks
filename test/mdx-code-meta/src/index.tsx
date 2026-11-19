import { renderToStaticMarkup } from "react-dom/server"

import Page from "./page.md"

// Print the props each `code` component receives, one JSON line per block.
// `test/mdx-code-meta/test` runs the bundle in Node and compares the lines with
// `expected.txt`
const Code = (props: Record<string, unknown>) => {
  console.log(JSON.stringify(props))

  return null
}

renderToStaticMarkup(<Page components={{ code: Code }} />)
