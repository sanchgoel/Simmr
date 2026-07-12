//
//  QuantityFormatter.swift
//  Simmr
//
//  Formats scaled ingredient quantities as friendly fractions instead of
//  raw decimals (e.g. "1½" rather than "1.5", "2.3333333333333335").
//

import Foundation

enum QuantityFormatter {
    static func format(_ value: Double) -> String {
        guard value > 0 else { return "0" }

        let nearestQuarter = (value * 4).rounded() / 4
        let whole = Int(nearestQuarter)
        let fraction = nearestQuarter - Double(whole)

        let fractionSymbol: String
        switch fraction {
        case 0.25: fractionSymbol = "¼"
        case 0.5: fractionSymbol = "½"
        case 0.75: fractionSymbol = "¾"
        default: fractionSymbol = ""
        }

        if fractionSymbol.isEmpty {
            return whole == 0 ? trimmedDecimal(nearestQuarter) : "\(whole)"
        }
        return whole == 0 ? fractionSymbol : "\(whole)\(fractionSymbol)"
    }

    private static func trimmedDecimal(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
