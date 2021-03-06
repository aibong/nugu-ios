//
//  DisplayAgentProtocol.swift
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

import NuguCore

/// The `DisplayAgent` handles directives for controlling template display.
public protocol DisplayAgentProtocol: CapabilityAgentable {
    /// Adds a delegate to be notified of `DisplayTemplate` changes.
    ///
    /// - Parameter delegate: The object to add.
    func add(delegate: DisplayAgentDelegate)
    
    /// Removes a delegate from DisplayAgent.
    ///
    /// - Parameter delegate: The object to remove.
    func remove(delegate: DisplayAgentDelegate)
    
    /// All of template has a templateId and all of element has a token.
    ///
    /// The Client should call this when element(view) selected(clicked).
    /// - Parameter templateId: The unique identifier for the template.
    /// - Parameter token: The unique identifier for the element.
    /// - Parameter postback: Additional data for the element.
    @discardableResult func elementDidSelect(templateId: String, token: String, postback: [String: AnyHashable]?, completion: ((StreamDataState) -> Void)?) -> String
    
    /// This should be called when occur interaction(input event such as touch, drag, etc...) for display
    func notifyUserInteraction()
}

// MARK: - Default

public extension DisplayAgentProtocol {
    @discardableResult func elementDidSelect(templateId: String, token: String, postback: [String: AnyHashable]?) -> String {
        return elementDidSelect(templateId: templateId, token: token, postback: postback, completion: nil)
    }
}
