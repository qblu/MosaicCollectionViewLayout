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
	
	
	func testMultipleSectionFrames() {
		
		
		
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
	
	func testInteritemSpacing() {
		class TestCollectionViewDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
			
			var interitemSpacing: CGFloat = 2.0
			var sectionInsets = UIEdgeInsetsMake(0, 0, 0, 0)
			
			//MARK: UICollectionViewDataSource
			
			@objc
			func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
				return 10
			}
			
			
			@objc
			func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
				return UICollectionViewCell()
			}
			

			//MARK: UICollectionViewDelegateFlowLayout
			@objc
			func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
				return sectionInsets
			}
			
			@objc
			func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
				return interitemSpacing
			}
	
			@objc
			func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
				return interitemSpacing
			}
		}
		
		let width: CGFloat = 304.0
		
		// 2 pixel space between each of 3 columns = 4 pixels
		// 300 / 3 = 100
		// first item should be 0,0,100,100
		// second item should be 102,0,100,100
		// etc
		let layout = MosaicCollectionViewLayout()
		let delegate = TestCollectionViewDelegate()
		
		let collectionView = UICollectionView(frame: CGRectMake(0, 0, width, 100), collectionViewLayout: layout)
		collectionView.delegate = delegate
		collectionView.dataSource = delegate
		
		layout.prepareLayout()
		let attributeBuilder = layout.attributeBuilder
		
		let frameTree = attributeBuilder.layoutFrameTree
		let cell1 = frameTree.sections[0].cells[0] // big
		let cell2 = frameTree.sections[0].cells[1] // small
		let cell3 = frameTree.sections[0].cells[2] // small
		let cell4 = frameTree.sections[0].cells[3] // big, positioned right
		let cell6 = frameTree.sections[0].cells[5] // small, positioned left
		
		XCTAssertEqual(CGRect(x: 0.0, y: 0.0, width: 202.0, height: 202.0), cell1.frame, "item 1 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 204.0, y: 0.0, width: 100.0, height: 100.0), cell2.frame, "item 2 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 204.0, y: 102.0, width: 100.0, height: 100.0), cell3.frame, "item 3 frame calculated incorrectly")
		
		
		XCTAssertEqual(CGRect(x: 102.0, y: 204.0, width: 202.0, height: 202.0), cell4.frame, "item 4 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 0.0, y: 306.0, width: 100.0, height: 100.0), cell6.frame, "item 6 frame calculated incorrectly")

	}



}
