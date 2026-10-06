import SwiftUI

private let filledFromID = Palette.green.opacity(0.55)

// MARK: - Step 1: Personal (S02)

struct SpousePersonalStep: View {
    @Bindable var model: SpouseFlowModel

    private func border(_ value: String) -> Color? {
        model.fromId && !value.isEmpty ? filledFromID : nil
    }

    var body: some View {
        if model.fromId {
            HStack(spacing: 10) {
                IconView(.check, size: 18).foregroundStyle(Palette.acceptedText)
                Text("Filled from their ID — please double-check.").font(Typo.manrope(13)).foregroundStyle(Color(hex: 0xBFEBD3))
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.green.opacity(0.14)))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.green.opacity(0.35), lineWidth: 1))
            .padding(.bottom, 18)
            .rise()
        }
        Text("Who is your spouse?").h1(26).rise(1)
        Text("Use their name exactly as it appears on their ID.").mutedBody(14).padding(.top, 6).rise(1)

        VStack(alignment: .leading, spacing: 14) {
            TahananTextField(label: "First name", placeholder: "Jose", text: $model.first, contentType: .givenName,
                             borderOverride: border(model.first), capitalization: .words)
            HStack(alignment: .top, spacing: 10) {
                TahananTextField(label: "Middle name", placeholder: "Reyes", text: $model.middle, contentType: .middleName,
                                 borderOverride: border(model.middle), capitalization: .words)
                    .disabled(model.noMiddleName)
                    .opacity(model.noMiddleName ? 0.5 : 1)
                TahananTextField(label: "Suffix", placeholder: "Jr.", text: $model.suffix, contentType: .nameSuffix, capitalization: .words)
                    .frame(width: 96)
            }
            CheckboxRow(isOn: Binding(get: { model.noMiddleName }, set: { model.noMiddleName = $0; if $0 { model.middle = "" } }), size: 20) {
                Text("No middle name").font(Typo.manrope(13)).foregroundStyle(Palette.muted)
            }
            .padding(.top, -4)
            TahananTextField(label: "Last name", placeholder: "Santos", text: $model.last, contentType: .familyName,
                             borderOverride: border(model.last), capitalization: .words)
            BirthdateField(date: $model.birthdate, border: model.fromId && model.birthdate != nil ? filledFromID : nil)

            VStack(alignment: .leading, spacing: 8) {
                Text("Sex").fieldLabel()
                HStack(spacing: 8) {
                    ForEach(["Male", "Female"], id: \.self) { s in
                        FilterChip(title: s, selected: model.sex == s, height: 52, radius: 16) { model.sex = s }
                    }
                }
            }
            TahananTextField(label: "Citizenship", placeholder: "Filipino", text: $model.citizenship, capitalization: .words)

            VStack(alignment: .leading, spacing: 8) {
                PhoneField(label: "Mobile number", text: Binding(get: { model.mobile }, set: { model.mobile = $0; model.touched = true }),
                           borderOverride: model.mobileError ? Palette.orange : nil)
                if model.mobileError {
                    HStack(spacing: 6) {
                        IconView(.info, size: 14)
                        Text("Enter 10 digits, starting with 9").font(Typo.manrope(12, .bold))
                    }
                    .foregroundStyle(Palette.todoText)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: model.mobileError)

            TahananTextField(label: "Email", placeholder: "name@email.com", text: $model.email, keyboard: .emailAddress,
                             contentType: .emailAddress, labelSuffix: "(optional)")
        }
        .padding(.top, 20)
        .rise(2)
    }
}

