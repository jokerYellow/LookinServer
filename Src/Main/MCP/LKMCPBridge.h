#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LKMCPBridge.h
//  LookinServer
//
//  Created by MCP Integration
//  https://lookin.work
//

#import <Foundation/Foundation.h>

@class LookinHierarchyInfo, LookinDisplayItem, LookinDisplayItemDetail;

NS_ASSUME_NONNULL_BEGIN

/**
 * Bridge layer that connects MCP Server to LookinServer data sources.
 * Provides access to UI hierarchy information for MCP tools.
 */
@interface LKMCPBridge : NSObject

+ (instancetype)sharedInstance;

/**
 * Get the current UI hierarchy information
 * @return LookinHierarchyInfo containing the complete UI tree
 */
- (nullable LookinHierarchyInfo *)getCurrentHierarchy;

/**
 * Get detailed information for a specific display item
 * @param oid The object identifier of the display item
 * @return LookinDisplayItemDetail with full details, or nil if not found
 */
- (nullable LookinDisplayItemDetail *)getDisplayItemDetails:(unsigned long)oid;

/**
 * Find a display item by its object identifier
 * @param oid The object identifier
 * @param items The array of items to search in
 * @return The found display item, or nil
 */
- (nullable LookinDisplayItem *)findDisplayItemWithOid:(unsigned long)oid 
                                               inItems:(NSArray<LookinDisplayItem *> *)items;

/**
 * Search for display items matching given criteria
 * @param className Optional class name to filter by
 * @param title Optional title/text to search for
 * @return Array of matching display items
 */
- (NSArray<LookinDisplayItem *> *)searchDisplayItemsWithClassName:(nullable NSString *)className
                                                            title:(nullable NSString *)title;

/**
 * Get all display items as a flat array
 * @return Flattened array of all display items
 */
- (NSArray<LookinDisplayItem *> *)getAllDisplayItemsFlat;

/**
 * Analyze layout for potential issues (overlapping, out of bounds, etc.)
 * @return Dictionary with analysis results
 */
- (NSDictionary *)analyzeLayoutIssues;

@end

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
