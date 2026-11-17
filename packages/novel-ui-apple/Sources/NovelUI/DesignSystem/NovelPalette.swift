import SwiftUI
import CoreText

public enum NovelAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    public var id: String { rawValue }
    public var title: String { switch self { case .system: "跟随系统"; case .light: "日间"; case .dark: "夜间" } }
    public var colorScheme: ColorScheme? { switch self { case .system: nil; case .light: .light; case .dark: .dark } }
}

struct NovelPalette {
    let dark: Bool
    init(_ scheme: ColorScheme) { dark = scheme == .dark }
    var paper: Color { Color(hex: dark ? 0x081a22 : 0xffffff) }
    var sidebar: Color { Color(hex: dark ? 0x06131d : 0xf0f4fc) }
    var chrome: Color { Color(hex: dark ? 0x081521 : 0xf8faff) }
    var text: Color { Color(hex: dark ? 0xf2f7ef : 0x07141d) }
    var secondary: Color { Color(hex: dark ? 0xb0c2d6 : 0x465b73) }
    var rule: Color { Color(hex: dark ? 0x1c3443 : 0xd8e1ef) }
    var accent: Color { Color(hex: dark ? 0x71ffdb : 0x0032d9) }
    var brand: Color { dark ? text : accent }
    var selection: Color { Color(hex: dark ? 0x143791 : 0x0032d9) }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

public enum NovelBrandFonts {
    public static func register() {
        let bundle = Bundle.main.url(forResource: "NovelUIApple_NovelUI", withExtension: "bundle").flatMap(Bundle.init(url:)) ?? Bundle.module
        guard let url = bundle.url(forResource: "DFWAfterglowSolid-BoldItalic", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

struct NovelWordmark: View {
    let palette: NovelPalette
    var body: some View {
        HStack(spacing: 9) {
            Text("✦").font(.custom("DFWAfterglowSolid-BoldItalic", size: 23)).foregroundStyle(palette.text)
            Text("NOVEL ENGINE").font(.custom("DFWAfterglowSolid-BoldItalic", size: 12)).tracking(0.8).foregroundStyle(palette.brand)
        }.accessibilityElement(children: .ignore).accessibilityLabel("Novel Engine")
    }
}
