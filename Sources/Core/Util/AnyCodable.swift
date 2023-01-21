import Foundation

///  A type-erased codable value.
struct AnyCodable {
  var base: Any

  /// Creates a type-erased codable value that wraps the given instance.
  ///
  /// - Parameter base: A codable value to wrap.
  init(_ base: Codable) {
    self.base = base
  }

  /// Used for converting arrays and dictionaries
  fileprivate init(_ base: Any) {
    self.base = base
  }
}

extension AnyCodable: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self.init(NSNull())
    } else if let value = try? container.decode(Bool.self) {
      self.init(value)
    } else if let value = try? container.decode(Int.self) {
      self.init(value)
    } else if let value = try? container.decode(Double.self) {
      self.init(value)
    } else if let value = try? container.decode(String.self) {
      self.init(value)
    } else if let value = try? container.decode([AnyCodable].self) {
      self.init(value.map(\.base))
    } else if let value = try? container.decode([String: AnyCodable].self) {
      self.init(value.mapValues(\.base))
    } else {
      throw DecodingError.typeMismatch(
        AnyCodable.self,
        .init(
          codingPath: container.codingPath,
          debugDescription: "Unable to decode value"
        )
      )
    }
  }
}

extension AnyCodable: Encodable {
  func encode(to encoder: Encoder) throws {
    switch self.base {
    case is NSNull:
      var container = encoder.singleValueContainer()
      try container.encodeNil()
    case let value as [Any]:
      try value.map(AnyCodable.init).encode(to: encoder)
    case let value as [String: Any]:
      try value.mapValues(AnyCodable.init).encode(to: encoder)
    case let value as Encodable:
      try value.encode(to: encoder)
    default:
      throw EncodingError.invalidValue(
        self.base,
        .init(
          codingPath: encoder.codingPath,
          debugDescription: "Unable to encode value \(self.base)"
        )
      )
    }
  }
}

extension AnyCodable: CustomStringConvertible {
  var description: String {
    if self.base is Void { return "nil" }
    return String(describing: self.base)
  }
}

extension AnyCodable: Equatable {
  static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
    isEqual(lhs.base, rhs.base)
  }
}

extension AnyCodable: ExpressibleByNilLiteral {
  init(nilLiteral: ()) {
    self.init(NSNull())
  }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
  init(booleanLiteral value: Bool) {
    self.init(value)
  }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
  init(integerLiteral value: IntegerLiteralType) {
    self.init(value)
  }
}

extension AnyCodable: ExpressibleByFloatLiteral {
  init(floatLiteral value: FloatLiteralType) {
    self.init(value)
  }
}

extension AnyCodable: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(value)
  }
}

extension AnyCodable: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: AnyCodable...) {
    self.init(elements.map(\.base))
  }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (String, AnyCodable)...) {
    self.init(Dictionary(elements) { $1 }.mapValues(\.base))
  }
}
