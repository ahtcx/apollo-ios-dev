import Foundation
import ArgumentParser
import ApolloCodegenLib

/// Shared group of common arguments used in commands for input parameters.
struct InputOptions: ParsableArguments {
  @Option(
    name: .shortAndLong,
    help: """
      Read the configuration from a file at the path. --string overrides this option if used \
      together.
      """
  )
  var path: String = Constants.defaultFilePath

  @Option(
    name: .shortAndLong,
    help: "Configuration string in JSON format. This option overrides --path."
  )
  var string: String?

  @Flag(
    name: .shortAndLong,
    help: "Expand environment variables in configuration"
  )
  var expandEnvironmentVariables: Bool = false

  @Flag(
    name: .shortAndLong,
    help: "Increase verbosity to include debug output."
  )
  var verbose: Bool = false
  
  @Flag(
    name: .long,
    help: "Ignore Apollo version mismatch errors. Warning: This may lead to incompatible generated objects."
  )
  var ignoreVersionMismatch: Bool = false

  func getCodegenConfiguration(fileManager: FileManager) throws -> ApolloCodegenConfiguration {
    var data: Data
    switch (string, path) {
    case let (.some(string), _):
      data = try preProcessConfiguration(string).asData()

    case let (nil, path):
      data = try preProcessConfiguration(data: fileManager.unwrappedContents(atPath: path))
    }
    return try JSONDecoder().decode(ApolloCodegenConfiguration.self, from: data)
  }

  func preProcessConfiguration(_ string: String) throws -> String {
    if expandEnvironmentVariables {
      expandEnvironmentVariables(in: string)
    } else {
      string
    }
  }

  func preProcessConfiguration(data: Data) throws -> Data {
    if expandEnvironmentVariables, let dataAsString = String(data: data, encoding: .utf8) {
      try expandEnvironmentVariables(in: dataAsString).asData()
    } else {
      data
    }
  }

  func expandEnvironmentVariables(in input: String) -> String {
    input.replacing(#/\$\(([^)]+)\)/#) { match in
      ProcessInfo.processInfo.environment[String(match.1)] ?? ""
    }
  }
}
