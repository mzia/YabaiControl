import Foundation

public struct YabaiSpace: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var uuid: String?
    public var index: Int
    public var label: String?
    public var type: String
    public var display: Int
    public var windows: [Int]
    public var hasFocus: Bool
    public var isVisible: Bool
    public var isNativeFullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case index
        case label
        case type
        case display
        case windows
        case hasFocus = "has-focus"
        case isVisible = "is-visible"
        case isNativeFullscreen = "is-native-fullscreen"
    }

    public init(id: Int, uuid: String? = nil, index: Int, label: String? = nil, type: String = "bsp", display: Int = 1, windows: [Int] = [], hasFocus: Bool = false, isVisible: Bool = true, isNativeFullscreen: Bool = false) {
        self.id = id
        self.uuid = uuid
        self.index = index
        self.label = label
        self.type = type
        self.display = display
        self.windows = windows
        self.hasFocus = hasFocus
        self.isVisible = isVisible
        self.isNativeFullscreen = isNativeFullscreen
    }
}

public struct YabaiWindow: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var pid: Int
    public var app: String
    public var title: String
    public var space: Int
    public var hasFocus: Bool
    public var isFloating: Bool
    public var isSticky: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case pid
        case app
        case title
        case space
        case hasFocus = "has-focus"
        case isFloating = "is-floating"
        case isSticky = "is-sticky"
    }

    public init(id: Int, pid: Int = 0, app: String, title: String = "", space: Int = 1, hasFocus: Bool = false, isFloating: Bool = false, isSticky: Bool = false) {
        self.id = id
        self.pid = pid
        self.app = app
        self.title = title
        self.space = space
        self.hasFocus = hasFocus
        self.isFloating = isFloating
        self.isSticky = isSticky
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.pid = try container.decodeIfPresent(Int.self, forKey: .pid) ?? 0
        self.app = try container.decode(String.self, forKey: .app)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.space = try container.decodeIfPresent(Int.self, forKey: .space) ?? 1
        self.hasFocus = try container.decodeIfPresent(Bool.self, forKey: .hasFocus) ?? false
        self.isFloating = try container.decodeIfPresent(Bool.self, forKey: .isFloating) ?? false
        self.isSticky = try container.decodeIfPresent(Bool.self, forKey: .isSticky) ?? false
    }
}