/// Date input styled as `.field`; the native compact date picker sits invisibly on top to handle taps.
struct BirthdateField: View {
    @Binding var date: Date?
    var border: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Birthdate").fieldLabel()
            ZStack {
                HStack {
                    Text(date.map(Self.format) ?? "mm/dd/yyyy")
                        .font(Typo.manrope(16))
                        .foregroundStyle(date == nil ? Palette.placeholder : Palette.text)
                    Spacer()
                    IconView(.calendar, size: 18).foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 16)
                .modifier(FieldChrome(focused: false, borderOverride: border))
                .allowsHitTesting(false)

                DatePicker("Birthdate", selection: Binding(get: { date ?? Self.defaultDate }, set: { date = $0 }),
                           in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Palette.yellow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(x: 3, y: 1.4)
                    .opacity(0.02)
                    .clipped()
            }
            .frame(height: 56)
        }
    }

    private static let defaultDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()

    static func format(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        return f.string(from: d)
    }
}

// MARK: - Step 2: Address & ID (S03)

struct SpouseAddressStep: View {
    @Bindable var model: SpouseFlowModel
    let address: String

    var body: some View {
        Text("Address and ID").h1(26).rise()

        HStack(spacing: 14) {
            IconTile(icon: .home, tint: Palette.yellow, background: Palette.yellow.opacity(0.16))
            VStack(alignment: .leading, spacing: 2) {
                Text("Lives with me").font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text)
                Text("Use my current address").font(Typo.manrope(12)).foregroundStyle(Palette.subtle)
            }
            Spacer()
            TahananToggle(isOn: $model.sameAddress, label: "Same address as mine")
        }
        .padding(16)
        .glass(22)
        .padding(.top, 18)
        .rise(1)

        Group {
            if model.sameAddress {
                HStack(alignment: .top, spacing: 10) {
                    IconView(.pin, size: 18).foregroundStyle(Palette.subtle)
                    Text(address).font(Typo.manrope(14)).foregroundStyle(Palette.soft).lineSpacing(6)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14).padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white(0.14), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                .padding(.top, 10)
            } else {
                VStack(spacing: 14) {
                    TahananTextField(label: "House no., street", placeholder: "Blk 4 Lot 12, Sampaguita St.", text: $model.street, contentType: .streetAddressLine1)
                    HStack(spacing: 10) {
                        TahananTextField(label: "Barangay", placeholder: "San Juan I", text: $model.barangay)
                        TahananTextField(label: "City", placeholder: "Ternate", text: $model.city, contentType: .addressCity)
                    }
                    HStack(spacing: 10) {
                        TahananTextField(label: "Province", placeholder: "Cavite", text: $model.province, contentType: .addressState)
                        TahananTextField(label: "ZIP", placeholder: "4111", text: $model.zip, keyboard: .numberPad, contentType: .postalCode, mono: true)
                            .frame(width: 110)
                    }
                }
                .padding(.top, 16)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: model.sameAddress)

        Text("Valid ID").sectionTitle(17).padding(.top, 26).rise(2)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpouseFlowModel.idTypes) { t in
                    FilterChip(title: t.label, selected: model.idType == t.id) { model.idType = t.id }
                }
            }
        }
        .contentMargins(.horizontal, Spacing.gutter, for: .scrollContent)
        .padding(.horizontal, -Spacing.gutter)
        .padding(.top, 12)
        .rise(2)

        VStack(alignment: .leading, spacing: 14) {
            TahananTextField(label: "\(model.idTypeInfo.label) number", placeholder: model.idTypeInfo.placeholder, text: $model.idNumber, mono: true,
                             borderOverride: model.fromId && !model.idNumber.isEmpty ? filledFromID : (model.touched && model.idNumber.isEmpty ? Palette.orange : nil),
                             capitalization: .characters)
            VStack(alignment: .leading, spacing: 8) {
                TahananTextField(label: "TIN", placeholder: "000-000-000-000", text: $model.tin, keyboard: .numbersAndPunctuation, mono: true)
                Text("No TIN yet? You can add it later — it’s needed before loan approval.").font(Typo.manrope(12)).foregroundStyle(Palette.subtle)
            }
        }
        .padding(.top, 14)
        .rise(3)
    }
}

// MARK: - Step 3: Work & income (S04)

struct SpouseWorkStep: View {
    @Bindable var model: SpouseFlowModel

