#ifdef SHOULD_COMPILE_LOOKIN_SERVER

//
//  LKMCPBridge.m
//  LookinServer
//
//  Created by MCP Integration
//  https://lookin.work
//

#import "LKMCPBridge.h"
#import "LookinHierarchyInfo.h"
#import "LookinDisplayItem.h"
#import "LookinDisplayItemDetail.h"
#import "LookinObject.h"
#import "LKS_HierarchyDisplayItemsMaker.h"
#import "NSArray+Lookin.h"

@interface LKMCPBridge()

@property (nonatomic, strong) LookinHierarchyInfo *cachedHierarchy;

@end

@implementation LKMCPBridge

+ (instancetype)sharedInstance {
    static LKMCPBridge *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LKMCPBridge alloc] init];
    });
    return instance;
}

- (nullable LookinHierarchyInfo *)getCurrentHierarchy {
#if TARGET_OS_IPHONE
    // Get fresh hierarchy with basic info (no screenshots for performance)
    LookinHierarchyInfo *info = [LookinHierarchyInfo staticInfoWithLookinVersion:@"1.0.4"];
    self.cachedHierarchy = info;
    return info;
#else
    return nil;
#endif
}

- (nullable LookinDisplayItemDetail *)getDisplayItemDetails:(unsigned long)oid {
    if (!self.cachedHierarchy) {
        [self getCurrentHierarchy];
    }
    
    if (!self.cachedHierarchy) {
        return nil;
    }
    
    // Find the display item
    LookinDisplayItem *item = [self findDisplayItemWithOid:oid inItems:self.cachedHierarchy.displayItems];
    if (!item) {
        return nil;
    }
    
    // Create detail object
    LookinDisplayItemDetail *detail = [[LookinDisplayItemDetail alloc] init];
    detail.displayItemOid = oid;
    detail.frameValue = [NSValue valueWithCGRect:item.frame];
    detail.boundsValue = [NSValue valueWithCGRect:item.bounds];
    detail.hiddenValue = @(item.isHidden);
    detail.alphaValue = @(item.alpha);
    detail.customDisplayTitle = item.customDisplayTitle;
    detail.attributesGroupList = item.attributesGroupList;
    detail.customAttrGroupList = item.customAttrGroupList;
    detail.subitems = item.subitems;
    
    return detail;
}

- (nullable LookinDisplayItem *)findDisplayItemWithOid:(unsigned long)oid 
                                               inItems:(NSArray<LookinDisplayItem *> *)items {
    for (LookinDisplayItem *item in items) {
        LookinObject *obj = [item displayingObject];
        if (obj && obj.oid == oid) {
            return item;
        }
        
        // Recursively search in subitems
        if (item.subitems.count > 0) {
            LookinDisplayItem *found = [self findDisplayItemWithOid:oid inItems:item.subitems];
            if (found) {
                return found;
            }
        }
    }
    return nil;
}

- (NSArray<LookinDisplayItem *> *)searchDisplayItemsWithClassName:(nullable NSString *)className
                                                            title:(nullable NSString *)title {
    if (!self.cachedHierarchy) {
        [self getCurrentHierarchy];
    }
    
    if (!self.cachedHierarchy) {
        return @[];
    }
    
    NSArray<LookinDisplayItem *> *allItems = [self getAllDisplayItemsFlat];
    NSMutableArray<LookinDisplayItem *> *results = [NSMutableArray array];
    
    for (LookinDisplayItem *item in allItems) {
        BOOL matches = YES;
        
        // Filter by class name if provided
        if (className && className.length > 0) {
            LookinObject *obj = [item displayingObject];
            if (obj && obj.className) {
                if ([obj.className rangeOfString:className options:NSCaseInsensitiveSearch].location == NSNotFound) {
                    matches = NO;
                }
            } else {
                matches = NO;
            }
        }
        
        // Filter by title if provided
        if (matches && title && title.length > 0) {
            if (item.customDisplayTitle) {
                if ([item.customDisplayTitle rangeOfString:title options:NSCaseInsensitiveSearch].location == NSNotFound) {
                    matches = NO;
                }
            } else {
                matches = NO;
            }
        }
        
        if (matches) {
            [results addObject:item];
        }
    }
    
    return results;
}

- (NSArray<LookinDisplayItem *> *)getAllDisplayItemsFlat {
    if (!self.cachedHierarchy) {
        [self getCurrentHierarchy];
    }
    
    if (!self.cachedHierarchy) {
        return @[];
    }
    
    return [LookinDisplayItem flatItemsFromHierarchicalItems:self.cachedHierarchy.displayItems];
}

- (NSDictionary *)analyzeLayoutIssues {
    NSMutableDictionary *analysis = [NSMutableDictionary dictionary];
    NSMutableArray *overlappingItems = [NSMutableArray array];
    NSMutableArray *outOfBoundsItems = [NSMutableArray array];
    NSMutableArray *hiddenItems = [NSMutableArray array];
    
    NSArray<LookinDisplayItem *> *allItems = [self getAllDisplayItemsFlat];
    
    for (LookinDisplayItem *item in allItems) {
        // Check for hidden items
        if (item.inHiddenHierarchy) {
            LookinObject *obj = [item displayingObject];
            if (obj) {
                [hiddenItems addObject:@{
                    @"oid": @(obj.oid),
                    @"className": obj.className ?: @"Unknown",
                    @"reason": item.isHidden ? @"hidden property" : @"alpha = 0"
                }];
            }
        }
        
        // Check for items outside parent bounds
        if (item.superItem) {
            CGRect itemFrame = item.frame;
            CGRect parentBounds = item.superItem.bounds;
            
            if (!CGRectContainsRect(parentBounds, itemFrame)) {
                LookinObject *obj = [item displayingObject];
                if (obj) {
                    [outOfBoundsItems addObject:@{
                        @"oid": @(obj.oid),
                        @"className": obj.className ?: @"Unknown",
                        @"frame": NSStringFromCGRect(itemFrame),
                        @"parentBounds": NSStringFromCGRect(parentBounds)
                    }];
                }
            }
        }
        
        // Check for overlapping siblings
        if (item.superItem && item.superItem.subitems.count > 1) {
            for (LookinDisplayItem *sibling in item.superItem.subitems) {
                if (sibling == item) continue;
                
                if (CGRectIntersectsRect(item.frame, sibling.frame)) {
                    LookinObject *obj1 = [item displayingObject];
                    LookinObject *obj2 = [sibling displayingObject];
                    
                    if (obj1 && obj2 && obj1.oid < obj2.oid) { // Avoid duplicates
                        [overlappingItems addObject:@{
                            @"item1": @{
                                @"oid": @(obj1.oid),
                                @"className": obj1.className ?: @"Unknown",
                                @"frame": NSStringFromCGRect(item.frame)
                            },
                            @"item2": @{
                                @"oid": @(obj2.oid),
                                @"className": obj2.className ?: @"Unknown",
                                @"frame": NSStringFromCGRect(sibling.frame)
                            }
                        }];
                    }
                }
            }
        }
    }
    
    analysis[@"totalItems"] = @(allItems.count);
    analysis[@"hiddenItems"] = hiddenItems;
    analysis[@"outOfBoundsItems"] = outOfBoundsItems;
    analysis[@"overlappingItems"] = overlappingItems;
    analysis[@"issuesFound"] = @(hiddenItems.count + outOfBoundsItems.count + overlappingItems.count);
    
    return analysis;
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
