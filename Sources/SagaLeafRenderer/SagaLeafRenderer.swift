import LeafKit
import Saga
import SagaPathKit
import NIOCore
import NIOPosix
import Foundation

public func createLeafRenderer(templatesDirectory: Path) -> LeafRenderer {
  let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
  let threadPool = NIOThreadPool(numberOfThreads: 2)
  threadPool.start()
  let fileio = NonBlockingFileIO(threadPool: threadPool)
  
  let absPath = URL(fileURLWithPath: templatesDirectory.string).standardized.path
  let configuration = LeafConfiguration(rootDirectory: absPath)
  return LeafRenderer(
    configuration: configuration,
    sources: .singleSource(NIOLeafFiles(
      fileio: fileio,
      limits: .default,
      sandboxDirectory: absPath,
      viewDirectory: absPath
    )),
    eventLoop: eventLoopGroup.next()
  )
}

nonisolated(unsafe) public var defaultLeafRenderer: LeafRenderer?

private extension ByteBuffer {
  var string: String {
    String(decoding: self.readableBytesView, as: UTF8.self)
  }
}

public func leaf(_ template: String, renderer: LeafRenderer? = nil) -> (@Sendable (DictRenderingContext) async throws -> String) {
  nonisolated(unsafe) let renderer = renderer ?? defaultLeafRenderer
  return { context in
    guard let renderer else {
      fatalError("No LeafRenderer provided. Either pass one to leaf() or set defaultLeafRenderer first.")
    }
    let leafContext = context.asDictionary().toLeafData()
    return try await renderer.render(path: template, context: leafContext).get().string
  }
}

// MARK: - [String: Any] to [String: LeafData] conversion

extension Dictionary where Key == String, Value == Any {
  func toLeafData() -> [String: LeafData] {
    return self.mapValues { anyToLeafData($0) }
  }
}

private func anyToLeafData(_ value: Any) -> LeafData {
  switch value {
  case let string as String:
    return .string(string)
  case let int as Int:
    return .int(int)
  case let double as Double:
    return .double(double)
  case let bool as Bool:
    return .bool(bool)
  case let date as Date:
    return .double(date.timeIntervalSince1970)
  case let path as Path:
    return .string(path.string)
  case let dict as [String: Any]:
    return .dictionary(dict.toLeafData())
  case let array as [Any]:
    return .array(array.map { anyToLeafData($0) })
  case let encodable as Encodable:
    return encodableToLeafData(encodable)
  default:
    return .string(nil)
  }
}

private func encodableToLeafData(_ value: Encodable) -> LeafData {
  guard let data = try? JSONEncoder().encode(value),
        let json = try? JSONSerialization.jsonObject(with: data) else {
    return .string(nil)
  }
  return jsonToLeafData(json)
}

private func jsonToLeafData(_ value: Any) -> LeafData {
  switch value {
  case let string as String:
    return .string(string)
  case let number as NSNumber:
    if CFBooleanGetTypeID() == CFGetTypeID(number) {
      return .bool(number.boolValue)
    } else if number.doubleValue == Double(number.intValue) {
      return .int(number.intValue)
    } else {
      return .double(number.doubleValue)
    }
  case let array as [Any]:
    return .array(array.map { jsonToLeafData($0) })
  case let dict as [String: Any]:
    return .dictionary(dict.mapValues { jsonToLeafData($0) })
  default:
    return .string(nil)
  }
}