    var body: some View {
        Text("Work and income").h1(26).rise()
        Text("This helps us size your loan. Only Homeful processors see it.").mutedBody(14).padding(.top, 6).rise()

        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(SpouseFlowModel.employment) { o in
                let on = model.employmentType == o.id
                Button { withAnimation(.easeInOut(duration: 0.25)) { model.employmentType = o.id } } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(o.label).font(Typo.manrope(14, .extrabold)).foregroundStyle(on ? Palette.yellow : Palette.text)
                        Text(o.sub).font(Typo.manrope(11)).foregroundStyle(Palette.subtle)
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 72)
                    .background(RoundedRectangle(cornerRadius: 18).fill(on ? Palette.yellow.opacity(0.1) : .white(0.04)))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(on ? Palette.yellow : .white(0.12), lineWidth: 1.5))
                }
                .pressable()
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
        .padding(.top, 18)
        .rise(1)

        Group {
            if model.employmentType != "none" {
                VStack(alignment: .leading, spacing: 14) {
                    TahananTextField(label: model.employerLabel, placeholder: model.employmentType == "self" ? "e.g. Santos Sari-sari Store" : "Company name",
                                     text: $model.employer, contentType: .organizationName, capitalization: .words)
                    TahananTextField(label: "Position", placeholder: "e.g. Staff nurse", text: $model.position, contentType: .jobTitle, capitalization: .words)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Years in this work").fieldLabel()
                        HStack {
                            stepperButton("−", label: "Fewer years") { model.years = max(0, model.years - 1) }
                            Spacer()
                            Text("\(model.years) \(model.years == 1 ? "year" : "years")").font(Typo.outfit(20, .semibold)).foregroundStyle(Palette.text)
                            Spacer()
                            stepperButton(nil, label: "More years") { model.years = min(40, model.years + 1) }
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 56)
                        .glass(16)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gross monthly income").fieldLabel()
                        HStack(spacing: 0) {
                            Text("₱").font(Typo.outfit(18, .semibold)).foregroundStyle(Palette.yellow).padding(.leading, 16)
                            TextField("", text: Binding(get: { model.incomeDisplay }, set: { model.incomeDigits = String($0.filter(\.isNumber).prefix(9)) }),
                                      prompt: Text("0").foregroundStyle(Palette.placeholder))
                                .keyboardType(.numberPad)
                                .font(Typo.outfit(20, .semibold))
                                .foregroundStyle(Palette.text)
                                .tint(Palette.yellow)
                                .padding(.leading, 8)
                                .padding(.trailing, 16)
                        }
                        .modifier(FieldChrome(focused: false, borderOverride: model.touched && model.incomeDigits.isEmpty ? Palette.orange : nil))
                    }
                }
                .padding(.top, 18)
            } else {
                Text("No problem — we’ll use your income only. You can update this anytime.")
                    .font(Typo.manrope(14)).foregroundStyle(Palette.soft).lineSpacing(6)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white(0.04)))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white(0.14), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                    .padding(.top, 18)
            }
        }
        .transition(.opacity)

        HouseholdIncomeCard(model: model).padding(.top, 20).rise(3)
    }

    private func stepperButton(_ text: String?, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let text { Text(text).font(Typo.manrope(20, .bold)) } else { IconView(.plus) }
            }
            .foregroundStyle(Palette.text)
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.white(0.07)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Live household income bar against the required GMI.
struct HouseholdIncomeCard: View {
    let model: SpouseFlowModel

