import type { Node } from "@xyflow/react"

/**
 * The side of one grid cell, in pixels. `<Background>` draws a dot per cell,
 * and a dragged node snaps to the dots
 */
const CELL_SIZE = 20

/**
 * A node with its `position` and `size` in cells. Give each side an even number
 * of cells, so the handle in its middle sits on a dot
 */
type CellNode<T extends Node> = T & {
  size: { width: number; height: number }
}

/**
 * Convert the position and the size of each node from cells to pixels
 *
 * @example
 * toPixels<StepNode>([
 *   {
 *     id: "swc",
 *     type: "step",
 *     position: { x: 0, y: 7 },
 *     size: { width: 12, height: 4 },
 *     data: { label: "SWC", detail: "Compiles TypeScript and JSX" },
 *   },
 * ])
 * // => [{ id: "swc", position: { x: 0, y: 140 }, width: 240, height: 80, … }]
 */
const toPixels = <T extends Node>(nodes: CellNode<T>[]): T[] =>
  nodes.map(node => ({
    ...node,
    position: {
      x: node.position.x * CELL_SIZE,
      y: node.position.y * CELL_SIZE,
    },
    width: node.size.width * CELL_SIZE,
    height: node.size.height * CELL_SIZE,
  }))

export { CELL_SIZE, toPixels }
export type { CellNode }
