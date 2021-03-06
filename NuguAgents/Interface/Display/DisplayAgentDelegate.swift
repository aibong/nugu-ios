//
//  DisplayAgentDelegate.swift
//  NuguAgents
//
//  Created by MinChul Lee on 16/05/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// The `DisplayAgent` delegate is used to notify observers when a template directive is received.
public protocol DisplayAgentDelegate: class {
    /// Tells the delegate that the specified template should be displayed.
    ///
    /// - Parameter template: The template to display.
    func displayAgentShouldRender(template: DisplayTemplate) -> AnyObject?
    
    /// Tells the delegate that the specified template should be removed from the screen.
    ///
    /// - Parameter template: The template to remove from the screen.
    func displayAgentDidClear(template: DisplayTemplate)
    
    /// Tells the delegate that the displayed template should move focus with given direction.
    /// Should return whether succeeded or not.
    /// - Parameter direction: Direction to move focus.
    func displayAgentShouldMoveFocus(direction: DisplayControlPayload.Direction) -> Bool
    
    /// Tells the delegate that the displayed template should scroll with given direction.
    /// Should return whether succeeded or not.
    /// - Parameter reason: Direction to scroll.
    func displayAgentShouldScroll(direction: DisplayControlPayload.Direction) -> Bool
    
    /// Should return currently focused item token.
    func displayAgentFocusedItemToken() -> String?
    
    /// Should return currently visible item's token.
    func displayAgentVisibleTokenList() -> [String]?
    
    /// Should update proper displaying view with given template.
    func displayAgentShouldUpdate(template: DisplayTemplate)
}
