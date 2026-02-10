#if SHOULD_COMPILE_LOOKIN_SERVER

//
//  LKMCPDataFormatter.swift
//  LookinServer
//
//  Created by MCP Integration
//  https://lookin.work
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Formats LookinServer data structures into JSON for MCP responses
@objc public class LKMCPDataFormatter: NSObject {
    
    /// Format a LookinHierarchyInfo into JSON dictionary
    @objc public static func formatHierarchyInfo(_ info: Any?) -> [String: Any] {
        guard let hierarchyInfo = info as? NSObject else {
            return ["error": "Invalid hierarchy info"]
        }
        
        var result: [String: Any] = [:]
        
        // Extract display items
        if let displayItems = hierarchyInfo.value(forKey: "displayItems") as? [Any] {
            result["items"] = displayItems.map { formatDisplayItem($0) }
            result["itemCount"] = displayItems.count
        }
        
        // Extract app info
        if let appInfo = hierarchyInfo.value(forKey: "appInfo") as? NSObject {
            result["appInfo"] = formatAppInfo(appInfo)
        }
        
        // Extract server version
        if let serverVersion = hierarchyInfo.value(forKey: "serverVersion") as? Int {
            result["serverVersion"] = serverVersion
        }
        
        return result
    }
    
    /// Format a LookinDisplayItem into JSON dictionary
    @objc public static func formatDisplayItem(_ item: Any?) -> [String: Any] {
        guard let displayItem = item as? NSObject else {
            return ["error": "Invalid display item"]
        }
        
        var result: [String: Any] = [:]
        
        // Extract object info
        if let viewObject = displayItem.value(forKey: "viewObject") as? NSObject {
            result["object"] = formatLookinObject(viewObject)
        } else if let layerObject = displayItem.value(forKey: "layerObject") as? NSObject {
            result["object"] = formatLookinObject(layerObject)
        }
        
        // Extract basic properties
        if let isHidden = displayItem.value(forKey: "isHidden") as? Bool {
            result["isHidden"] = isHidden
        }
        
        if let alpha = displayItem.value(forKey: "alpha") as? Float {
            result["alpha"] = alpha
        }
        
        // Extract frame and bounds
        #if canImport(UIKit)
        if let frameValue = displayItem.value(forKey: "frame") {
            let frame = (frameValue as? NSValue)?.cgRectValue ?? .zero
            result["frame"] = [
                "x": frame.origin.x,
                "y": frame.origin.y,
                "width": frame.size.width,
                "height": frame.size.height
            ]
        }
        
        if let boundsValue = displayItem.value(forKey: "bounds") {
            let bounds = (boundsValue as? NSValue)?.cgRectValue ?? .zero
            result["bounds"] = [
                "x": bounds.origin.x,
                "y": bounds.origin.y,
                "width": bounds.size.width,
                "height": bounds.size.height
            ]
        }
        #endif
        
        // Extract custom title
        if let customTitle = displayItem.value(forKey: "customDisplayTitle") as? String {
            result["customTitle"] = customTitle
        }
        
        // Extract subitems
        if let subitems = displayItem.value(forKey: "subitems") as? [Any] {
            result["subitems"] = subitems.map { formatDisplayItem($0) }
            result["subitemCount"] = subitems.count
        }
        
        // Extract attributes
        if let attrGroups = displayItem.value(forKey: "attributesGroupList") as? [Any] {
            result["attributes"] = attrGroups.map { formatAttributeGroup($0) }
        }
        
        if let customAttrGroups = displayItem.value(forKey: "customAttrGroupList") as? [Any] {
            result["customAttributes"] = customAttrGroups.map { formatAttributeGroup($0) }
        }
        
        return result
    }
    
