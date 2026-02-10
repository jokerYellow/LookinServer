# MCP Integration Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AI Assistant                              │
│                    (Claude, GPT-4, etc.)                         │
│                                                                   │
│  Queries:                                                        │
│  - "Show me all UIButtons"                                       │
│  - "Why is my login button not visible?"                        │
│  - "Check for accessibility issues"                             │
│  - "Find layout performance problems"                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ MCP Protocol (JSON-RPC)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LKMCPServer.swift                           │
│                                                                   │
│  Tools:                                                          │
│  ├─ get_ui_hierarchy()         → Full UI tree                   │
│  ├─ get_display_item_details() → Specific element info          │
│  ├─ search_ui_elements()       → Find matching elements         │
│  └─ analyze_layout()           → Detect issues                  │
│                                                                   │
│  Features:                                                       │
│  • Tool registration & discovery                                │
│  • Request validation & routing                                 │
│  • Response formatting                                          │
│  • Error handling                                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Objective-C Bridge
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LKMCPBridge.h/.m                              │
│                                                                   │
│  Responsibilities:                                               │
│  ├─ getCurrentHierarchy()                                       │
│  ├─ getDisplayItemDetails(oid)                                  │
│  ├─ searchDisplayItemsWithClassName:title:                      │
│  ├─ analyzeLayoutIssues()                                       │
│  └─ findDisplayItemWithOid:inItems:                            │
│                                                                   │
│  Features:                                                       │
│  • Access to LookinServer data sources                         │
│  • Hierarchy traversal & search                                │
│  • Layout validation & analysis                                │
│  • Caching for performance                                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Data Formatting
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  LKMCPDataFormatter.swift                        │
│                                                                   │
│  Formatters:                                                     │
│  ├─ formatHierarchyInfo()      → JSON tree                      │
│  ├─ formatDisplayItem()        → JSON object                    │
│  ├─ formatDisplayItemDetail()  → Detailed JSON                  │
│  └─ formatAttributeGroup()     → Attribute JSON                 │
│                                                                   │
│  Features:                                                       │
│  • Objective-C to JSON conversion                              │
│  • Recursive hierarchy formatting                              │
│  • Type-safe serialization                                     │
│  • Attribute extraction                                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Uses Existing APIs
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   LookinServer Core                              │
│                                                                   │
│  Data Sources:                                                   │
│  ├─ LookinHierarchyInfo        → Hierarchy tree                 │
│  ├─ LookinDisplayItem          → UI element data                │
│  ├─ LookinDisplayItemDetail    → Detailed properties            │
│  ├─ LookinObject               → Object metadata                │
│  ├─ LookinAttributesGroup      → Attribute groups               │
│  └─ LKS_HierarchyDisplayItemsMaker → Build hierarchy            │
│                                                                   │
│  Features:                                                       │
│  • UI hierarchy capture                                         │
│  • Display item management                                      │
│  • Attribute extraction                                         │
│  • Screenshot generation                                        │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Example: AI searches for all UIButtons

```
1. AI Request:
   ┌──────────────────────────────────────┐
   │ search_ui_elements(                  │
   │   className: "UIButton",             │
   │   title: nil                         │
   │ )                                    │
   └──────────┬───────────────────────────┘
              │
              ▼
2. LKMCPServer validates and routes:
   ┌──────────────────────────────────────┐
   │ executeTool(                         │
   │   name: "search_ui_elements",        │
   │   parameters: {...}                  │
   │ )                                    │
   └──────────┬───────────────────────────┘
              │
              ▼
3. LKMCPBridge performs search:
   ┌──────────────────────────────────────┐
   │ searchDisplayItemsWithClassName:     │
   │   title:                             │
   │                                      │
   │ • Gets current hierarchy             │
   │ • Flattens to array                  │
   │ • Filters by className               │
   │ • Returns matching items             │
   └──────────┬───────────────────────────┘
              │
              ▼
4. LKMCPDataFormatter formats results:
   ┌──────────────────────────────────────┐
   │ formatDisplayItem() for each match   │
   │                                      │
   │ • Extracts object info (oid, class)  │
   │ • Formats frame & bounds             │
   │ • Includes attributes                │
   │ • Adds subitems if any              │
   └──────────┬───────────────────────────┘
              │
              ▼
5. Response to AI:
   ┌──────────────────────────────────────┐
   │ {                                    │
   │   "results": [                       │
   │     {                                │
   │       "object": {                    │
   │         "oid": 12345,                │
   │         "className": "UIButton"      │
   │       },                             │
   │       "frame": {...},                │
   │       "customTitle": "Login"         │
   │     }                                │
   │   ],                                 │
   │   "count": 5                         │
   │ }                                    │
   └──────────────────────────────────────┘
```

