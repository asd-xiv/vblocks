import { useCallback } from "react"
import { createRoot } from "react-dom/client"
import {
  addEdge,
  Background,
  Controls,
  Handle,
  Position,
  ReactFlow,
  useEdgesState,
  useNodesState,
  type Edge,
  type Node,
  type NodeProps,
  type NodeTypes,
  type OnConnect,
} from "@xyflow/react"

import "@xyflow/react/dist/style.css"
import "./index.css"

type StepNode = Node<{ label: string; detail: string }, "step">

/**
 * The graph. Edit these two lists, this specimen draws the VBlocks build.
 */
const initialNodes: StepNode[] = [
  {
    id: "index.tsx",
    type: "step",
    position: { x: 0, y: 0 },
    data: { label: "src/index.tsx", detail: "The application entry point" },
  },
  {
    id: "index.css",
    type: "step",
    position: { x: 280, y: 0 },
    data: { label: "src/index.css", detail: "The global CSS" },
  },
  {
    id: "swc",
    type: "step",
    position: { x: 0, y: 140 },
    data: { label: "SWC", detail: "Compiles TypeScript and JSX" },
  },
  {
    id: "postcss",
    type: "step",
    position: { x: 280, y: 140 },
    data: { label: "PostCSS", detail: "Runs Tailwind and cssnano" },
  },
  {
    id: "index.html",
    type: "step",
    position: { x: 560, y: 140 },
    data: { label: "src/index.html", detail: "The HTML template" },
  },
  {
    id: "webpack",
    type: "step",
    position: { x: 280, y: 280 },
    data: { label: "Webpack", detail: "Bundles the modules and the assets" },
  },
  {
    id: "dist",
    type: "step",
    position: { x: 280, y: 420 },
    data: { label: "dist/index.html", detail: "The build output" },
  },
]

const initialEdges: Edge[] = [
  { id: "index.tsx-swc", source: "index.tsx", target: "swc" },
  { id: "index.css-postcss", source: "index.css", target: "postcss" },
  { id: "swc-webpack", source: "swc", target: "webpack" },
  { id: "postcss-webpack", source: "postcss", target: "webpack" },
  { id: "index.html-webpack", source: "index.html", target: "webpack" },
  { id: "webpack-dist", source: "webpack", target: "dist", animated: true },
]

const Step = ({ data }: NodeProps<StepNode>) => (
  <div className="w-56 rounded-md border border-stone-300 bg-white px-4 py-2 shadow-sm">
    <Handle type="target" position={Position.Top} />
    <div className="font-mono text-sm font-semibold text-stone-900">
      {data.label}
    </div>
    <div className="text-xs text-stone-500">{data.detail}</div>
    <Handle type="source" position={Position.Bottom} />
  </div>
)

const nodeTypes: NodeTypes = { step: Step }

const Playground = () => {
  const [nodes, , onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges)

  const onConnect: OnConnect = useCallback(
    connection => {
      setEdges(currentEdges => addEdge(connection, currentEdges))
    },
    [setEdges]
  )

  return (
    <div className="h-screen w-screen">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        fitView>
        <Background />
        <Controls />
      </ReactFlow>
    </div>
  )
}

const root = document.querySelector("#root")

if (!root) {
  throw new Error("index.html has no #root element")
}

createRoot(root).render(<Playground />)
