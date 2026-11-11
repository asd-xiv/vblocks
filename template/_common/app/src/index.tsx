import { Agentation } from "agentation"
import { createRoot } from "react-dom/client"

import { App } from "./index.app.tsx"

const root = document.querySelector("#root")

if (!root) {
  throw new Error("index.html has no #root element")
}

// Webpack writes NODE_ENV into the bundle at build time. A production build
// drops this branch, and the Agentation toolbar with it
createRoot(root).render(
  process.env["NODE_ENV"] === "development" ? (
    <>
      {/* Agentation finds React by this attribute. #root has no fiber
          (agentation#225) */}
      <div data-reactroot="" style={{ display: "contents" }}>
        <App />
      </div>
      <Agentation endpoint={process.env["AGENTATION_ENDPOINT"]} />
    </>
  ) : (
    <App />
  )
)