    var body: some View {
        let scale = model.scale
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("HOUSEHOLD INCOME").font(Typo.manrope(12, .extrabold)).tracking(0.96)
                Spacer()
                Text(SpouseFlowModel.peso(model.total)).font(Typo.outfit(24, .bold))
            }
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.ink.opacity(0.14))
                    HStack(spacing: 0) {
                        CornerBox(7, 0, 0, 7).fill(Palette.ink).frame(width: w * Double(model.mine) / scale)
                        StripesFill().clipShape(CornerBox(0, 7, 7, 0)).frame(width: w * Double(model.spouseIncome) / scale)
                    }
                    Rectangle().fill(Palette.orange).frame(width: 2, height: 26)
                        .offset(x: w * Double(model.required) / scale)
                }
                .animation(Motion.standard(0.6), value: model.spouseIncome)
            }
            .frame(height: 14)
            .padding(.top, 14)

            FlowLayout(spacing: 14, lineSpacing: 6) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3).fill(Palette.ink).frame(width: 10, height: 10)
                    Text("You \(SpouseFlowModel.peso(model.mine))")
                }
                HStack(spacing: 6) {
                    StripesFill().frame(width: 10, height: 10).clipShape(RoundedRectangle(cornerRadius: 3))
                    Text("Spouse \(SpouseFlowModel.peso(model.spouseIncome))")
                }
                HStack(spacing: 6) {
                    Rectangle().fill(Palette.orange).frame(width: 10, height: 2)
                    Text("Required \(SpouseFlowModel.peso(model.required))")
                }
            }
            .font(Typo.manrope(12, .bold))
            .padding(.top, 12)

            Text(model.gmiMessage).font(Typo.manrope(13, .extrabold)).padding(.top, 12)
        }
        .foregroundStyle(Palette.ink)
        .padding(18)
        .background(
            ZStack(alignment: .topTrailing) {
                Palette.yellow
                ArchShape(bottomRadius: 0).fill(Color.white(0.22)).frame(width: 150, height: 180).offset(x: 40, y: -60)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Step 4: Review (S05)

struct SpouseReviewStep: View {
    @Bindable var model: SpouseFlowModel
    let edit: (Int) -> Void

    var body: some View {
        Text("Review and confirm").h1(26).rise()
        Text("Tap Edit to fix anything.").mutedBody(14).padding(.top, 6).rise()

        VStack(spacing: 10) {
            card("Personal", step: 0, rows: [
                ("Name", model.fullName.isEmpty ? "—" : model.fullName),
                ("Birthdate", model.birthdateText),
                ("Sex", model.sex),
                ("Mobile", model.mobile.isEmpty ? "—" : "+63 \(model.mobile)"),
            ])
            card("Address & ID", step: 1, rows: [
                ("Address", model.sameAddress ? "Same as mine" : "Separate address"),
                (model.idTypeInfo.label, model.idNumber.isEmpty ? "—" : model.idNumber),
                ("TIN", model.tin.isEmpty ? "Add later" : model.tin),
            ])
            card("Work & income", step: 2, rows: model.employmentType == "none"
                ? [("Status", "Not working")]
                : [
                    ("Status", SpouseFlowModel.employment.first { $0.id == model.employmentType }?.label ?? ""),
                    (model.employerLabel, model.employer.isEmpty ? "—" : model.employer),
                    ("Monthly income", SpouseFlowModel.peso(model.spouseIncome)),
                ])
        }
        .padding(.top, 18)
        .rise(1)

        CheckboxRow(isOn: $model.consent) {
            Text("My spouse agreed to share this information with Homeful for our home loan, under the Data Privacy Act of 2012.")
                .font(Typo.manrope(13)).foregroundStyle(Palette.muted).lineSpacing(4)
        }
        .padding(.top, 18)
        .rise(3)
    }

    private func card(_ title: String, step: Int, rows: [(String, String)]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).overline(tracking: 0.08)
                Spacer()
                Button { edit(step) } label: {
                    HStack(spacing: 6) {
                        IconView(.edit, size: 14)
                        Text("Edit").font(Typo.manrope(13, .extrabold))
                    }
                    .foregroundStyle(Palette.yellow)
                    .frame(minWidth: 44, minHeight: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(title)")
            }
            ForEach(rows.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    Text(rows[i].0).font(Typo.manrope(14)).foregroundStyle(Palette.subtle)
                    Spacer()
                    Text(rows[i].1).font(Typo.manrope(14, .bold)).foregroundStyle(Palette.text).multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 8)
                .overlay(alignment: .top) { Rectangle().fill(Color.white(0.06)).frame(height: 1) }
            }
        }
        .padding(16)
        .glass(22)
    }
}
