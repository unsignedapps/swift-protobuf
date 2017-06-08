// Tests/SwiftProtobufTests/Test_MessageSet.swift - Test MessageSet behaviors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Test all behaviors around the message option message_set_wire_format.
///
// -----------------------------------------------------------------------------

import Foundation
import XCTest
import SwiftProtobuf

class Test_MessageSet: XCTestCase {

  // wireformat_unittest.cc: TEST(WireFormatTest, SerializeMessageSet)
  func testSerialize() throws {
    let msg = Proto2WireformatUnittest_TestMessageSet.with {
      $0.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i = 123
      $0.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str = "foo"
    }

    let serialized: Data
    do {
      serialized = try msg.serializedData()
    } catch let e {
      XCTFail("Failed to serialize: \(e)")
      return
    }

    // Read it back in with the RawMessageSet to validate it.

    let raw: ProtobufUnittest_RawMessageSet
    do {
      raw = try ProtobufUnittest_RawMessageSet(serializedData: serialized)
    } catch let e {
      XCTFail("Failed to parse: \(e)")
      return
    }

    XCTAssertTrue(raw.unknownFields.data.isEmpty)

    XCTAssertEqual(raw.item.count, 2)

    XCTAssertEqual(Int(raw.item[0].typeID),
                   ProtobufUnittest_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber)
    XCTAssertEqual(Int(raw.item[1].typeID),
                   ProtobufUnittest_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber)

    let extMsg1 = try ProtobufUnittest_TestMessageSetExtension1(serializedData: raw.item[0].message)
    XCTAssertEqual(extMsg1.i, 123)
    XCTAssertTrue(extMsg1.unknownFields.data.isEmpty)
    let extMsg2 = try ProtobufUnittest_TestMessageSetExtension2(serializedData: raw.item[1].message)
    XCTAssertEqual(extMsg2.str, "foo")
    XCTAssertTrue(extMsg2.unknownFields.data.isEmpty)
  }

  static let canonicalTextFormat: String = (
    "message_set {\n" +
      "  [protobuf_unittest.TestMessageSetExtension1] {\n" +
      "    i: 23\n" +
      "  }\n" +
      "  [protobuf_unittest.TestMessageSetExtension2] {\n" +
      "    str: \"foo\"\n" +
      "  }\n" +
    "}\n"
  )

  // text_format_unittest.cc: TEST_F(TextFormatMessageSetTest, Serialize)
  func testTextFormat_Serialize() {
    let msg = ProtobufUnittest_TestMessageSetContainer.with {
      $0.messageSet.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i = 23;
      $0.messageSet.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str = "foo"
    }

    XCTAssertEqual(msg.textFormatString(), Test_MessageSet.canonicalTextFormat)
  }

  // text_format_unittest.cc: TEST_F(TextFormatMessageSetTest, Deserialize)
  func testTextFormat_Parse() {
    let msg: ProtobufUnittest_TestMessageSetContainer
    do {
      msg = try ProtobufUnittest_TestMessageSetContainer(
        textFormatString: Test_MessageSet.canonicalTextFormat,
        extensions: ProtobufUnittest_UnittestMset_Extensions)
    } catch let e {
      XCTFail("Shouldn't have failed: \(e)")
      return
    }

    XCTAssertEqual(
      msg.messageSet.ProtobufUnittest_TestMessageSetExtension1_messageSetExtension.i, 23)
    XCTAssertEqual(
      msg.messageSet.ProtobufUnittest_TestMessageSetExtension2_messageSetExtension.str, "foo")

    // Ensure nothing else showed up.
    XCTAssertTrue(msg.unknownFields.data.isEmpty)
    XCTAssertTrue(msg.messageSet.unknownFields.data.isEmpty)

    var validator = ExtensionValidator()
    validator.expectedMessages = [
      (1, true), // protobuf_unittest.TestMessageSetContainer.message_set (where the extensions are)
      (ProtobufUnittest_TestMessageSetExtension1.Extensions.message_set_extension.fieldNumber, false),
      (ProtobufUnittest_TestMessageSetExtension2.Extensions.message_set_extension.fieldNumber, false),
    ]
    validator.validate(message: msg)
  }

  fileprivate struct ExtensionValidator: PBTestVisitor {
    // Values are field number and if we should recurse.
    var expectedMessages = [(Int, Bool)]()

    mutating func validate<M: Message>(message: M) {
      do {
        try message.traverse(visitor: &self)
      } catch let e {
        XCTFail("Error while traversing: \(e)")
      }
      XCTAssertTrue(expectedMessages.isEmpty,
                    "Epected more messages: \(expectedMessages)")
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      guard !expectedMessages.isEmpty else {
        XCTFail("Unexpected Message: \(fieldNumber) = \(value)")
        return
      }
      let (expected, shouldRecurse) = expectedMessages.removeFirst()
      XCTAssertEqual(fieldNumber, expected)
      if shouldRecurse && expected == fieldNumber {
        try value.traverse(visitor: &self)
      }
    }
  }
}
