//
//  ContentView.swift
//  EmojiExplorer
//
//  Created by Jinwoo Kim on 8/4/24.
//

import SwiftUI
import ObjectiveC
import os

struct ContentView: View {
    var body: some View {
        List {
            ForEach(categoryIdentifierList(), id: \.self) { categoryIdentifier in
                Section(localizedNameWithCategoryIdentifier(identifier: categoryIdentifier)) {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(emojiStringsWithCategoryIdentifier(identifier: categoryIdentifier), id: \.self) { emojis in
                                Text(emojis.joined(separator: " "))
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

fileprivate func categoryIdentifierList() -> [String] {
    let EMFEmojiCategory: AnyClass = objc_lookUpClass("EMFEmojiCategory")!
    let cmd_categoryIdentifierList = Selector(("categoryIdentifierList"))
    let method_categoryIdentifierList = class_getClassMethod(EMFEmojiCategory, cmd_categoryIdentifierList)!
    let imp_categoryIdentifierList = method_getImplementation(method_categoryIdentifierList)
    let func_categoryIdentifierList = unsafeBitCast(imp_categoryIdentifierList, to: (@convention(c) (AnyClass, Selector) -> [String]).self)
    
    return func_categoryIdentifierList(EMFEmojiCategory, cmd_categoryIdentifierList)
}

fileprivate func emojiCategoryWithCategoryIdentifier(identifier: String) -> AnyObject {
    // +[EMFEmojiCategory _emojiSetForIdentifier:]에서 -isEqualToString:을 쓰지 않고 Pointer 비교를 하고 있기 때문에 Pointer를 가져와야함
    // 이걸 피하려면 +[EMFEmojiCategory NatureEmoji] 같은 것을 쓰면 되겠지만 그러면 모든 경우를 하드코딩 해야함
    
    let handle = dlopen("/System/Library/PrivateFrameworks/EmojiFoundation.framework/EmojiFoundation", RTLD_NOW)!
    let symbol = identifier.withCString { ptr in
        dlsym(handle, ptr)
    }!
    let identifierPtr = symbol.assumingMemoryBound(to: AnyObject.self)
    
    let EMFEmojiCategory: AnyClass = objc_lookUpClass("EMFEmojiCategory")!
    let cmd_categoryWithIdentifier = Selector(("categoryWithIdentifier:"))
    let method_categoryWithIdentifier = class_getClassMethod(EMFEmojiCategory, cmd_categoryWithIdentifier)!
    let imp_categoryWithIdentifier = method_getImplementation(method_categoryWithIdentifier)
    let func_categoryWithIdentifier = unsafeBitCast(imp_categoryWithIdentifier, to: (@convention(c) (AnyClass, Selector, AnyObject) -> AnyObject).self)
    
    let category = func_categoryWithIdentifier(EMFEmojiCategory, cmd_categoryWithIdentifier, identifierPtr.pointee)
    return category
}

fileprivate func localizedNameWithCategoryIdentifier(identifier: String) -> String {
    let category = emojiCategoryWithCategoryIdentifier(identifier: identifier)
    
    let EMFEmojiCategory: AnyClass = objc_lookUpClass("EMFEmojiCategory")!
    let cmd_localizedName = Selector(("localizedName"))
    let method_localizedName = class_getInstanceMethod(EMFEmojiCategory, cmd_localizedName)!
    let imp_localizedName = method_getImplementation(method_localizedName)
    let func_localizedName = unsafeBitCast(imp_localizedName, to: (@convention(c) (AnyObject, Selector) -> NSString).self)
    
    return func_localizedName(category, cmd_localizedName) as String
}

fileprivate func emojiStringsWithCategoryIdentifier(identifier: String) -> [[String]] {
    let category = emojiCategoryWithCategoryIdentifier(identifier: identifier)
    
    //
    
    let EMFEmojiCategory: AnyClass = objc_lookUpClass("EMFEmojiCategory")!
    
    let cmd_emojiTokensForLocaleData = Selector(("emojiTokensForLocaleData:"))
    let method_emojiTokensForLocaleData = class_getInstanceMethod(EMFEmojiCategory, cmd_emojiTokensForLocaleData)!
    let imp_emojiTokensForLocaleData = method_getImplementation(method_emojiTokensForLocaleData)
    let func_emojiTokensForLocaleData = unsafeBitCast(imp_emojiTokensForLocaleData, to: (@convention(c) (AnyObject, Selector, AnyObject?) -> [AnyObject]).self)
    let emojiTokens = func_emojiTokensForLocaleData(category, cmd_emojiTokensForLocaleData, nil)
    
    //
    
    let EMFEmojiToken: AnyClass = objc_lookUpClass("EMFEmojiToken")!
    
    let cmd_string = Selector(("string"))
    let method_string = class_getInstanceMethod(EMFEmojiToken, cmd_string)!
    let imp_string = method_getImplementation(method_string)
    let func_string = unsafeBitCast(imp_string, to: (@convention(c) (AnyObject, Selector) -> NSString).self)
    
    let cmd_skinToneSpecifiers = Selector(("_skinToneVariantStrings"))
    let method_skinToneSpecifiers = class_getInstanceMethod(EMFEmojiToken, cmd_skinToneSpecifiers)!
    let imp_skinToneSpecifiers = method_getImplementation(method_skinToneSpecifiers)
    let func_skinToneSpecifiers = unsafeBitCast(imp_skinToneSpecifiers, to: (@convention(c) (AnyObject, Selector) -> [NSString]).self)
    
    let results: [[String]] = emojiTokens
        .map { emojiToken in
            let _skinToneVariantStrings = func_skinToneSpecifiers(emojiToken, cmd_skinToneSpecifiers)
           
            if _skinToneVariantStrings.isEmpty {
                return [func_string(emojiToken, cmd_string) as String]
            } else {
                return _skinToneVariantStrings as [String]
            }
        }
    
    return results
}
