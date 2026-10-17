import { serveEdges, serveNodes } from "./diagram"

type ServeDetailsProps = {
  selectedId: string
}

/**
 * The selected phase of the loop, with how long it waits, or the selected
 * hand-off between two phases
 */
const ServeDetails = ({ selectedId }: ServeDetailsProps) => {
  const node = serveNodes.find(item => item.id === selectedId)
  const edge = serveEdges.find(item => item.id === selectedId)

  return (
    <section>
      <h2 className="text-sm font-semibold">
        {node?.data.label ?? edge?.label ?? selectedId}
      </h2>
      <p className="mt-1 text-sm text-stone-600">
        {node?.data.detail ?? edge?.data?.detail}
      </p>
      {node?.data.delay && (
        <p className="mt-4 text-sm">
          <span className="text-stone-500">Waits </span>
          <span className="font-mono">{node.data.delay}</span>
        </p>
      )}
    </section>
  )
}

export { ServeDetails }
