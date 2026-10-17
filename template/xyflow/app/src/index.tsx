import { useState } from "react"
import { createRoot } from "react-dom/client"

import { Details } from "./details"
import { Diagram } from "./diagram"

import "@xyflow/react/dist/style.css"
import "./index.css"

const App = () => {
  const [selectedId, setSelectedId] = useState<string>()

  return (
    <div className="grid h-screen grid-rows-[auto_1fr] bg-stone-50 text-stone-900">
      <header className="border-b border-stone-200 bg-white px-6 py-3">
        <h1 className="text-lg font-semibold">VBlocks</h1>
        <p className="text-sm text-stone-500">How build turns src/ into a page</p>
      </header>

      <div className="grid min-h-0 grid-cols-[1fr_20rem]">
        <main className="min-h-0">
          <Diagram onSelect={setSelectedId} />
        </main>

        <aside className="overflow-y-auto border-l border-stone-200 bg-white p-6">
          {selectedId === undefined ? (
            <p className="text-sm text-stone-500">Select a node or an edge</p>
          ) : (
            <Details selectedId={selectedId} />
          )}
        </aside>
      </div>
    </div>
  )
}

const root = document.querySelector("#root")

if (!root) {
  throw new Error("index.html has no #root element")
}

createRoot(root).render(<App />)
