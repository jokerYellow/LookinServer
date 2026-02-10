#if SHOULD_COMPILE_LOOKIN_SERVER

//
//  LKMCPServer.swift
//  LookinServer
//
//  Created by MCP Integration
//  https://lookin.work
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// MCP (Model Context Protocol) Server for Lookin
/// Provides tools for AI assistants to query and analyze UI hierarchy
@objc public class LKMCPServer: NSObject {
    
    @objc public static let shared = LKMCPServer()
    
    private var isRunning = false
    private let bridge: Any? // LKMCPBridge instance
    
    private override init() {
        // Initialize bridge
        if let bridgeClass = NSClassFromString("LKMCPBridge") as? NSObject.Type {
            self.bridge = bridgeClass.perform(NSSelectorFromString("sharedInstance"))?.takeUnretainedValue()
        } else {
            self.bridge = nil
        }
        super.init()
    }
    
    /// Start the MCP server
    @objc public func start() {
        guard !isRunning else {
            print("[LKMCPServer] Already running")
            return
        }
        
        isRunning = true
        print("[LKMCPServer] Started successfully")
        print("[LKMCPServer] Available tools:")
        print("  - get_ui_hierarchy")
        print("  - get_display_item_details")
        print("  - search_ui_elements")
        print("  - analyze_layout")
    }
    
    /// Stop the MCP server
    @objc public func stop() {
        guard isRunning else {
            print("[LKMCPServer] Not running")
            return
        }
        
        isRunning = false
        print("[LKMCPServer] Stopped")
    }
    
    /// Check if server is running
    @objc public var running: Bool {
        return isRunning
    }
    
    // MARK: - MCP Tools Implementation
    
    /// Tool: get_ui_hierarchy
    /// Get the complete UI hierarchy tree structure
    @objc public func getUIHierarchy() -> [String: Any] {
        guard let bridge = self.bridge as? NSObject else {
            return ["error": "Bridge not available"]
        }
        
        guard let hierarchy = bridge.perform(NSSelectorFromString("getCurrentHierarchy"))?.takeUnretainedValue() else {
            return ["error": "Failed to get hierarchy"]
        }
        
        return LKMCPDataFormatter.formatHierarchyInfo(hierarchy)
    }
    
    /// Tool: get_display_item_details
    /// Get detailed information for a specific UI element
    /// - Parameter oid: The object identifier of the display item
    @objc public func getDisplayItemDetails(oid: UInt) -> [String: Any] {
        guard let bridge = self.bridge as? NSObject else {
            return ["error": "Bridge not available"]
        }
        
        let selector = NSSelectorFromString("getDisplayItemDetails:")
        guard bridge.responds(to: selector) else {
            return ["error": "Method not available"]
        }
        
        let oidValue = NSNumber(value: oid)
        guard let detail = bridge.perform(selector, with: oidValue)?.takeUnretainedValue() else {
            return ["error": "Display item not found", "oid": oid]
        }
        
        return LKMCPDataFormatter.formatDisplayItemDetail(detail)
    }
    
    /// Tool: search_ui_elements
    /// Search for UI elements matching given criteria
    /// - Parameters:
    ///   - className: Optional class name to filter by
    ///   - title: Optional title/text to search for
    @objc public func searchUIElements(className: String?, title: String?) -> [String: Any] {
        guard let bridge = self.bridge as? NSObject else {
            return ["error": "Bridge not available"]
        }
        
        let selector = NSSelectorFromString("searchDisplayItemsWithClassName:title:")
        guard bridge.responds(to: selector) else {
            return ["error": "Method not available"]
        }
        
        // Use NSInvocation for multi-parameter method
        let method = class_getInstanceMethod(type(of: bridge), selector)!
        let imp = method_getImplementation(method)
        
        typealias FunctionType = @convention(c) (AnyObject, Selector, String?, String?) -> [Any]
        let function = unsafeBitCast(imp, to: FunctionType.self)
        let results = function(bridge, selector, className, title)
        
        var formattedResults: [[String: Any]] = []
        for item in results {
            formattedResults.append(LKMCPDataFormatter.formatDisplayItem(item))
        }
        
        return [
            "results": formattedResults,
            "count": results.count,
            "query": [
                "className": className ?? "",
                "title": title ?? ""
            ]
        ]
    }
    
    /// Tool: analyze_layout
    /// Analyze the UI layout for potential issues
    @objc public func analyzeLayout() -> [String: Any] {
        guard let bridge = self.bridge as? NSObject else {
            return ["error": "Bridge not available"]
        }
        
        guard let analysis = bridge.perform(NSSelectorFromString("analyzeLayoutIssues"))?.takeUnretainedValue() as? [String: Any] else {
            return ["error": "Failed to analyze layout"]
        }
        
        return analysis
    }
    
    // MARK: - Helper Methods
    
    /// Get list of available MCP tools
    @objc public func getAvailableTools() -> [[String: Any]] {
        return [
            [
                "name": "get_ui_hierarchy",
                "description": "Get the complete UI hierarchy tree structure",
                "parameters": []
            ],
            [
                "name": "get_display_item_details",
                "description": "Get detailed information for a specific UI element",
                "parameters": [
                    [
                        "name": "oid",
                        "type": "integer",
                        "description": "The object identifier of the display item",
                        "required": true
                    ]
                ]
            ],
            [
                "name": "search_ui_elements",
                "description": "Search for UI elements matching given criteria",
                "parameters": [
                    [
                        "name": "className",
                        "type": "string",
                        "description": "Optional class name to filter by",
                        "required": false
                    ],
                    [
                        "name": "title",
                        "type": "string",
                        "description": "Optional title/text to search for",
                        "required": false
                    ]
                ]
            ],
            [
                "name": "analyze_layout",
                "description": "Analyze the UI layout for potential issues (overlapping, out of bounds, hidden elements)",
                "parameters": []
            ]
        ]
    }
    
    /// Execute a tool by name
    @objc public func executeTool(name: String, parameters: [String: Any]?) -> [String: Any] {
        switch name {
        case "get_ui_hierarchy":
            return getUIHierarchy()
            
        case "get_display_item_details":
            guard let oid = parameters?["oid"] as? UInt else {
                return ["error": "Missing required parameter: oid"]
            }
            return getDisplayItemDetails(oid: oid)
            
        case "search_ui_elements":
            let className = parameters?["className"] as? String
            let title = parameters?["title"] as? String
            return searchUIElements(className: className, title: title)
            
        case "analyze_layout":
            return analyzeLayout()
            
        default:
            return ["error": "Unknown tool: \(name)"]
        }
    }
}

#endif
