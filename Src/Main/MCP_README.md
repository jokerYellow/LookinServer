# MCP Integration for LookinServer

## Overview

This module provides a Model Context Protocol (MCP) integration for LookinServer, enabling AI assistants like Claude to query and analyze UI hierarchy information in iOS applications.

## Architecture

```
┌─────────────────────────┐
│   AI Assistant (Claude) │
└───────────┬─────────────┘
            │ MCP Protocol
┌───────────▼─────────────┐
│   LKMCPServer (Swift)   │
│  - Tools Registration   │
│  - Tool Execution       │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│ LKMCPBridge (ObjC)      │
│  - Data Access Layer    │
│  - Hierarchy Fetching   │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│ LKMCPDataFormatter      │
│  - JSON Serialization   │
└───────────┬─────────────┘
            │
┌───────────▼─────────────┐
│ LookinServer Core       │
│  - Hierarchy Data       │
│  - DisplayItem Models   │
└─────────────────────────┘
```

## Available MCP Tools

### 1. get_ui_hierarchy

Get the complete UI hierarchy tree structure.

**Parameters:** None

**Returns:**
```json
{
  "items": [...],
  "itemCount": 123,
  "appInfo": {
    "appName": "MyApp",
    "appVersion": "1.0.0",
    "deviceModel": "iPhone 14 Pro",
    "systemVersion": "iOS 16.0"
  },
  "serverVersion": 7
}
```

### 2. get_display_item_details

Get detailed information for a specific UI element.

**Parameters:**
- `oid` (integer, required): The object identifier of the display item

**Returns:**
```json
{
  "oid": 12345,
  "frame": {
    "x": 0,
    "y": 0,
    "width": 375,
    "height": 812
  },
  "bounds": {...},
  "isHidden": false,
  "alpha": 1.0,
  "customTitle": "Main View",
  "attributes": [...],
  "subitems": [...]
}
```

### 3. search_ui_elements

Search for UI elements matching given criteria.

**Parameters:**
- `className` (string, optional): Class name to filter by (case-insensitive)
- `title` (string, optional): Title/text to search for (case-insensitive)

**Returns:**
```json
{
  "results": [
    {
      "object": {
        "oid": 12345,
        "className": "UIButton",
        "memoryAddress": "0x1234567890"
      },
      "frame": {...},
      "customTitle": "Login Button",
      ...
    }
  ],
  "count": 5,
  "query": {
    "className": "UIButton",
    "title": "Login"
  }
}
```

### 4. analyze_layout

Analyze the UI layout for potential issues.

**Parameters:** None

**Returns:**
```json
{
  "totalItems": 123,
  "issuesFound": 15,
  "hiddenItems": [
    {
      "oid": 12345,
      "className": "UILabel",
      "reason": "alpha = 0"
    }
  ],
  "outOfBoundsItems": [
    {
      "oid": 67890,
      "className": "UIView",
      "frame": "{0, 0, 100, 100}",
      "parentBounds": "{0, 0, 50, 50}"
    }
  ],
  "overlappingItems": [
    {
      "item1": {...},
      "item2": {...}
    }
  ]
}
```

## Usage

### Starting the MCP Server

```swift
import LookinServer

// Start the MCP server
LKMCPServer.shared.start()

// Check if running
if LKMCPServer.shared.running {
    print("MCP Server is running")
}

// Get available tools
let tools = LKMCPServer.shared.getAvailableTools()
print("Available tools: \(tools)")
```

### Using MCP Tools

```swift
// Get UI hierarchy
let hierarchy = LKMCPServer.shared.getUIHierarchy()
print("Total items: \(hierarchy["itemCount"] ?? 0)")

// Get details for a specific item
let details = LKMCPServer.shared.getDisplayItemDetails(oid: 12345)
print("Item details: \(details)")

// Search for UI elements
let searchResults = LKMCPServer.shared.searchUIElements(
    className: "UIButton",
    title: "Login"
)
print("Found \(searchResults["count"] ?? 0) items")

// Analyze layout
let analysis = LKMCPServer.shared.analyzeLayout()
print("Issues found: \(analysis["issuesFound"] ?? 0)")

// Execute tool by name
let result = LKMCPServer.shared.executeTool(
    name: "get_ui_hierarchy",
    parameters: nil
)
```

### Stopping the Server

```swift
LKMCPServer.shared.stop()
```

## Integration with AI Assistants

AI assistants can use these tools to:

1. **Inspect UI Structure**: Get complete view hierarchy to understand app layout
2. **Debug Layout Issues**: Find overlapping views, hidden elements, or out-of-bounds items
3. **Search for Elements**: Locate specific UI components by class or title
4. **Analyze Performance**: Identify potential UI performance issues
5. **Generate Documentation**: Create UI structure documentation automatically

## Example Queries for AI

**Q: "Show me all UIButtons in the app"**
```
Use search_ui_elements with className="UIButton"
```

**Q: "Are there any views outside their parent bounds?"**
```
Use analyze_layout and check outOfBoundsItems
```

**Q: "What's the hierarchy structure of the current screen?"**
```
Use get_ui_hierarchy to get the complete tree
```

**Q: "Give me details about view with oid 12345"**
```
Use get_display_item_details with oid=12345
```

## File Structure

- `LKMCPServer.swift` - Main MCP server with tool implementations
- `LKMCPBridge.h/m` - Objective-C bridge to access LookinServer data
- `LKMCPDataFormatter.swift` - JSON formatting utilities

## Requirements

- iOS 9.0+
- Swift 5.3+
- LookinServer 1.2.8+

## Notes

- The MCP server only works in Debug builds (controlled by `SHOULD_COMPILE_LOOKIN_SERVER`)
- Screenshot capture is disabled by default for performance
- Hierarchy data is cached and refreshed on each tool call
- All coordinates are in the iOS coordinate system (top-left origin)

## Future Enhancements

- Real-time hierarchy updates via notifications
- Screenshot capture for specific items
- Ability to modify UI properties via MCP
- Performance metrics and profiling
- Support for SwiftUI view hierarchy
