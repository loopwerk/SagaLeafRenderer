# SagaLeafRenderer
A renderer for [Saga](https://github.com/loopwerk/Saga) that uses [Leaf templates](https://github.com/vapor/leaf-kit) to turn a rendering context into a string.

It comes with a free function named `leaf` which takes a template name, and returns a function that goes from `DictRenderingContext` to `String`, which can then be plugged into Saga's writers.

## Example
Package.swift

``` swift
// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "Example",
  platforms: [
    .macOS(.v14)
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaLeafRenderer", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "Example",
      dependencies: [
        "SagaParsleyMarkdownReader",
        "SagaLeafRenderer"
      ]
    ),
  ]
)
```

main.swift:

```swift
import Saga
import SagaParsleyMarkdownReader
import SagaLeafRenderer

let saga = try Saga(input: "content", output: "deploy")
defaultLeafRenderer = createLeafRenderer(templatesDirectory: saga.rootPath + "templates")

try await saga
  // All the Markdown files will be parsed to html.
  .register(
    readers: [.parsleyMarkdownReader],
    writers: [
      .itemWriter(leaf("page"))
    ]
  )

  // Run the steps we registered above
  .run()
```

Please check out the [Example app](https://github.com/loopwerk/SagaLeafRenderer/tree/main/Example) to play around.
