import { Panel, useReactFlow, useViewport } from "@xyflow/react"

/**
 * The zoom of the diagram, as a percentage, and a button that centers the
 * diagram at 100%. Render it inside `<ReactFlow>`, both hooks read the viewport
 * from there
 */
const ZoomLevel = () => {
  const { zoom } = useViewport()
  const { fitView } = useReactFlow()

  return (
    <Panel
      position="top-right"
      className="flex items-center gap-2 rounded border border-stone-200 bg-white px-2 py-1 font-mono text-xs leading-none text-stone-600">
      <span>{Math.round(zoom * 100)}%</span>
      <button
        type="button"
        onClick={() => {
          void fitView({ minZoom: 1, maxZoom: 1, duration: 200 })
        }}
        className="cursor-pointer text-stone-500 hover:text-stone-900">
        Reset
      </button>
    </Panel>
  )
}

export { ZoomLevel }
