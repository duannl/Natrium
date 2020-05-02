//
//  SwiftVariablesParser.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 06/02/2019.
//

import Foundation
import Yaml
import Francium

class SwiftVariablesParser: Parseable {

    var yamlKey: String {
        return "variables"
    }

    var isRequired: Bool {
        return true
    }

    func parse(_ dictionary: [String: Yaml]) throws {
        var lines: [String] = []
        let tab = "    "
        lines.append("import Foundation")
        lines.append("")
        lines.append("/// Natrium.swift")
        lines.append("/// Autogenerated by Natrium")
        lines.append("///")
        lines.append("/// - see: https://github.com/e-sites/Natrium")
        lines.append("")
        lines.append("public enum Natrium {")
        lines.append("")
        lines.append("\(tab)public enum Environment: String {")
        for environment in data.environments.sorted() {
            lines.append("\(tab)\(tab)case \(environment.lowercased()) = \"\(environment)\"")
        }
        lines.append("\(tab)}")
        lines.append("")
        lines.append("\(tab)public enum Configuration: String {")
        for configuration in data.configurations.sorted() {
            lines.append("\(tab)\(tab)case \(configuration.lowercased()) = \"\(configuration)\"")
        }
        lines.append("\(tab)}")
        lines.append("")
        lines.append("\(tab)public enum Config {")

        lines.append("\(tab)\(tab)public static let configuration: Configuration = .\(data.configuration.lowercased())")
        lines.append("\(tab)\(tab)public static let environment: Environment = .\(data.environment.lowercased())")
        lines.append("")
        
        for keyValue in dictionary.sorted(by: { $0.key < $1.key }) {
            lines.append("\(tab)\(tab)\(_variable(keyValue))")
        }
        lines.append("\(tab)}")
        lines.append("}")

        let newContents = lines.joined(separator: "\n")

        let file = File(path: FileManager.default.currentDirectoryPath + "/Natrium.swift")
        try file.writeChanges(string: newContents)
    }

    private func _variable(_ keyValue: (key: String, value: Yaml)) -> String {
        let type: String
        var value = keyValue.value.stringValue

        switch keyValue.value {
        case .int:
            type = "Int"
        case .double:
            type = "Double"
        case .bool:
            type = "Bool"
        case .null:
            type = "String?"
        default:
            type = "String"
            value = "\"\(value)\""
        }
        return "public static let \(keyValue.key): \(type) = \(value)"
    }
}
