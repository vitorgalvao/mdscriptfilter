import AppKit
import ArgumentParser
import UniformTypeIdentifiers

struct ScriptFilter: Codable {
  let items: [Item]

  struct Item: Codable {
    static let imageFormats: Array = NSImage.imageUnfilteredTypes
    let uid: String
    let title: String
    let subtitle: String?
    let type: String
    let match: String?
    let icon: Icon
    let arg: String

    struct Icon: Codable {
      let path: String
      let type: String?
    }

    init(_ fileString: String, hideSubtitle: Bool, matchPath: Bool, displayImages: Bool) {
      let fileURL: URL = URL(filePath: fileString)
      let fileName: String = fileURL.lastPathComponent
      let iconType: String? = displayImages ? {
        guard
          let fileFormat = try? fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType?.identifier,
          Item.imageFormats.contains(fileFormat)
        else { return "fileicon" }
        return nil
      }() : "fileicon"

      self.uid = fileString
      self.title = fileName
      self.subtitle = hideSubtitle ? nil : (fileString as NSString).abbreviatingWithTildeInPath
      self.type = "file:skipcheck"
      self.match = matchPath ? fileString : nil
      self.arg = fileString
      self.icon = Icon(path: fileString, type: iconType)
    }
  }
}

struct Mdscriptfilter: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Search Spotlight database and output result as Script Filter (or Grid View) JSON for Alfred.",
    discussion: """
    Query predicates look similar to metadata searches in mdfind. For example, to find PDF files:

      \(ProcessInfo.processInfo.processName) 'kMDItemContentType == "com.adobe.pdf"'

    Or text files with the word "imagination" (case-insensitive) somewhere in the content:

      \(ProcessInfo.processInfo.processName) 'kMDItemContentType == "public.plain-text" AND kMDItemTextContent CONTAINS[c] "imagination"'

    Or all screenshots on the Desktop and its folders, sorted by the most recently added:

      \(ProcessInfo.processInfo.processName) 'kMDItemIsScreenCapture == 1' --positive-scope ~/Desktop --sort-key 'kMDItemDateAdded'

    See Apple’s documentation for help with syntax:

      https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html#//apple_ref/doc/uid/TP40001849-CJBEJBHH
      https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795-215832
      https://developer.apple.com/library/archive/documentation/CoreServices/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694-SW1
      https://developer.apple.com/documentation/coreservices/file_metadata/mditem/common_metadata_attribute_keys
    """,
    version: "25.1")

  @Argument(help: "The query predicate for the search.")
  var inputQuery: String

  @Option(help: "Restrict search to folder. Can be used multiple times.")
  var positiveScope: [String] = [("~" as NSString).expandingTildeInPath]

  @Option(help: "Exclude folder from results. Can be used multiple times.")
  var negativeScope: [String] = []

  @Flag(help: "Exclude user Library folder from results.")
  var excludeLibrary: Bool = false

  @Option(help: "Metadata field to use for sorting")
  var sortKey: String = "kMDItemFSName"

  @Flag(help: "Sort in ascending order.")
  var sortAscending: Bool = false

  @Flag(help: "Preview images and PDFs for Grid View.")
  var displayImages: Bool = false

  @Flag(help: "Do not show subtitles.")
  var hideSubtitle: Bool = false

  @Flag(help: "Use full path for filtering.")
  var matchPath: Bool = false

  func run() throws {
    // Run query
    let query = NSMetadataQuery()
    query.searchScopes = positiveScope.map { URL(fileURLWithPath: $0) }
    query.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: sortAscending)]
    query.predicate = NSPredicate(format: inputQuery)

    let finishedNotification = NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: nil) { _ in
      query.stop()
      CFRunLoopStop(CFRunLoopGetMain())
    }

    query.start()
    CFRunLoopRun()
    NotificationCenter.default.removeObserver(finishedNotification)

    // Parse items
    let results = query.results as? [NSMetadataItem] ?? []

    let libraryPaths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).map { $0.path }
    let excludedPaths = excludeLibrary ? negativeScope + libraryPaths : negativeScope

    let sfItems: [ScriptFilter.Item] = results.compactMap {
      guard let resultPath = $0.value(forAttribute: NSMetadataItemPathKey) as? String else { return nil }
      for excludedPath in excludedPaths { guard !resultPath.hasPrefix(excludedPath) else { return nil } }
      return ScriptFilter.Item(resultPath, hideSubtitle: hideSubtitle, matchPath: matchPath, displayImages: displayImages)
    }

    // No results
    guard !sfItems.isEmpty else {
      let icon = displayImages ? ",\"icon\":{\"path\":\"icon.png\"}" : ""
      return print("{\"items\":[{\"title\":\"No Results\",\"subtitle\":\"No matches found for your query\",\"valid\":false,\(icon)}]}")
    }

    // Output JSON
    let jsonData = try JSONEncoder().encode(["items": sfItems])
    print(String(data: jsonData, encoding: .utf8)!)
  }
}

Mdscriptfilter.main()
