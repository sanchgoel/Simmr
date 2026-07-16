//
//  UnitConverter.swift
//  Simmr
//
//  Kitchen unit conversions for the Cooking Mode conversion helper. Volume
//  and weight each convert exactly through a common base unit. Weight <->
//  volume also works, approximated via IngredientDensity, for people
//  without a scale who only have measuring spoons/cups on hand.
//

import Foundation

enum ConversionCategory: String, CaseIterable, Identifiable {
    case volume = "Volume"
    case weight = "Weight"

    var id: String { rawValue }
}

enum VolumeUnit: String, CaseIterable, Identifiable {
    case milliliter = "ml"
    case liter = "L"
    case teaspoon = "tsp"
    case tablespoon = "tbsp"
    case fluidOunce = "fl oz"
    case cup = "cup"
    case pint = "pt"
    case quart = "qt"
    case gallon = "gal"

    var id: String { rawValue }

    /// Conversion factor to milliliters, the base unit for this category.
    var perMilliliter: Double {
        switch self {
        case .milliliter: return 1
        case .liter: return 1000
        case .teaspoon: return 4.92892
        case .tablespoon: return 14.7868
        case .fluidOunce: return 29.5735
        case .cup: return 236.588
        case .pint: return 473.176
        case .quart: return 946.353
        case .gallon: return 3785.41
        }
    }

    func convert(_ value: Double, to unit: VolumeUnit) -> Double {
        (value * perMilliliter) / unit.perMilliliter
    }

    /// Matches common free-text ingredient unit strings (as written by the
    /// recipe parser) to a VolumeUnit, or nil if it isn't a volume unit.
    init?(matching text: String) {
        switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "ml", "mls", "milliliter", "milliliters", "millilitre", "millilitres": self = .milliliter
        case "l", "ltr", "ltrs", "liter", "liters", "litre", "litres": self = .liter
        case "tsp", "tsps", "tspn", "teaspoon", "teaspoons": self = .teaspoon
        case "tbsp", "tbsps", "tbs", "tblsp", "tablespoon", "tablespoons": self = .tablespoon
        case "fl oz", "fluid ounce", "fluid ounces": self = .fluidOunce
        case "cup", "cups": self = .cup
        case "pt", "pint", "pints": self = .pint
        case "qt", "quart", "quarts": self = .quart
        case "gal", "gallon", "gallons": self = .gallon
        default: return nil
        }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case gram = "g"
    case kilogram = "kg"
    case ounce = "oz"
    case pound = "lb"

    var id: String { rawValue }

    /// Conversion factor to grams, the base unit for this category.
    var perGram: Double {
        switch self {
        case .gram: return 1
        case .kilogram: return 1000
        case .ounce: return 28.3495
        case .pound: return 453.592
        }
    }

    func convert(_ value: Double, to unit: WeightUnit) -> Double {
        (value * perGram) / unit.perGram
    }

    /// Matches common free-text ingredient unit strings (as written by the
    /// recipe parser) to a WeightUnit, or nil if it isn't a weight unit.
    init?(matching text: String) {
        switch text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "g", "gm", "gms", "gram", "grams": self = .gram
        case "kg", "kgs", "kilo", "kilos", "kilogram", "kilograms": self = .kilogram
        case "oz", "ounce", "ounces": self = .ounce
        case "lb", "lbs", "pound", "pounds": self = .pound
        default: return nil
        }
    }
}

/// Approximate ingredient densities, so a weight measurement (e.g. "300g
/// rice") can be converted to a volume someone can measure with spoons or a
/// cup when they don't have a scale — and vice versa. Matched by keyword
/// against the ingredient's name; falls back to a water-like density for
/// anything unrecognized, since that's a reasonable neutral default.
enum IngredientDensity {
    private static let gramsPerCupByKeyword: [(keywords: [String], gramsPerCup: Double)] = [
        (["powdered sugar", "icing sugar", "confectioners"], 120),
        (["brown sugar"], 220),
        (["sugar"], 200),
        (["flour", "maida"], 120),
        (["cornstarch", "corn flour", "cornflour"], 128),
        (["rice"], 185),
        (["lentil", "dal", "bean", "chickpea"], 200),
        (["oats"], 90),
        (["butter", "ghee"], 227),
        (["oil"], 218),
        (["honey", "syrup", "molasses"], 340),
        (["milk", "buttermilk"], 245),
        (["cream", "yogurt", "curd"], 245),
        (["water", "stock", "broth", "juice"], 236),
        (["salt"], 273),
        (["cocoa", "cacao"], 100),
        (["bread crumbs", "breadcrumbs"], 108),
        (["cheese", "parmesan", "cheddar"], 100),
        (["nuts", "almond", "cashew", "walnut", "peanut"], 120),
    ]

    static func gramsPerCup(for ingredientName: String) -> Double {
        let normalized = ingredientName.lowercased()
        for entry in gramsPerCupByKeyword where entry.keywords.contains(where: { normalized.contains($0) }) {
            return entry.gramsPerCup
        }
        return 236 // water-like default
    }

    /// Approximate volume, in milliliters, for a weight of the given ingredient.
    static func milliliters(fromGrams grams: Double, ingredientName: String) -> Double {
        let cups = grams / gramsPerCup(for: ingredientName)
        return cups * VolumeUnit.cup.perMilliliter
    }

    /// Approximate weight, in grams, for a volume of the given ingredient.
    static func grams(fromMilliliters milliliters: Double, ingredientName: String) -> Double {
        let cups = milliliters / VolumeUnit.cup.perMilliliter
        return cups * gramsPerCup(for: ingredientName)
    }
}
