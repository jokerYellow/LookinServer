# MCP Integration - Usage Examples

## Quick Start

### 1. Start the MCP Server

In your iOS app's debug configuration, start the MCP server when the app launches:

```swift
import LookinServer

// In AppDelegate or SceneDelegate
func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    #if DEBUG
    // Start MCP server for AI-assisted debugging
    LKMCPServer.shared.start()
    print("MCP Server started - AI assistants can now query UI hierarchy")
    #endif
    
    return true
}
```

### 2. Query UI Hierarchy

AI assistants can now query your app's UI structure:

```swift
// Get complete UI hierarchy
let hierarchy = LKMCPServer.shared.getUIHierarchy()
print("Total UI elements: \(hierarchy["itemCount"] ?? 0)")

// Example output:
// {
//   "itemCount": 47,
//   "items": [
//     {
//       "object": {
//         "oid": 140703358271264,
//         "className": "UIWindow",
//         "memoryAddress": "0x7ff9d2c0d4a0"
//       },
//       "frame": {"x": 0, "y": 0, "width": 393, "height": 852},
//       "isHidden": false,
//       "alpha": 1.0,
//       "subitemCount": 3
//     }
//   ]
// }
```

### 3. Search for Specific Elements

```swift
// Find all buttons
let buttons = LKMCPServer.shared.searchUIElements(
    className: "UIButton",
    title: nil
)

print("Found \(buttons["count"] ?? 0) buttons")

// Find login button specifically
let loginButton = LKMCPServer.shared.searchUIElements(
    className: "UIButton",
    title: "Login"
)
```

### 4. Get Element Details

```swift
// Get detailed info for a specific element
let oid: UInt = 140703358271264
let details = LKMCPServer.shared.getDisplayItemDetails(oid: oid)

print("Element details: \(details)")

// Example output:
// {
//   "oid": 140703358271264,
//   "frame": {"x": 50, "y": 100, "width": 200, "height": 44},
//   "isHidden": false,
//   "alpha": 1.0,
//   "customTitle": "Login Button",
//   "attributes": [...]
// }
```

### 5. Analyze Layout Issues

```swift
// Check for common layout problems
let analysis = LKMCPServer.shared.analyzeLayout()

print("Total issues found: \(analysis["issuesFound"] ?? 0)")
print("Hidden items: \(analysis["hiddenItems"] ?? [])")
print("Out of bounds: \(analysis["outOfBoundsItems"] ?? [])")
print("Overlapping: \(analysis["overlappingItems"] ?? [])")
```

## AI Assistant Integration Examples

### Example 1: Debugging Invisible Button

**User:** "My submit button isn't showing up"

**AI Assistant:**
```
1. Search for button: search_ui_elements(title="submit")
2. Check if found: Result shows button exists with oid=12345
3. Get details: get_display_item_details(oid=12345)
4. Analyze: Button has alpha=0 (invisible)
5. Suggest: Set button.alpha = 1.0
```

### Example 2: Layout Validation

**User:** "Check if all buttons are properly sized for touch targets"

**AI Assistant:**
```
1. Find buttons: search_ui_elements(className="UIButton")
2. For each button:
   - Get details: get_display_item_details(oid=...)
   - Check frame.width >= 44 and frame.height >= 44
3. Report buttons that are too small
```

### Example 3: Accessibility Audit

**User:** "Generate accessibility report"

**AI Assistant:**
```
1. Get hierarchy: get_ui_hierarchy()
2. For each interactive element:
   - Check for accessibility label
   - Verify minimum touch target size
   - Check color contrast
3. Generate comprehensive report
```

### Example 4: Performance Analysis

**User:** "Find performance issues in my UI"

**AI Assistant:**
```
1. Analyze layout: analyze_layout()
2. Check for:
   - Hidden views being rendered
   - Excessive view hierarchy depth
   - Overlapping transparent views
   - Out-of-bounds rendering
3. Suggest optimizations
```

## Advanced Usage

### Custom Tool Execution

```swift
// Execute any tool by name
let result = LKMCPServer.shared.executeTool(
    name: "get_ui_hierarchy",
    parameters: nil
)

// With parameters
let result2 = LKMCPServer.shared.executeTool(
    name: "search_ui_elements",
    parameters: [
        "className": "UIButton",
        "title": "Submit"
    ]
)
```

### List Available Tools

```swift
let tools = LKMCPServer.shared.getAvailableTools()
for tool in tools {
    if let toolDict = tool as? [String: Any] {
        print("Tool: \(toolDict["name"] ?? "")")
        print("Description: \(toolDict["description"] ?? "")")
        print("Parameters: \(toolDict["parameters"] ?? [])")
        print("---")
    }
}
```

### Server Lifecycle

```swift
// Check if server is running
if LKMCPServer.shared.running {
    print("MCP Server is active")
}

// Stop server when done
LKMCPServer.shared.stop()

// Restart server
LKMCPServer.shared.start()
```

## Integration with Popular AI Assistants

### Claude Desktop

Configure Claude to use Lookin MCP server:

```json
{
  "mcpServers": {
    "lookin": {
      "command": "lookin-mcp-server",
      "args": ["--port", "47175"]
    }
  }
}
```

### Custom MCP Client

```python
import json
import requests

class LookinMCPClient:
    def __init__(self, host="localhost", port=47175):
        self.base_url = f"http://{host}:{port}"
    
    def get_hierarchy(self):
        response = requests.post(
            f"{self.base_url}/tools/get_ui_hierarchy",
            json={}
        )
        return response.json()
    
    def search_elements(self, class_name=None, title=None):
        response = requests.post(
            f"{self.base_url}/tools/search_ui_elements",
            json={
                "className": class_name,
                "title": title
            }
        )
        return response.json()

# Usage
client = LookinMCPClient()
hierarchy = client.get_hierarchy()
print(f"Total items: {hierarchy['itemCount']}")
```

## Tips & Best Practices

1. **Performance**: MCP queries are lightweight but avoid excessive polling
2. **Caching**: Hierarchy data is cached - call `getUIHierarchy()` to refresh
3. **Debug Only**: MCP server only runs in Debug builds
4. **Security**: Server listens on localhost only by default
5. **Thread Safety**: All MCP APIs are thread-safe

## Troubleshooting

### Server Not Starting

```swift
// Check if server is running
if !LKMCPServer.shared.running {
    print("Server failed to start")
    // Check console for error messages
}
```

### No Data Returned

```swift
let hierarchy = LKMCPServer.shared.getUIHierarchy()
if hierarchy["error"] != nil {
    print("Error: \(hierarchy["error"]!)")
}
```

### Element Not Found

```swift
let details = LKMCPServer.shared.getDisplayItemDetails(oid: 12345)
if details["error"] != nil {
    print("Element not found or invalid OID")
}
```

## Further Reading

- [MCP Integration README](MCP_README.md)
- [Feature Request Document](../MCP_FEATURE_REQUEST.md)
- [LookinServer Documentation](https://lookin.work)
- [Model Context Protocol Spec](https://modelcontextprotocol.io)
