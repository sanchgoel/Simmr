//
//  UnitConverterView.swift
//  Simmr
//
//  Kitchen conversion helper shown as a drawer from Cooking Mode. Lets the
//  user pick any convertible ingredient from the current step (or switch
//  between them) and shows the single most practical kitchen tool —
//  teaspoon, tablespoon, or cup — for that quantity, rather than dumping
//  every unit and making the user guess. Falls back to a plain same-unit
//  reference table when the step has no convertible ingredients.
//

import SwiftUI

struct UnitConverterView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    let options: [ConvertibleIngredientOption]
    @State private var selectedOptionID: ConvertibleIngredientOption.ID?

    @State private var category: ConversionCategory
    @State private var inputText: String
    /// Full-precision shadow of `inputText`, in whatever unit is currently
    /// selected. Unit/ingredient switches convert from this rather than
    /// re-parsing the (rounded, 2-decimal) display text, so repeated
    /// switches don't drift — e.g. 300g -> lb -> g lands back on exactly
    /// 300, not 299.37.
    @State private var preciseValue: Double
    /// Guards the onChange handlers below while this view applies several
    /// @State changes together (loading a new ingredient, or reformatting
    /// text after a unit switch), so those handlers don't misinterpret our
    /// own updates as user edits and reconvert on top of them.
    @State private var isApplyingProgrammaticUpdate = false
    @State private var volumeUnit: VolumeUnit
    @State private var weightUnit: WeightUnit

    init(options: [ConvertibleIngredientOption], selectedOptionID: ConvertibleIngredientOption.ID? = nil) {
        self.options = options
        let initialOption = options.first { $0.id == selectedOptionID } ?? options.first
        _selectedOptionID = State(initialValue: initialOption?.id)
        _category = State(initialValue: initialOption?.category ?? .volume)
        _preciseValue = State(initialValue: initialOption?.quantity ?? 0)
        _inputText = State(initialValue: initialOption.map { Self.formattedValue($0.quantity) } ?? "")
        _volumeUnit = State(initialValue: initialOption?.volumeUnit ?? .milliliter)
        _weightUnit = State(initialValue: initialOption?.weightUnit ?? .gram)
    }

    private var selectedOption: ConvertibleIngredientOption? {
        options.first { $0.id == selectedOptionID }
    }

    private var ingredientName: String? { selectedOption?.name }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    if options.isEmpty {
                        Picker("Category", selection: $category) {
                            ForEach(ConversionCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if let ingredientName {
                        Text("No scale? Here's the easiest way to measure \(ingredientName).")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.textMuted)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if options.count > 1 {
                        ingredientPicker
                    }

                    inputRow

                    Divider().overlay(Theme.Colors.border)

                    if ingredientName != nil {
                        smartResult
                    } else {
                        VStack(spacing: Theme.Spacing.xs) {
                            ForEach(sameCategoryRows, id: \.label) { row in
                                resultRow(label: row.label, value: row.value)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .navigationTitle("Unit Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onChange(of: inputText) { _, newText in
            guard !isApplyingProgrammaticUpdate else { return }
            preciseValue = Double(newText) ?? preciseValue
        }
        .onChange(of: volumeUnit) { oldUnit, newUnit in
            guard !isApplyingProgrammaticUpdate else { return }
            preciseValue = oldUnit.convert(preciseValue, to: newUnit)
            syncTextFromPreciseValue()
        }
        .onChange(of: weightUnit) { oldUnit, newUnit in
            guard !isApplyingProgrammaticUpdate else { return }
            preciseValue = oldUnit.convert(preciseValue, to: newUnit)
            syncTextFromPreciseValue()
        }
        .onChange(of: selectedOptionID) { _, newID in
            withAnimation(.easeInOut(duration: 0.25)) {
                applyOption(options.first { $0.id == newID })
            }
        }
    }

    /// Updates the displayed text from `preciseValue` (or, when loading a
    /// new option, all the related state at once) without letting the
    /// resulting text/unit changes bounce back through the onChange guards
    /// above and clobber what we just set.
    private func syncTextFromPreciseValue() {
        isApplyingProgrammaticUpdate = true
        inputText = Self.formattedValue(preciseValue)
        DispatchQueue.main.async {
            isApplyingProgrammaticUpdate = false
        }
    }

    private func applyOption(_ option: ConvertibleIngredientOption?) {
        guard let option else { return }
        isApplyingProgrammaticUpdate = true
        category = option.category
        if let volumeUnit = option.volumeUnit { self.volumeUnit = volumeUnit }
        if let weightUnit = option.weightUnit { self.weightUnit = weightUnit }
        preciseValue = option.quantity
        inputText = Self.formattedValue(option.quantity)
        DispatchQueue.main.async {
            isApplyingProgrammaticUpdate = false
        }
    }

    private var ingredientPicker: some View {
        Menu {
            ForEach(options) { option in
                Button(option.name) { selectedOptionID = option.id }
            }
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.xxs) {
                Text(ingredientName ?? "Select ingredient")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.coral)
                    .padding(.top, 3)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
            .background(Theme.Colors.tint)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var inputRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("", text: $inputText, prompt: Text("Value").foregroundStyle(Theme.Colors.textMuted))
                .keyboardType(.decimalPad)
                .focused($isInputFocused)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textDark)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.creamCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(isInputFocused ? Theme.Colors.coral : Theme.Colors.border, lineWidth: Theme.Stroke.regular)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

            fromUnitPicker
        }
    }

    @ViewBuilder
    private var fromUnitPicker: some View {
        switch category {
        case .volume:
            Picker("From", selection: $volumeUnit) {
                ForEach(VolumeUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.Colors.coral)
        case .weight:
            Picker("From", selection: $weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.Colors.coral)
        }
    }

    private var inputValue: Double { Double(inputText) ?? preciseValue }

    /// The input's volume equivalent in milliliters — direct if the input
    /// is already a volume, or via the ingredient's density if it's a
    /// weight. This is what the smart cup/tbsp/tsp suggestion is based on.
    private var millilitersEquivalent: Double {
        switch category {
        case .volume:
            return volumeUnit.convert(inputValue, to: .milliliter)
        case .weight:
            guard let ingredientName else { return 0 }
            let grams = weightUnit.convert(inputValue, to: .gram)
            return IngredientDensity.milliliters(fromGrams: grams, ingredientName: ingredientName)
        }
    }

    /// The input's weight equivalent in grams — direct if the input is
    /// already a weight, or via the ingredient's density if it's a volume.
    private var gramsEquivalent: Double {
        switch category {
        case .weight:
            return weightUnit.convert(inputValue, to: .gram)
        case .volume:
            guard let ingredientName else { return 0 }
            let milliliters = volumeUnit.convert(inputValue, to: .milliliter)
            return IngredientDensity.grams(fromMilliliters: milliliters, ingredientName: ingredientName)
        }
    }

    private var smartResult: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("≈ \(Self.smartVolumeLabel(forMilliliters: millilitersEquivalent))")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.coral)
                Text("using a standard cup, tablespoon, or teaspoon")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.tint)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))

            resultRow(label: "Weight", value: "\(Self.formattedValue(gramsEquivalent)) g")
            resultRow(label: "Volume", value: "\(Self.formattedValue(millilitersEquivalent)) ml")
        }
    }

    /// Picks whichever of teaspoon, tablespoon, or cup reads most naturally
    /// for the given volume, formatted as a friendly fraction (matching how
    /// ingredient quantities are shown elsewhere in the app) instead of a
    /// raw decimal — e.g. "1½ cups" rather than "1.62 cup, 25.9 tbsp, ...".
    private static func smartVolumeLabel(forMilliliters milliliters: Double) -> String {
        guard milliliters > 0 else { return "0" }

        let cups = VolumeUnit.milliliter.convert(milliliters, to: .cup)
        if cups >= 0.25 {
            let formatted = QuantityFormatter.format(cups)
            return "\(formatted) \(cups > 1.001 ? "cups" : "cup")"
        }

        let tablespoons = VolumeUnit.milliliter.convert(milliliters, to: .tablespoon)
        if tablespoons >= 1 {
            return "\(QuantityFormatter.format(tablespoons)) tbsp"
        }

        let teaspoons = VolumeUnit.milliliter.convert(milliliters, to: .teaspoon)
        return "\(QuantityFormatter.format(teaspoons)) tsp"
    }

    private var sameCategoryRows: [(label: String, value: String)] {
        switch category {
        case .volume:
            return VolumeUnit.allCases
                .filter { $0 != volumeUnit }
                .map { unit in (unit.rawValue, Self.formattedValue(volumeUnit.convert(inputValue, to: unit))) }
        case .weight:
            return WeightUnit.allCases
                .filter { $0 != weightUnit }
                .map { unit in (unit.rawValue, Self.formattedValue(weightUnit.convert(inputValue, to: unit))) }
        }
    }

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textMuted)
            Spacer()
            Text(value)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textDark)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    private static func formattedValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UnitConverterView(options: [
                ConvertibleIngredientOption(name: "rice", category: .weight, quantity: 300, volumeUnit: nil, weightUnit: .gram),
                ConvertibleIngredientOption(name: "water", category: .volume, quantity: 500, volumeUnit: .milliliter, weightUnit: nil),
            ])
        }
}
