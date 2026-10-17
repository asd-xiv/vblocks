import { useState } from "react"
import { createRoot } from "react-dom/client"

import { BuildDetails } from "./pages/build/details"
import { BuildDiagram } from "./pages/build/diagram"
import { ServeDetails } from "./pages/serve/details"
import { ServeDiagram } from "./pages/serve/diagram"

import "@xyflow/react/dist/style.css"
import "./index.css"

/**
 * The tabs of the diagram. For a new tab, add a folder in `pages/` with a
 * diagram and its details, then add it here and in each slot of `App`
 */
const TABS = [
  { id: "build", label: "Build" },
  { id: "serve", label: "Serve" },
] as const

type TabId = (typeof TABS)[number]["id"]

const App = () => {
  const [tabId, setTabId] = useState<TabId>("build")
  const [selectedId, setSelectedId] = useState<string>()

  const selectTab = (nextTabId: TabId) => {
    setTabId(nextTabId)
    // An id of one tab names nothing in the other
    setSelectedId(undefined)
  }

  return (
    <div className="grid h-screen grid-rows-[auto_1fr] bg-stone-50 text-stone-900">
      <header className="border-b border-stone-200 bg-white px-6 py-3">
        <h1 className="text-lg font-semibold">VBlocks</h1>
        <p className="text-sm text-stone-500">
          How serve and build turn src/ into a page
        </p>
      </header>

      <div className="grid min-h-0 grid-cols-[1fr_20rem]">
        <main className="flex min-h-0 flex-col">
          <nav className="flex gap-4 border-b border-stone-200 bg-white px-6">
            {TABS.map(tab => (
              <button
                key={tab.id}
                type="button"
                aria-selected={tab.id === tabId}
                onClick={() => {
                  selectTab(tab.id)
                }}
                className={
                  tab.id === tabId
                    ? "cursor-pointer border-b-2 border-stone-900 py-2 text-sm font-medium"
                    : "cursor-pointer border-b-2 border-transparent py-2 text-sm text-stone-500 hover:text-stone-900"
                }>
                {tab.label}
              </button>
            ))}
          </nav>

          <div className="min-h-0 flex-1">
            {tabId === "build" && <BuildDiagram onSelect={setSelectedId} />}
            {tabId === "serve" && <ServeDiagram onSelect={setSelectedId} />}
          </div>
        </main>

        <aside className="overflow-y-auto border-l border-stone-200 bg-white p-6">
          {selectedId === undefined ? (
            <p className="text-sm text-stone-500">Select a node or an edge</p>
          ) : (
            <>
              {tabId === "build" && <BuildDetails selectedId={selectedId} />}
              {tabId === "serve" && <ServeDetails selectedId={selectedId} />}
            </>
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
