#if SHOULD_COMPILE_LOOKIN_SERVER && DEBUG

//
//  LKMCPIntegrationTests.swift
//  LookinServer
//
//  Created by MCP Integration
//  https://lookin.work
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Integration tests for MCP Server
/// These tests demonstrate how to use the MCP tools and validate their functionality
@objc public class LKMCPIntegrationTests: NSObject {
    
    /// Run all integration tests
    @objc public static func runAllTests() {
        print("=== Running MCP Integration Tests ===\n")
        
        testServerLifecycle()
        testGetHierarchy()
        testSearchElements()
        testGetDetails()
        testAnalyzeLayout()
        testToolExecution()
        
        print("\n=== All Tests Completed ===")
    }
    
    // MARK: - Test Cases
    
    static func testServerLifecycle() {
        print("Test: Server Lifecycle")
        
        let server = LKMCPServer.shared
        
        // Test start
        server.start()
        assert(server.running, "Server should be running after start()")
        print("✓ Server started successfully")
        
        // Test stop
        server.stop()
        assert(!server.running, "Server should not be running after stop()")
        print("✓ Server stopped successfully")
        
        // Restart for other tests
        server.start()
        print("✓ Server lifecycle test passed\n")
    }
    
    static func testGetHierarchy() {
        print("Test: Get UI Hierarchy")
        
        let server = LKMCPServer.shared
        let result = server.getUIHierarchy()
        
        // Validate result structure
        assert(result["error"] == nil, "Should not have error")
        
        if let itemCount = result["itemCount"] as? Int {
            print("✓ Found \(itemCount) UI items in hierarchy")
        }
        
        if let items = result["items"] as? [[String: Any]] {
            print("✓ Hierarchy contains \(items.count) top-level items")
            
            // Validate first item structure
            if let firstItem = items.first {
                if let object = firstItem["object"] as? [String: Any] {
                    print("  - First item class: \(object["className"] ?? "Unknown")")
                    print("  - First item OID: \(object["oid"] ?? 0)")
                }
            }
        }
        
        if let appInfo = result["appInfo"] as? [String: Any] {
            print("✓ App info included:")
            print("  - App name: \(appInfo["appName"] ?? "Unknown")")
            print("  - Device: \(appInfo["deviceModel"] ?? "Unknown")")
        }
        
        print("✓ Get hierarchy test passed\n")
    }
    
    static func testSearchElements() {
        print("Test: Search UI Elements")
        
        let server = LKMCPServer.shared
        
        // Search by class name
        let buttonSearch = server.searchUIElements(className: "UIButton", title: nil)
        if let count = buttonSearch["count"] as? Int {
            print("✓ Found \(count) UIButton elements")
        }
        
        // Search by title
        let titleSearch = server.searchUIElements(className: nil, title: "Test")
        if let count = titleSearch["count"] as? Int {
            print("✓ Found \(count) elements with 'Test' in title")
        }
        
        // Combined search
        let combinedSearch = server.searchUIElements(className: "UILabel", title: "Login")
        if let count = combinedSearch["count"] as? Int {
            print("✓ Found \(count) UILabel elements with 'Login' in title")
        }
        
        // Validate result structure
        assert(buttonSearch["error"] == nil, "Search should not have error")
        assert(buttonSearch["results"] != nil, "Search should return results array")
        assert(buttonSearch["count"] != nil, "Search should return count")
        
        print("✓ Search elements test passed\n")
    }
    
    static func testGetDetails() {
        print("Test: Get Display Item Details")
        
        let server = LKMCPServer.shared
        
        // First get hierarchy to find an OID
        let hierarchy = server.getUIHierarchy()
        
        if let items = hierarchy["items"] as? [[String: Any]],
           let firstItem = items.first,
           let object = firstItem["object"] as? [String: Any],
           let oid = object["oid"] as? UInt {
            
            // Get details for this item
            let details = server.getDisplayItemDetails(oid: oid)
            
            // Validate details
            if details["error"] == nil {
                print("✓ Successfully retrieved details for OID: \(oid)")
                
                if let frame = details["frame"] as? [String: Any] {
                    print("  - Frame: x=\(frame["x"] ?? 0), y=\(frame["y"] ?? 0), " +
                          "w=\(frame["width"] ?? 0), h=\(frame["height"] ?? 0)")
                }
                
                if let alpha = details["alpha"] as? Float {
                    print("  - Alpha: \(alpha)")
                }
                
                if let hidden = details["isHidden"] as? Bool {
                    print("  - Hidden: \(hidden)")
                }
            } else {
                print("⚠ Could not get details (item may not exist anymore)")
            }
        }
        
        // Test invalid OID
        let invalidDetails = server.getDisplayItemDetails(oid: 0)
        assert(invalidDetails["error"] != nil, "Invalid OID should return error")
        print("✓ Invalid OID properly handled")
        
        print("✓ Get details test passed\n")
    }
    
    static func testAnalyzeLayout() {
        print("Test: Analyze Layout")
        
        let server = LKMCPServer.shared
        let analysis = server.analyzeLayout()
        
        // Validate analysis structure
        assert(analysis["error"] == nil, "Analysis should not have error")
        
        if let totalItems = analysis["totalItems"] as? Int {
            print("✓ Analyzed \(totalItems) total items")
        }
        
        if let issuesFound = analysis["issuesFound"] as? Int {
            print("✓ Found \(issuesFound) layout issues")
        }
        
        if let hiddenItems = analysis["hiddenItems"] as? [[String: Any]] {
            print("  - Hidden items: \(hiddenItems.count)")
        }
        
        if let outOfBounds = analysis["outOfBoundsItems"] as? [[String: Any]] {
            print("  - Out of bounds: \(outOfBounds.count)")
        }
        
        if let overlapping = analysis["overlappingItems"] as? [[String: Any]] {
            print("  - Overlapping: \(overlapping.count)")
        }
        
        print("✓ Analyze layout test passed\n")
    }
    
    static func testToolExecution() {
        print("Test: Tool Execution API")
        
        let server = LKMCPServer.shared
        
        // Test get_ui_hierarchy tool
        let hierarchyResult = server.executeTool(name: "get_ui_hierarchy", parameters: nil)
        assert(hierarchyResult["error"] == nil, "Hierarchy tool should work")
        print("✓ get_ui_hierarchy tool executed")
        
        // Test search_ui_elements tool
        let searchResult = server.executeTool(
            name: "search_ui_elements",
            parameters: ["className": "UIButton"]
        )
        assert(searchResult["error"] == nil, "Search tool should work")
        print("✓ search_ui_elements tool executed")
        
        // Test analyze_layout tool
        let analysisResult = server.executeTool(name: "analyze_layout", parameters: nil)
        assert(analysisResult["error"] == nil, "Analysis tool should work")
        print("✓ analyze_layout tool executed")
        
        // Test invalid tool
        let invalidResult = server.executeTool(name: "invalid_tool", parameters: nil)
        assert(invalidResult["error"] != nil, "Invalid tool should return error")
        print("✓ Invalid tool properly handled")
        
        // Test available tools
        let tools = server.getAvailableTools()
        assert(tools.count > 0, "Should have available tools")
        print("✓ Found \(tools.count) available tools")
        
        print("✓ Tool execution test passed\n")
    }
}

#endif
