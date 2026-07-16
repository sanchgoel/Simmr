//
//  FlowLayout.swift
//  Simmr
//
//  Wraps subviews onto multiple lines (like text wrapping) instead of
//  clipping or requiring horizontal scrolling — used for ingredient chips.
//
//  Rows are packed with a gap-filling first-fit: if the next item in order
//  doesn't fit the current row, later (typically smaller) items are tried
//  instead of immediately wrapping, so a row only ends once nothing left
//  fits it. This trades strict left-to-right order for noticeably less
//  wasted trailing space per row, which is fine for chip collections where
//  order isn't meaningfully sequential.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let rows = packedRows(sizes: sizes, maxWidth: proposal.width ?? .infinity)

        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            let rowWidth = row.reduce(into: CGFloat(0)) { $0 += sizes[$1].width + spacing } - spacing
            totalHeight += rowHeight + spacing
            maxRowWidth = max(maxRowWidth, rowWidth)
        }
        if totalHeight > 0 { totalHeight -= spacing }

        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let rows = packedRows(sizes: sizes, maxWidth: bounds.width)

        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            for index in row {
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sizes[index]))
                x += sizes[index].width + spacing
            }
            y += rowHeight + spacing
        }
    }

    /// Greedily fills each row: walks the not-yet-placed items in their
    /// original order and adds every one that still fits, rather than
    /// stopping at the first one that doesn't. A row always gets at least
    /// one item (even if it's wider than the available space) so layout
    /// can't get stuck.
    private func packedRows(sizes: [CGSize], maxWidth: CGFloat) -> [[Int]] {
        guard maxWidth.isFinite else {
            return [Array(sizes.indices)]
        }

        var remaining = Array(sizes.indices)
        var rows: [[Int]] = []

        while !remaining.isEmpty {
            var row: [Int] = []
            var rowWidth: CGFloat = 0

            remaining.removeAll { index in
                let itemWidth = sizes[index].width
                let neededWidth = row.isEmpty ? itemWidth : rowWidth + spacing + itemWidth
                guard neededWidth <= maxWidth || row.isEmpty else { return false }
                row.append(index)
                rowWidth = neededWidth
                return true
            }

            rows.append(row)
        }

        return rows
    }
}