    /// Format a LookinDisplayItemDetail into JSON dictionary
    @objc public static func formatDisplayItemDetail(_ detail: Any?) -> [String: Any] {
        guard let itemDetail = detail as? NSObject else {
            return ["error": "Invalid display item detail"]
        }
        
        var result: [String: Any] = [:]
        
        if let oid = itemDetail.value(forKey: "displayItemOid") as? UInt {
            result["oid"] = oid
        }
        
        #if canImport(UIKit)
        if let frameValue = itemDetail.value(forKey: "frameValue") as? NSValue {
            let frame = frameValue.cgRectValue
            result["frame"] = [
                "x": frame.origin.x,
                "y": frame.origin.y,
                "width": frame.size.width,
                "height": frame.size.height
            ]
        }
        
        if let boundsValue = itemDetail.value(forKey: "boundsValue") as? NSValue {
            let bounds = boundsValue.cgRectValue
            result["bounds"] = [
                "x": bounds.origin.x,
                "y": bounds.origin.y,
                "width": bounds.size.width,
                "height": bounds.size.height
            ]
        }
        #endif
        
        if let hidden = itemDetail.value(forKey: "hiddenValue") as? NSNumber {
            result["isHidden"] = hidden.boolValue
        }
        
        if let alpha = itemDetail.value(forKey: "alphaValue") as? NSNumber {
            result["alpha"] = alpha.floatValue
        }
        
        if let customTitle = itemDetail.value(forKey: "customDisplayTitle") as? String {
            result["customTitle"] = customTitle
        }
        
        if let attrGroups = itemDetail.value(forKey: "attributesGroupList") as? [Any] {
            result["attributes"] = attrGroups.map { formatAttributeGroup($0) }
        }
        
        if let customAttrGroups = itemDetail.value(forKey: "customAttrGroupList") as? [Any] {
            result["customAttributes"] = customAttrGroups.map { formatAttributeGroup($0) }
        }
        
        if let subitems = itemDetail.value(forKey: "subitems") as? [Any] {
            result["subitems"] = subitems.map { formatDisplayItem($0) }
            result["subitemCount"] = subitems.count
        }
        
        return result
    }
    
    // MARK: - Private Helpers
    
    private static func formatLookinObject(_ obj: NSObject) -> [String: Any] {
        var result: [String: Any] = [:]
        
        if let oid = obj.value(forKey: "oid") as? UInt {
            result["oid"] = oid
        }
        
        if let className = obj.value(forKey: "className") as? String {
            result["className"] = className
        }
        
        if let memoryAddress = obj.value(forKey: "memoryAddress") as? String {
            result["memoryAddress"] = memoryAddress
        }
        
        return result
    }
    
    private static func formatAppInfo(_ appInfo: NSObject) -> [String: Any] {
        var result: [String: Any] = [:]
        
        if let appName = appInfo.value(forKey: "appName") as? String {
            result["appName"] = appName
        }
        
        if let appVersion = appInfo.value(forKey: "appVersion") as? String {
            result["appVersion"] = appVersion
        }
        
        if let deviceModel = appInfo.value(forKey: "deviceModel") as? String {
            result["deviceModel"] = deviceModel
        }
        
        if let systemVersion = appInfo.value(forKey: "systemVersion") as? String {
            result["systemVersion"] = systemVersion
        }
        
        return result
    }
    
    private static func formatAttributeGroup(_ group: Any?) -> [String: Any] {
        guard let attrGroup = group as? NSObject else {
            return [:]
        }
        
        var result: [String: Any] = [:]
        
        if let title = attrGroup.value(forKey: "title") as? String {
            result["title"] = title
        }
        
        if let sections = attrGroup.value(forKey: "sectionArray") as? [Any] {
            result["sections"] = sections.map { formatAttributeSection($0) }
        }
        
        return result
    }
    
    private static func formatAttributeSection(_ section: Any?) -> [String: Any] {
        guard let attrSection = section as? NSObject else {
            return [:]
        }
        
        var result: [String: Any] = [:]
        
        if let title = attrSection.value(forKey: "title") as? String {
            result["title"] = title
        }
        
        if let attributes = attrSection.value(forKey: "attributes") as? [Any] {
            result["attributes"] = attributes.map { formatAttribute($0) }
        }
        
        return result
    }
    
    private static func formatAttribute(_ attr: Any?) -> [String: Any] {
        guard let attribute = attr as? NSObject else {
            return [:]
        }
        
        var result: [String: Any] = [:]
        
        if let identifier = attribute.value(forKey: "identifier") as? String {
            result["identifier"] = identifier
        }
        
        if let title = attribute.value(forKey: "title") as? String {
            result["title"] = title
        }
        
        // Handle value - could be various types
        if let value = attribute.value(forKey: "value") {
            if let stringValue = value as? String {
                result["value"] = stringValue
            } else if let numberValue = value as? NSNumber {
                result["value"] = numberValue
            } else {
                result["value"] = String(describing: value)
            }
        }
        
        return result
    }
}

#endif
