import Foundation
// Le dessin n'a rien à faire dans un export texte : on remplace juste ce
// que Program.swift attend du thème.
struct Color { init(hex: UInt32) {} }
struct LinearGradient { init(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) {} }
struct UnitPoint { static let topLeading = UnitPoint(); static let bottomTrailing = UnitPoint() }
