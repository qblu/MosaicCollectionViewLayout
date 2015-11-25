//
//  MosaicCollectionViewLayoutTests.swift
//  MosaicCollectionViewLayoutTests
//
//  Created by Rusty Zarse on 11/23/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import XCTest
@testable import MosaicCollectionViewLayout

class MosaicCollectionViewLayoutTests: XCTestCase {
	
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
	
	func testLayoutFrameTreeComputeFrames1() {
	
		
		let cells: [CellFrame] = [
			
			CellFrame(frame: CGRect(x: 0, y: 0, width: 50, height: 50)),	// 50, 50
			CellFrame(frame: CGRect(x: 50, y: 100, width: 75, height: 35)), // 125, 135 <--
			
		]
		
		
		let section = SectionFrame(cells: cells, sectionInsets: UIEdgeInsetsMake(20, 10, 5, 8))
	
		let sectionWidth: CGFloat = 125.0 + 8.0
		let sectionHeight: CGFloat = 135.0 + 5.0
		
		
		XCTAssertEqual(CGRect(x: 10.0, y: 20.0, width: sectionWidth, height: sectionHeight), section.frame, "section frame calculated incorrectly")
		
		
	}
    
    func testLayoutFrameTreeFrames() {
		

		
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
		
		
		let section = SectionFrame(cells: cells, sectionInsets: UIEdgeInsetsMake(10, 20, 12, 30))
		let frameTree = FrameTree(sections: [section])

		let contentSize = frameTree.contentSize
		let sectionWidth: CGFloat = 300.0 + 30.0
		let sectionHeight: CGFloat = 175.0 + 12.0
		
		
		XCTAssertEqual(CGRect(x: 20.0, y: 10.0, width: sectionWidth, height: sectionHeight), section.frame, "section frame calculated incorrectly")
		
		XCTAssertEqual(CGSize(width: sectionWidth + 20.0, height: sectionHeight + 10.0), contentSize, "contentSize calculated incorrectly")
    }
	
}
