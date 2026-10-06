import SwiftUI

/// The prototype's line icons (24 × 24 viewBox, 1.8 stroke, round caps and joins), drawn from the exact SVG paths.
enum Icon: CaseIterable {
    case check, family, home, arrowRight, arrowUpRight, eye, fingerprint, arrowLeft, lock, send, mail, external
    case shield, bell, pin, link, chevronRight, wallet, calendar, heart, play, close, grid, scan, help, image
    case bolt, card, bank, store, chevronDown, document, upload, settings, camera, phone, person, logout
    case search, plus, paperclip, replay, info, edit

    var paths: [String] {
        switch self {
        case .check: return ["M5 12.5 10 17 19 7"]
        case .family: return ["M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z", "M2 21a7 7 0 0 1 14 0", "M16 3.5a4 4 0 0 1 0 7.5", "M18 14a7 7 0 0 1 4 6.5"]
        case .home: return ["M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"]
        case .arrowRight: return ["M5 12h14", "m13 6 6 6-6 6"]
        case .arrowUpRight: return ["M7 17 17 7", "M8 7h9v9"]
        case .eye: return ["M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z", "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"]
        case .fingerprint: return ["M12 11v3a8 8 0 0 1-1.5 4.7", "M8.5 7.5A5 5 0 0 1 17 11v2a12 12 0 0 1-.6 3.8", "M7 11a5 5 0 0 1 .3-1.7", "M7 14a11 11 0 0 1-1 4", "M4.5 6.5A9 9 0 0 1 21 11v1", "M3 11a9 9 0 0 1 .5-3"]
        case .arrowLeft: return ["M19 12H5", "m11 6-6 6 6 6"]
        case .lock: return ["M6 11h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1z", "M8 11V7a4 4 0 0 1 8 0v4"]
        case .send: return ["M4 12 20 4l-6 16-3-7z", "m11 13 9-9"]
        case .mail: return ["M4 5h16a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z", "m3 7 9 6 9-6"]
        case .external: return ["M14 4h6v6", "m20 4-9 9", "M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"]
        case .shield: return ["M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z", "m9 12 2 2 4-4"]
        case .bell: return ["M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9", "M10.3 21a1.94 1.94 0 0 0 3.4 0"]
        case .pin: return ["M12 21s7-6.2 7-12a7 7 0 0 0-14 0c0 5.8 7 12 7 12z", "M12 11.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z"]
        case .link: return ["M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1", "M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"]
        case .chevronRight: return ["m9 6 6 6-6 6"]
        case .wallet: return ["M4 6h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a1 1 0 0 1-1-1z", "M4 6a2 2 0 0 1 2-2h10v2", "M16 13h.01"]
        case .calendar: return ["M4 6h16v14H4z", "M4 10h16M8 3v4M16 3v4"]
        case .heart: return ["M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"]
        case .play: return ["M7 4.5v15l13-7.5z"]
        case .close: return ["M6 6l12 12M18 6 6 18"]
        case .grid: return ["M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z"]
        case .scan: return ["M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3", "M4 12h16"]
        case .help: return ["M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z", "M9.5 9.5a2.5 2.5 0 0 1 4.9.7c0 1.6-2.4 2-2.4 3.3", "M12 16.5h.01"]
        case .image: return ["M4 4h16v16H4z", "m4 16 5-5 4 4 2-2 5 5", "M15.5 9.5h.01"]
        case .bolt: return ["M13 2 4 14h7l-1 8 9-12h-7z"]
        case .card: return ["M3 6h18v12H3z", "M3 10h18M7 15h3"]
        case .bank: return ["M3 10 12 4l9 6", "M5 10v8M9.5 10v8M14.5 10v8M19 10v8M3 20h18"]
        case .store: return ["M4 9l1.5-5h13L20 9", "M4 9v11h16V9", "M4 9h16", "M10 20v-5h4v5"]
        case .chevronDown: return ["m6 9 6 6 6-6"]
        case .document: return ["M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z", "M14 3v5h5", "M9 13h6M9 17h4"]
        case .upload: return ["M12 16V4", "m7 9 5-5 5 5", "M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3"]
        case .settings: return ["M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z", "M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"]
        case .camera: return ["M4 7h3l2-3h6l2 3h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z", "M12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"]
        case .phone: return ["M7 2h10a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z", "M11 18h2"]
        case .person: return ["M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z", "M4 21a8 8 0 0 1 16 0"]
        case .logout: return ["M15 4h3a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-3", "m10 16-4-4 4-4", "M6 12h10"]
        case .search: return ["M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14z", "m20 20-3.5-3.5"]
        case .plus: return ["M12 5v14M5 12h14"]
        case .paperclip: return ["m21 11-8.5 8.5a5 5 0 0 1-7-7L14 4a3.5 3.5 0 0 1 5 5l-8.5 8.5a2 2 0 0 1-3-3L15 7"]
        case .replay: return ["M20 11a8 8 0 1 0-2.3 5.7", "M20 4v7h-7"]
        case .info: return ["M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z", "M12 11v5M12 8h.01"]
        case .edit: return ["M4 20h4L19 9l-4-4L4 16z", "m13.5 6.5 4 4"]
        }
    }

