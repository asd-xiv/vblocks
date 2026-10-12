import { createRoot } from "react-dom/client"

import "./index.css"

const root = document.querySelector("#root")

if (!root) {
  throw new Error("index.html has no #root element")
}

createRoot(root).render(<h1>Hello World!</h1>)
