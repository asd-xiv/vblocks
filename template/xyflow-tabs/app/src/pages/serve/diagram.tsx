import { useCallback } from "react"
import {
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
  type OnSelectionChangeFunc,
} from "@xyflow/react"

import { CELL_SIZE, toPixels } from "@self/utils/grid"

import { ZoomLevel } from "@self/ui/zoom-level"

type PhaseNode = Node<
  { label: string; detail: string; delay?: string },
  "phase"
>

type PhaseEdge = Edge<{ detail: string }>

/**
 * The loop. Edit these two lists, this specimen draws the VBlocks serve. A
 * node has a handle on each side, an edge names the two it joins, eg.
 * `right-source` to `left-target`
 */
const serveNodes = toPixels<PhaseNode>([
  {
    id: "save",
    type: "phase",
    position: { x: 0, y: 0 },
    size: { width: 12, height: 4 },
    data: { label: "You", detail: "Save a file in src/" },
  },
  {
    id: "watcher",
    type: "phase",
    position: { x: 18, y: 0 },
    size: { width: 12, height: 4 },
    data: {
      label: "Watcher",
      detail: "Waits for more saves, eg. of a codemod, then starts one compile",
      delay: "100 ms",
    },
  },
  {
    id: "compile",
    type: "phase",
    position: { x: 18, y: 10 },
    size: { width: 12, height: 4 },
    data: { label: "Webpack", detail: "Compiles the modules the saves touched" },
  },
  {
    id: "browser",
    type: "phase",
    position: { x: 0, y: 10 },
    size: { width: 12, height: 4 },
    data: {
      label: "Browser",
      detail:
        "Hot Module Replacement swaps the modules, React Refresh keeps the state of each component",
    },
  },
])

const serveEdges: PhaseEdge[] = [
  {
    id: "save-watcher",
    source: "save",
    sourceHandle: "right-source",
    target: "watcher",
    targetHandle: "left-target",
    label: "save",
    animated: true,
    data: { detail: "Your editor writes the file to disk" },
  },
  {
    id: "watcher-compile",
    source: "watcher",
    sourceHandle: "bottom-source",
    target: "compile",
    targetHandle: "top-target",
    label: "changed files",
    animated: true,
    data: { detail: "The files of the last compile that changed or went away" },
  },
  {
    id: "compile-browser",
    source: "compile",
    sourceHandle: "left-source",
    target: "browser",
    targetHandle: "right-target",
    label: "hot update",
    animated: true,
    data: { detail: "The development server sends the new modules over a WebSocket" },
  },
  {
    id: "browser-save",
    source: "browser",
    sourceHandle: "top-source",
    target: "save",
    targetHandle: "bottom-target",
    label: "you see the change",
    animated: true,
    data: { detail: "The page updates without a reload" },
  },
]

const SIDES = [Position.Top, Position.Right, Position.Bottom, Position.Left]

const Phase = ({ data, selected }: NodeProps<PhaseNode>) => (
  <div
    className={`flex h-full w-full flex-col justify-center rounded-full border bg-white px-5 text-center shadow-sm ${selected ? "border-stone-900" : "border-stone-300"}`}>
    {SIDES.map(side => (
      <span key={side}>
        <Handle type="source" position={side} id={`${side}-source`} />
        <Handle type="target" position={side} id={`${side}-target`} />
      </span>
    ))}
    <div className="text-sm font-semibold text-stone-900">{data.label}</div>
    {data.delay && <div className="text-xs text-stone-500">{data.delay}</div>}
  </div>
)

const nodeTypes: NodeTypes = { phase: Phase }

type ServeDiagramProps = {
  onSelect: (entityId: string | undefined) => void
}

const ServeDiagram = ({ onSelect }: ServeDiagramProps) => {
  const [nodes, , onNodesChange] = useNodesState(serveNodes)
  const [edges, , onEdgesChange] = useEdgesState(serveEdges)

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

export { ServeDiagram, serveEdges, serveNodes }
