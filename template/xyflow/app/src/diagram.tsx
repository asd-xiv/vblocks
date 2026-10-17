import { useCallback } from "react"
import {
  addEdge,
  Background,
  Controls,
  Handle,
  MarkerType,
  Position,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type Edge,
  type Node,
  type NodeProps,
  type NodeTypes,
  type OnConnect,
  type OnSelectionChangeFunc,
} from "@xyflow/react"

import { ZoomLevel } from "./ui/zoom-level"
import { CELL_SIZE, toPixels } from "./utils/grid"

type StepNode = Node<{ label: string; detail: string }, "step">

/**
 * The graph. Edit these two lists, this specimen draws the VBlocks build
 */
const diagramNodes = toPixels<StepNode>([
  {
    id: "index.tsx",
    type: "step",
    position: { x: 0, y: 0 },
    size: { width: 12, height: 4 },
    data: { label: "src/index.tsx", detail: "The application entry point" },
  },
  {
    id: "index.css",
    type: "step",
    position: { x: 14, y: 0 },
    size: { width: 12, height: 4 },
    data: { label: "src/index.css", detail: "The global CSS" },
  },
  {
    id: "swc",
    type: "step",
    position: { x: 0, y: 7 },
    size: { width: 12, height: 4 },
    data: { label: "SWC", detail: "Compiles TypeScript and JSX" },
  },
  {
    id: "postcss",
    type: "step",
    position: { x: 14, y: 7 },
    size: { width: 12, height: 4 },
    data: { label: "PostCSS", detail: "Runs Tailwind and cssnano" },
  },
  {
    id: "index.html",
    type: "step",
    position: { x: 28, y: 7 },
    size: { width: 12, height: 4 },
    data: { label: "src/index.html", detail: "The HTML template" },
  },
  {
    id: "webpack",
    type: "step",
    position: { x: 14, y: 14 },
    size: { width: 12, height: 4 },
    data: { label: "Webpack", detail: "Bundles the modules and the assets" },
  },
  {
    id: "dist",
    type: "step",
    position: { x: 14, y: 21 },
    size: { width: 12, height: 4 },
    data: { label: "dist/index.html", detail: "The bundle" },
  },
])

const diagramEdges: Edge[] = [
  { id: "index.tsx-swc", source: "index.tsx", target: "swc" },
  { id: "index.css-postcss", source: "index.css", target: "postcss" },
  { id: "swc-webpack", source: "swc", target: "webpack" },
  { id: "postcss-webpack", source: "postcss", target: "webpack" },
  { id: "index.html-webpack", source: "index.html", target: "webpack" },
  { id: "webpack-dist", source: "webpack", target: "dist", animated: true },
]

const Step = ({ data, selected }: NodeProps<StepNode>) => (
  <div
    className={`h-full w-full overflow-hidden rounded-md border bg-white px-4 py-2 shadow-sm ${selected ? "border-stone-900" : "border-stone-300"}`}>
    <Handle type="target" position={Position.Top} />
    <div className="font-mono text-sm font-semibold text-stone-900">
      {data.label}
    </div>
    <div className="text-xs text-stone-500">{data.detail}</div>
    <Handle type="source" position={Position.Bottom} />
  </div>
)

const nodeTypes: NodeTypes = { step: Step }

type DiagramProps = {
  onSelect: (entityId: string | undefined) => void
}

const Diagram = ({ onSelect }: DiagramProps) => {
  const [nodes, , onNodesChange] = useNodesState(diagramNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(diagramEdges)

  const onConnect: OnConnect = useCallback(
    connection => {
      setEdges(currentEdges => addEdge(connection, currentEdges))
    },
    [setEdges]
  )

  // Memoize it, as React Flow asks for onSelectionChange
  const onSelectionChange: OnSelectionChangeFunc = useCallback(
    selection => {
      onSelect(selection.nodes[0]?.id ?? selection.edges[0]?.id)
    },
    [onSelect]
  )

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      nodeTypes={nodeTypes}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
      onConnect={onConnect}
      onSelectionChange={onSelectionChange}
      // Snap a dragged node to the dots of <Background>
      snapToGrid
      snapGrid={[CELL_SIZE, CELL_SIZE]}
      defaultEdgeOptions={{ markerEnd: { type: MarkerType.ArrowClosed } }}
      // Center the diagram at 100%, the fit-view button of <Controls> still
      // fits it to the screen
      fitView
      fitViewOptions={{ minZoom: 1, maxZoom: 1 }}>
      <Background gap={CELL_SIZE} />
      <Controls />
      <ZoomLevel />
    </ReactFlow>
  )
}

export { Diagram, diagramEdges, diagramNodes }
