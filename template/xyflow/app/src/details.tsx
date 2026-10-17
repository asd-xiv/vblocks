import { diagramEdges, diagramNodes } from "./diagram"

const findLabel = (nodeId: string) =>
  diagramNodes.find(node => node.id === nodeId)?.data.label ?? nodeId

type LabelListProps = {
  title: string
  labels: string[]
}

const LabelList = ({ title, labels }: LabelListProps) => (
  <div className="mt-4">
    <h3 className="text-xs font-semibold tracking-wide text-stone-500 uppercase">
      {title}
    </h3>
    <ul className="mt-1 font-mono text-sm">
      {labels.length === 0 ? (
        <li className="text-stone-400">none</li>
      ) : (
        labels.map(label => <li key={label}>{label}</li>)
      )}
    </ul>
  </div>
)

type DetailsProps = {
  selectedId: string
}

/**
 * The selected step, with the steps it reads from and writes to, or the
 * selected edge
 */
const Details = ({ selectedId }: DetailsProps) => {
  const node = diagramNodes.find(item => item.id === selectedId)

  if (node) {
    return (
      <section>
        <h2 className="font-mono text-sm font-semibold">{node.data.label}</h2>
        <p className="mt-1 text-sm text-stone-600">{node.data.detail}</p>
        <LabelList
          title="In"
          labels={diagramEdges
            .filter(edge => edge.target === node.id)
            .map(edge => findLabel(edge.source))}
        />
        <LabelList
          title="Out"
          labels={diagramEdges
            .filter(edge => edge.source === node.id)
            .map(edge => findLabel(edge.target))}
        />
      </section>
    )
  }

  const edge = diagramEdges.find(item => item.id === selectedId)

  return (
    <section>
      <h2 className="font-mono text-sm font-semibold">
        {edge
          ? `${findLabel(edge.source)} → ${findLabel(edge.target)}`
          : selectedId}
      </h2>
      <p className="mt-1 text-sm text-stone-600">
        {edge ? "The output of one step, read by the next" : "A new edge"}
      </p>
    </section>
  )
}

export { Details }
