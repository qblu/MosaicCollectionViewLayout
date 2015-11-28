//
//  MosaicAttributeBuilderTests.swift
//  MosaicCollectionViewLayout
//
//  Created by Rusty Zarse on 11/23/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import XCTest
@testable import MosaicCollectionViewLayout

class MosaicAttributeBuilderTests: XCTestCase {
	
	typealias FrameTree = MosaicCollectionViewLayout.MosaicAttributeBuilder.MosaicLayoutFrameTree
	typealias SectionFrame = FrameTree.SectionFrameNode
	typealias CellFrame = SectionFrame.CellFrameNode
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testSectionFrames1() {
		
		
		let cells: [CellFrame] = [
			
			CellFrame(frame: CGRect(x: 0, y: 0, width: 50, height: 50)),	// 50, 50
			CellFrame(frame: CGRect(x: 50, y: 100, width: 75, height: 35)), // 125, 135 <--
			
		]
		
		
		let section = SectionFrame(cells: cells)
		
		let sectionWidth: CGFloat = 125.0
		let sectionHeight: CGFloat = 135.0
		
		
		XCTAssertEqual(CGRect(x: 0.0, y: 0.0, width: sectionWidth, height: sectionHeight), section.frame, "section frame calculated incorrectly")
		
		
	}
	
	func testSectionFrames2() {
		
		
		
		let cells: [CellFrame] = [
			CellFrame(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
			CellFrame(frame: CGRect(x: 100, y: 0, width: 100, height: 100)),
			CellFrame(frame: CGRect(x: 200, y: 0, width: 50, height: 50)),
			CellFrame(frame: CGRect(x: 200, y: 50, width: 50, height: 50)),
			CellFrame(frame: CGRect(x: 0, y: 100, width: 50, height: 50)),
			CellFrame(frame: CGRect(x: 0, y: 100, width: 75, height: 25)),
			CellFrame(frame: CGRect(x: 50, y: 100, width: 200, height: 75)), //overlaps item before last, also tallest
			
			CellFrame(frame: CGRect(x: 250, y: 50, width: 50, height: 100)) // widest
		]
		
		
		let section = SectionFrame(cells: cells)
		let frameTree = FrameTree(sections: [section])
		
		let contentSize = frameTree.contentSize
		let sectionWidth: CGFloat = 300.0
		let sectionHeight: CGFloat = 175.0
		
		
		XCTAssertEqual(CGRect(x: 0.0, y: 0.0, width: sectionWidth, height: sectionHeight), section.frame, "section frame calculated incorrectly")
		
		XCTAssertEqual(CGSize(width: sectionWidth, height: sectionHeight), contentSize, "contentSize calculated incorrectly")
	}
	
	
	func testMultiplSectionFrames() {
		
		
		
		let cells: [CellFrame] = [
			CellFrame(frame: CGRect(x: 0, y: 0, width: 270, height: 100)),
			CellFrame(frame: CGRect(x: 100, y: 0, width: 200, height: 100)), // width==300
		]
		
		let cells2: [CellFrame] = [
			CellFrame(frame: CGRect(x: 0, y: 130, width: 200, height: 100)),
			CellFrame(frame: CGRect(x: 100, y: 230, width: 100, height: 90)), // section height==190
		]
		//  both sections total height==320
		
		let section = SectionFrame(cells: cells)
		let section2 = SectionFrame(cells:  cells2)
		let frameTree = FrameTree(sections: [section, section2])
		let contentSize = frameTree.contentSize
		let width: CGFloat = 300.0
		let height: CGFloat = 320.0
		
		XCTAssertEqual(CGRect(x: 0.0, y: 130.0, width: 200.0, height: 190.0), section2.frame, "section frame calculated incorrectly")
		
		XCTAssertEqual(CGSize(width: width, height: height), contentSize, "contentSize calculated incorrectly")
	}
	
	
	
}
