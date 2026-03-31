import Foundation
import Saga
import SagaPathKit
import SagaParsleyMarkdownReader
import SagaLeafRenderer

struct AppMetadata: Metadata {
  let url: URL?
  let images: [String]?
}

let saga = try Saga(input: "content", output: "deploy")
defaultLeafRenderer = createLeafRenderer(templatesDirectory: saga.rootPath + "templates")

try await saga
  // All markdown files within the "apps" subfolder will be parsed to html,
  // using AppMetadata as the Item's metadata type.
    .register(
      folder: "apps",
      metadata: AppMetadata.self,
      readers: [.parsleyMarkdownReader],
      writers: [.listWriter(leaf("apps"))]
    )

  // All the Markdown files will be parsed to html,
  // using the default EmptyMetadata as the Item's metadata type.
  .register(
    readers: [.parsleyMarkdownReader],
    writers: [.itemWriter(leaf("page"))]
  )

  // Run the steps we registered above
  .run()