    var filled: Bool { self == .play }

    /// Parsed once, in 24 × 24 space.
    var path: Path { IconCache.path(for: self) }
}

private enum IconCache {
    private static var cache: [Icon: Path] = [:]
    private static let lock = NSLock()

    static func path(for icon: Icon) -> Path {
        lock.lock(); defer { lock.unlock() }
        if let p = cache[icon] { return p }
        var p = Path()
        for d in icon.paths { p.addPath(SVGPath.parse(d)) }
        cache[icon] = p
        return p
    }
}

/// An icon at a given CSS pixel size; the stroke scales with it like the SVG would.
struct IconView: View {
    let icon: Icon
    var size: CGFloat = 20

    init(_ icon: Icon, size: CGFloat = 20) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        // Stroked icons are outlined into a fillable path, so both kinds take the foreground style.
        IconShape(icon: icon)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct IconShape: Shape {
    let icon: Icon
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let base = icon.path.applying(CGAffineTransform(scaleX: s, y: s).translatedBy(x: rect.minX / s, y: rect.minY / s))
        if icon.filled { return base }
        return base.strokedPath(StrokeStyle(lineWidth: 1.8 * s, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Minimal SVG path parser (M L H V C S Q T A Z, absolute and relative)

enum SVGPath {
    static func parse(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var i = 0
        var cmd: Character = "M"
        var cur = CGPoint.zero
        var start = CGPoint.zero
        var lastCtrl: CGPoint? = nil
        var lastQuad: CGPoint? = nil

        func num() -> CGFloat {
            guard i < tokens.count, case let .number(v) = tokens[i] else { return 0 }
            i += 1
            return v
        }
        func hasNumber() -> Bool {
            if i < tokens.count, case .number = tokens[i] { return true }
            return false
        }

        while i < tokens.count {
            if case let .command(c) = tokens[i] {
                cmd = c
                i += 1
            }
            let rel = cmd.isLowercase
            let base = rel ? cur : .zero
            switch cmd.uppercased().first! {
            case "M":
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                path.move(to: p)
                cur = p; start = p
                cmd = rel ? "l" : "L" // subsequent pairs are implicit lineto
                lastCtrl = nil; lastQuad = nil
            case "L":
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                path.addLine(to: p); cur = p
                lastCtrl = nil; lastQuad = nil
            case "H":
                let x = (rel ? cur.x : 0) + num()
                cur = CGPoint(x: x, y: cur.y); path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case "V":
                let y = (rel ? cur.y : 0) + num()
                cur = CGPoint(x: cur.x, y: y); path.addLine(to: cur)
                lastCtrl = nil; lastQuad = nil
            case "C":
                let c1 = CGPoint(x: base.x + num(), y: base.y + num())
                let c2 = CGPoint(x: base.x + num(), y: base.y + num())
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                path.addCurve(to: p, control1: c1, control2: c2)
                cur = p; lastCtrl = c2; lastQuad = nil
            case "S":
                let c1 = lastCtrl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = CGPoint(x: base.x + num(), y: base.y + num())
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                path.addCurve(to: p, control1: c1, control2: c2)
                cur = p; lastCtrl = c2; lastQuad = nil
            case "Q":
                let c = CGPoint(x: base.x + num(), y: base.y + num())
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                path.addQuadCurve(to: p, control: c)
                cur = p; lastQuad = c; lastCtrl = nil
            case "T":
                let c = lastQuad.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                path.addQuadCurve(to: p, control: c)
                cur = p; lastQuad = c; lastCtrl = nil
            case "A":
                let rx = num(), ry = num(), rot = num(), large = num() != 0, sweep = num() != 0
                let p = CGPoint(x: base.x + num(), y: base.y + num())
                addArc(&path, from: cur, to: p, rx: rx, ry: ry, rotation: rot, largeArc: large, sweep: sweep)
                cur = p; lastCtrl = nil; lastQuad = nil
            case "Z":
                path.closeSubpath(); cur = start
                lastCtrl = nil; lastQuad = nil
                if hasNumber() { cmd = "L" }
            default:
                i += 1
            }
        }
        return path
    }

    private enum Token { case command(Character), number(CGFloat) }

    private static func tokenize(_ d: String) -> [Token] {
        var out: [Token] = []
        let chars = Array(d)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isLetter && c != "e" && c != "E" {
                out.append(.command(c)); i += 1
            } else if c == "-" || c == "+" || c == "." || c.isNumber {
                var j = i
                var s = ""
                if chars[j] == "-" || chars[j] == "+" { s.append(chars[j]); j += 1 }
                var seenDot = false, seenExp = false
                while j < chars.count {
                    let ch = chars[j]
                    if ch.isNumber { s.append(ch); j += 1 }
                    else if ch == "." && !seenDot && !seenExp { seenDot = true; s.append(ch); j += 1 }
                    else if (ch == "e" || ch == "E") && !seenExp {
                        seenExp = true; s.append(ch); j += 1
                        if j < chars.count, chars[j] == "-" || chars[j] == "+" { s.append(chars[j]); j += 1 }
                    } else { break }
                }
                out.append(.number(CGFloat(Double(s) ?? 0)))
                i = j
            } else {
                i += 1
            }
        }
        return out
    }

    /// SVG endpoint arc → cubic Béziers (SVG spec F.6).
    private static func addArc(_ path: inout Path, from p0: CGPoint, to p1: CGPoint, rx rxIn: CGFloat, ry ryIn: CGFloat, rotation: CGFloat, largeArc: Bool, sweep: Bool) {
        var rx = abs(rxIn), ry = abs(ryIn)
        if rx == 0 || ry == 0 || p0 == p1 { path.addLine(to: p1); return }
        let phi = rotation * .pi / 180
        let cosP = cos(phi), sinP = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1p = cosP * dx + sinP * dy
        let y1p = -sinP * dx + cosP * dy
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
        let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
        let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
        var coef = sqrt(max(0, num / den))
        if largeArc == sweep { coef = -coef }
        let cxp = coef * rx * y1p / ry
        let cyp = -coef * ry * x1p / rx
        let cx = cosP * cxp - sinP * cyp + (p0.x + p1.x) / 2
        let cy = sinP * cxp + cosP * cyp + (p0.y + p1.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var dTheta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }
        if sweep && dTheta < 0 { dTheta += 2 * .pi }

        let segments = Int(ceil(abs(dTheta) / (.pi / 2)))
        let delta = dTheta / CGFloat(segments)
        let t = 4 / 3 * tan(delta / 4)
        var th = theta1
        for _ in 0..<segments {
            let cos1 = cos(th), sin1 = sin(th)
            let cos2 = cos(th + delta), sin2 = sin(th + delta)
            let e1 = CGPoint(x: cos1 - t * sin1, y: sin1 + t * cos1)
            let e2 = CGPoint(x: cos2 + t * sin2, y: sin2 - t * cos2)
            let e3 = CGPoint(x: cos2, y: sin2)
            func map(_ p: CGPoint) -> CGPoint {
                CGPoint(x: cx + rx * p.x * cosP - ry * p.y * sinP, y: cy + rx * p.x * sinP + ry * p.y * cosP)
            }
            path.addCurve(to: map(e3), control1: map(e1), control2: map(e2))
            th += delta
        }
    }
}
