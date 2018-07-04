//
//  Natrium.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 20/10/2017.
//

import Foundation
import XcodeEdit
import Yaml

class Natrium {

    static var version: String = "5.7.0"

    let projectDir: String
    let configuration: String
    let environment: String
    let target: String
    var infoPlistPath: String!
    var environments: [String] = []
    var configurations: [String] = []
    var appVersion: String = "1.0"
    var xcProjectFile: XCProjectFile!
    var xcTarget: PBXTarget!

    var xcodeProjectPath: String!

    lazy fileprivate var yamlHelper: NatriumYamlHelper = {
        return NatriumYamlHelper(natrium: self)
    }()

    var settings: [Yaml: Yaml] {
        return yamlHelper.settings
    }

    lazy fileprivate var lock: NatriumLock = {
        return NatriumLock(natrium: self)
    }()

    lazy var parsers: [Parser] = {
        return [
            SwiftVariablesParser(natrium: self),
            XccConfigParser(natrium: self),
            AppIconParser(natrium: self),
            LaunchScreenStoryboardParser(natrium: self),
            PlistParser(natrium: self),
            FilesParser(natrium: self)
        ]
    }()

    init(projectDir: String, target: String, configuration: String, environment: String, force: Bool = true) {
        self.projectDir = Dir.dirName(path: projectDir)
        self.target = target
        self.configuration = configuration
        self.environment = environment
        Logger.clearLogFile()
        if force {
            lock.remove()
        }
    }

    func run() {
        if !File.exists(at: yamlFile) {
            Logger.fatalError("Cannot find \(yamlFile)")
        }

        guard let xcodeProjectPath = Dir.glob("\(projectDir)/*.xcodeproj").first?.path else {
            Logger.fatalError("Cannot find xcodeproj in folder '\(projectDir)'")
            return
        }
        self.xcodeProjectPath = xcodeProjectPath
        _getXcodeProject()
        _getInfoPlistFile()

        if let version = PlistHelper.getValue(for: "CFBundleShortVersionString", in: infoPlistPath) {
            self.appVersion = version
        }
        
        defer {
            Logger.logLines.removeAll()
        }

        if !lock.needsUpdate {
            return
        }
        Logger.log(Logger.colorWrap(text: "Running Natrium installer (v\(Natrium.version))", in: "1"))
        Logger.log("")
        yamlHelper.parse()

        print(Logger.logLines.joined(separator: "\n"))
        lock.create()

        Logger.insets = 0
        Logger.success("Natrium ▸ Success!")
    }
}

extension Natrium {
    var yamlFile: String {
        return "\(projectDir)/.natrium.yml"
    }
}

extension Natrium {
    fileprivate func _getXcodeProject() {
        let xcodeproj = URL(fileURLWithPath: xcodeProjectPath)
        do {
            xcProjectFile = try XCProjectFile(xcodeprojURL: xcodeproj)
        } catch let error {
            Logger.fatalError("\(error)")
            return
        }

        guard let target = (xcProjectFile.project.targets.first { $0.name == self.target }) else {
            Logger.fatalError("Cannot find target '\(self.target)' in '\(xcodeProjectPath ?? "")'")
            return
        }

        self.configurations = target.buildConfigurationList.buildConfigurations.map { $0.name }
        self.xcTarget = target
    }

    fileprivate func _getInfoPlistFile() {
        guard let buildConfiguration = (xcTarget.buildConfigurationList.buildConfigurations
            .first { $0.name == self.configuration }) else {
                Logger.fatalError("Cannot find configuration '\(self.configuration)' in '\(xcodeProjectPath ?? "")'")
                return
        }

        guard let infoPlist = buildConfiguration.buildSettings?["INFOPLIST_FILE"] as? String else {
            Logger.fatalError("Cannot find INFOPLIST_FILE in '\(xcodeProjectPath)'")
            return
        }

        infoPlistPath = "\(projectDir)/\(infoPlist)"

        if !File.exists(at: infoPlistPath) {
            Logger.fatalError("Cannot find \(infoPlistPath)")
        }
    }
}
