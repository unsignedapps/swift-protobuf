// Sources/protoc-gen-swift/Range+Extensions.swift - Descriptor extensions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Range` that provide Swift-generation-specific
/// functionality.
///
// -----------------------------------------------------------------------------

import Foundation
import SwiftProtobufPluginLibrary
import SwiftProtobuf

extension Range where Bound == Int32 {

  /// A `String` containing the Swift expression that represents this range to
  /// be used in a `case` statement.
  var swiftCaseExpression: String {
    if lowerBound == upperBound - 1 {
      return "\(lowerBound)"
    }
    return "\(lowerBound)..<\(upperBound)"
  }

  /// A `String` containing the Swift Boolean expression that tests the given
  /// variable for containment within this range.
  ///
  /// - Parameter variable: The name of the variable to test in the expression.
  /// - Returns: A `String` containing the Boolean expression.
  func swiftBooleanExpression(variable: String) -> String {
    if lowerBound == upperBound - 1 {
      return "\(lowerBound) == \(variable)"
    }
    return "\(lowerBound) <= \(variable) && \(variable) < \(upperBound)"
  }

}