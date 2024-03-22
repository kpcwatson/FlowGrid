//
//  FlowGrid.swift
//
//  Created by Kyle Watson on 3/21/24.
//
//  Inspired by https://github.com/minacod/SwiftUILayoutTutorial

import SwiftUI

struct FlowGrid {
    struct Container {
        static let defaultContainer = Container(width: 0, spacing: 0)

        let width: Double
        let spacing: Double
        private(set) var rows = [Row]()

        var totalHeightSpacing: Double { spacing * Double(rows.count - 1) }
        var height: Double {
            totalHeightSpacing + rows.reduce(0.0) { $0 + $1.size.height }
        }
        var size: CGSize { CGSize(width: width, height: height) }

        mutating func add(_ row: Row) {
            rows.append(row)
        }

        struct Row {
            let spacing: Double
            private(set) var sizes = [CGSize]()

            var isEmpty: Bool { sizes.isEmpty }
            var isNotEmpty: Bool { !isEmpty }
            var totalWidthSpacing: Double { spacing * Double(sizes.count - 1) }
            var size: CGSize {
                sizes.reduce(CGSize(width: totalWidthSpacing, height: 0)) { result, size in
                    CGSize(
                        width: result.width + size.width,
                        height: max(result.height, size.height)
                    )
                }
            }

            mutating func add(_ size: CGSize) {
                sizes.append(size)
            }
        }
    }

    let spacing: Double
    let alignment: HorizontalAlignment

    init(
        spacing: Double = 10,
        alignment: HorizontalAlignment = .center
    ) {
        self.spacing = spacing
        self.alignment = alignment
    }
}

// MARK: - Layout conformance
extension FlowGrid: Layout {

    func makeCache(
        subviews: Subviews
    ) -> Container {
        // can't calculate container sizes without ProposedViewSizes
        // since the proposals wrap text correctly and subview.sizeThatFits
        // without proposal (using .infinity, .zero, .unspecified)
        // does not wrap
        return Container.defaultContainer
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache container: inout Container
    ) -> CGSize {

        guard !subviews.isEmpty,
              let proposedWidth = proposal.width
        else { return .zero }

        container = buildContainer(
            width: proposedWidth,
            proposal: proposal,
            subviews: subviews
        )

        let size = container.size
        return size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache container: inout Container
    ) {

        guard !subviews.isEmpty else { return }

        var point = bounds.origin
        var index = 0
        for row in container.rows {
            point.x = initialHorizontalPosition(
                of: row,
                in: bounds
            )

            for size in row.sizes {
                let subview = subviews[index]
                let sizeProposal = ProposedViewSize(size)
                subview.place(at: point, proposal: sizeProposal)

                point.x += (size.width + spacing)
                index += 1
            }

            point.y += (row.size.height + spacing)
        }
    }
}

// MARK: - private methods
extension FlowGrid {

    private func buildContainer(
        width: Double,
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> Container {

        var rowWidth = 0.0 // TODO: spacing?
        var container = Container(width: width, spacing: spacing)
        var currentRow = Container.Row(spacing: spacing)

        for subview in subviews {

            let subviewSize = subview.sizeThatFits(proposal)
            rowWidth += subviewSize.width + spacing

            if rowWidth < container.width {
                // this subview fits in current row, add subview to row

                currentRow.add(subviewSize)
            } else {
                // this subview does not fit in current row
                // create next row and add subview to that row
                container.add(currentRow)

                currentRow = Container.Row(spacing: spacing)
                currentRow.add(subviewSize)

                rowWidth = subviewSize.width + spacing
            }
        }

        if currentRow.isNotEmpty {
            container.add(currentRow)
        }

        return container
    }

    private func initialHorizontalPosition(
        of row: Container.Row,
        in containerBounds: CGRect
    ) -> Double {
        switch alignment {
        case .trailing, .listRowSeparatorTrailing:
            (containerBounds.maxX - row.size.width)
        case .center:
            (containerBounds.minX + containerBounds.maxX - row.size.width) / 2.0
        case .leading, .listRowSeparatorLeading:
            containerBounds.minX
        default:
            containerBounds.minX
        }
    }
}