## Component Interaction

```
┌────────────┐     uses      ┌────────────┐
│ MCP Server │ ─────────────▶ │   Bridge   │
└────────────┘                └─────┬──────┘
      │                             │
      │ uses                        │ accesses
      │                             │
      ▼                             ▼
┌────────────┐               ┌────────────┐
│ Formatter  │               │ Lookin Core│
└────────────┘               └────────────┘
```

## File Organization

```
LookinServer/
├── Src/
│   ├── Main/
│   │   ├── MCP/
│   │   │   ├── LKMCPBridge.h        (Bridge header)
│   │   │   └── LKMCPBridge.m        (Bridge implementation)
│   │   ├── MCP_README.md            (Documentation)
│   │   └── Server/...               (Existing server code)
│   │
│   └── Swift/
│       ├── LKMCPServer.swift        (MCP server)
│       ├── LKMCPDataFormatter.swift (JSON formatter)
│       └── LKMCPIntegrationTests.swift (Tests)
│
├── MCP_USAGE_EXAMPLES.md            (Usage guide)
├── MCP_FEATURE_REQUEST.md           (Proposal)
├── MCP_IMPLEMENTATION_SUMMARY.md    (Overview)
└── GITHUB_ISSUE_TEMPLATE.md         (Issue template)
```

## Security Model

```
┌─────────────────────────────────────────┐
│          Build Configuration             │
├─────────────────────────────────────────┤
│                                          │
│  Debug Build:                            │
│  ├─ SHOULD_COMPILE_LOOKIN_SERVER = 1    │
│  ├─ MCP Server: ✅ Enabled               │
│  └─ Lookin: ✅ Enabled                   │
│                                          │
│  Release Build:                          │
│  ├─ SHOULD_COMPILE_LOOKIN_SERVER = 0    │
│  ├─ MCP Server: ❌ Disabled              │
│  └─ Lookin: ❌ Disabled                  │
│                                          │
└─────────────────────────────────────────┘
```

## Performance Characteristics

```
Operation                  | Performance     | Caching
──────────────────────────┼─────────────────┼─────────
get_ui_hierarchy()        | ~50-100ms       | Yes*
get_display_item_details()| ~1-5ms          | No
search_ui_elements()      | ~10-50ms        | Uses cached
analyze_layout()          | ~20-100ms       | Uses cached

* Hierarchy is cached until next call to getCurrentHierarchy()
```

## Error Handling

```
┌─────────────────┐
│   AI Request    │
└────────┬────────┘
         │
         ▼
    ┌────────┐ No  ┌──────────────┐
    │ Valid? │────▶│ Return Error │
    └───┬────┘     └──────────────┘
        │ Yes
        ▼
    ┌────────┐ No  ┌──────────────┐
    │ Bridge │────▶│ Return Error │
    │  OK?   │     └──────────────┘
    └───┬────┘
        │ Yes
        ▼
    ┌────────┐ No  ┌──────────────┐
    │ Data   │────▶│ Return Error │
    │ Found? │     └──────────────┘
    └───┬────┘
        │ Yes
        ▼
    ┌────────┐
    │ Format │
    │   &    │
    │ Return │
    └────────┘
```
