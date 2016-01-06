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
		
		
		let width: CGFloat = 304.0
		
		// 2 pixel space between each of 3 columns = 4 pixels
		// 300 / 3 = 100
		// first item should be 0,0,100,100
		// second item should be 102,0,100,100
		// etc
		let layout = MosaicCollectionViewLayout()
		let delegate = TestMosaicCollectionViewDelegate()
		delegate.interitemSpacing = 2.0
		
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
	
	
	func testContentAndSectionInsets() {
		
		
		let width: CGFloat = 314.0
		
		// 2 pixel space between each of 3 columns = 4 pixels
		// 5 pixels left and right section inset = 10 pixels
		// 300 / 3 = 100
		// first item should be 5,0,100,100
		// second item should be 107,0,100,100
		// etc
		let layout = MosaicCollectionViewLayout()
		let delegate = TestMosaicCollectionViewDelegate()
		
		let collectionView = UICollectionView(frame: CGRectMake(0, 0, width, 100), collectionViewLayout: layout)
		delegate.sectionInsets = UIEdgeInsets(top: 10, left: 5, bottom: 20, right: 5)
		delegate.headerSize = CGSizeMake(314, 200)
		
		collectionView.delegate = delegate
		collectionView.dataSource = delegate
		
		layout.prepareLayout()
		let attributeBuilder = layout.attributeBuilder
		let frameTree = attributeBuilder.layoutFrameTree
		
		let headerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0))
		
		XCTAssertEqual(CGRect(x: 0, y: 0, width: 314, height: 200), headerAttributes?.frame, "first header frame not computed correctly")
		
		let cell1 = frameTree.sections[0].cells[0] // big
		let cell2 = frameTree.sections[0].cells[1] // small
		let cell3 = frameTree.sections[0].cells[2] // small
		let cell4 = frameTree.sections[0].cells[3] // big, positioned right
		let cell6 = frameTree.sections[0].cells[5] // small, positioned left
		
		XCTAssertEqual(CGRect(x: 5, y: 210, width: 202.0, height: 202.0), cell1.frame, "item 1 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 209, y: 210.0, width: 100.0, height: 100.0), cell2.frame, "item 2 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 209.0, y: 312.0, width: 100.0, height: 100.0), cell3.frame, "item 3 frame calculated incorrectly")
		
		
		XCTAssertEqual(CGRect(x: 107.0, y: 414.0, width: 202.0, height: 202.0), cell4.frame, "item 4 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 5.0, y: 516.0, width: 100.0, height: 100.0), cell6.frame, "item 6 frame calculated incorrectly")
		
	}
	
	func testNoHeaderOrFooterFrames() {
		let width: CGFloat = 314.0
		
		let layout = MosaicCollectionViewLayout()
		let delegate = TestMosaicCollectionViewDelegate()
		
		let collectionView = UICollectionView(frame: CGRectMake(0, 0, width, 100), collectionViewLayout: layout)
		
		collectionView.delegate = delegate
		collectionView.dataSource = delegate
		
		layout.prepareLayout()
		
		let headerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0))
		
		XCTAssertNil(headerAttributes?.frame, "header should be nil")
		
	}
	
	func testHeaderAndFooterFrames() {
		
		
		let width: CGFloat = 314.0
		
		let layout = MosaicCollectionViewLayout()
		let delegate = TestMosaicCollectionViewDelegate()
		
		delegate.headerSize = CGSizeMake(width, 120)
		delegate.footerSize = CGSizeMake(width, 25)
		delegate.numberOfSections = 2
		
		let collectionView = UICollectionView(frame: CGRectMake(0, 0, width, 100), collectionViewLayout: layout)
		delegate.sectionInsets = UIEdgeInsets(top: 10, left: 5, bottom: 20, right: 5)
		
		collectionView.delegate = delegate
		collectionView.dataSource = delegate
		
		layout.prepareLayout()
		
		let attributeBuilder = layout.attributeBuilder
		let frameTree = attributeBuilder.layoutFrameTree
		
		let headerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 0))
		
		let footerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, atIndexPath: NSIndexPath(forItem: 0, inSection: 0))
		
		let headerAttributes2 = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: 1))
		
		// find the y coordinate of the bottom edge of the furthest cell
		var sectionEnd: CGFloat = 0
		for cell in frameTree.sections[0].cells {
			if cell.frame.origin.y + cell.frame.size.height > sectionEnd {
				sectionEnd = cell.frame.origin.y + cell.frame.size.height
			}
		}
		
		
		
		// add the section inset bottom (20 above)
		sectionEnd += 20.0
		
		
		
		XCTAssertEqual(CGRect(x: 0, y: 0, width: width, height: 120), headerAttributes?.frame, "first header frame not computed correctly")
		XCTAssertEqual(CGRectMake(0, sectionEnd, width, 25), footerAttributes?.frame, "first footer frame not computed correctly")
		XCTAssertEqual(CGRectMake(0, sectionEnd + 25, width, 120), headerAttributes2?.frame, "second header frame not computed correctly")
		
		let cell1 = frameTree.sections[0].cells[0] // big
		let cell2 = frameTree.sections[0].cells[1] // small
		let cell3 = frameTree.sections[0].cells[2] // small
		let cell4 = frameTree.sections[0].cells[3] // big, positioned right
		let cell6 = frameTree.sections[0].cells[5] // small, positioned left
		
		XCTAssertEqual(CGRect(x: 5, y: 130, width: 202.0, height: 202.0), cell1.frame, "item 1 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 209, y: 130.0, width: 100.0, height: 100.0), cell2.frame, "item 2 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 209.0, y: 232, width: 100.0, height: 100.0), cell3.frame, "item 3 frame calculated incorrectly")
		
		
		XCTAssertEqual(CGRect(x: 107.0, y: 334, width: 202.0, height: 202.0), cell4.frame, "item 4 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 5.0, y: 436, width: 100.0, height: 100.0), cell6.frame, "item 6 frame calculated incorrectly")
		
	}
	
	/// TEST IS FAILING: The row following the custom cell is shifted an extra grid space down.  Must return to this another time.
	func testCustomSizeFromDelegate() {
		
		let width: CGFloat = 300.0
		
		let layout = MosaicCollectionViewLayout()
		let delegate = TestMosaicCollectionViewDelegate()
		delegate.interitemSpacing = 0.0
		let collectionView = UICollectionView(frame: CGRectMake(0, 0, width, 100), collectionViewLayout: layout)
		
		collectionView.delegate = delegate
		collectionView.dataSource = delegate
		let idxCell4 = NSIndexPath(forItem: 3, inSection: 0)
		delegate.sizeforIndexPath[idxCell4] = CGSizeMake(174, 144)
		delegate.allowedMosaicCellSizesForIndexPath[idxCell4] = [MosaicCollectionViewLayout.MosaicCellSize.CustomSizeOverride]
		layout.prepareLayout()
		let attributeBuilder = layout.attributeBuilder
		let frameTree = attributeBuilder.layoutFrameTree
		
		let cell1 = frameTree.sections[0].cells[0] // big
		let cell2 = frameTree.sections[0].cells[1] // small
		let cell3 = frameTree.sections[0].cells[2] // small
		let cell4 = frameTree.sections[0].cells[3] // custom size from delegate
		let cell5 = frameTree.sections[0].cells[4] // big, positioned right
		
		XCTAssertEqual(CGRect(x: 0, y: 0, width: 200.0, height: 200.0), cell1.frame, "item 1 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 200.0, y: 0.0, width: 100.0, height: 100.0), cell2.frame, "item 2 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 200.0, y: 100.0, width: 100.0, height: 100.0), cell3.frame, "item 3 frame calculated incorrectly")
		
		//FIXME: this cell is incorrectly shifted an extra grid row down,
		XCTAssertEqual(CGRect(x: 0, y: 200.0, width: 174.0, height: 144.0), cell4.frame, "item 4 frame calculated incorrectly")
		XCTAssertEqual(CGRect(x: 100.0, y: 344.0, width: 200.0, height: 200.0), cell5.frame, "item 5 frame calculated incorrectly") // positioned right because last was left
		
	}



}
