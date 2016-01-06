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
	
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	
	func testOverrideSizesPerSection() {
		// Mosaic supports overridding
		let sizes: [MosaicCollectionViewLayout.MosaicCellSize] = [
			.SmallSquare,
			.BigSquare,
			.SmallSquare,
			.SmallSquare,
			.BigSquare,
			.BigSquare,
			.SmallSquare,
			.SmallSquare,
			.SmallSquare,
			.SmallSquare,
			.SmallSquare,
			.SmallSquare
		]
		
		let width: CGFloat = 300.0
		
		let layout = MosaicCollectionViewLayout()
		let delegate = TestMosaicCollectionViewDelegate()
		delegate.interitemSpacing = 0.0
		let collectionView = UICollectionView(frame: CGRectMake(0, 0, width, 100), collectionViewLayout: layout)
		
		collectionView.delegate = delegate
		collectionView.dataSource = delegate
		
		for (row, size) in sizes.enumerate() {
			// force the layout to a known distribution of sizes (verified by `SectionLayoutViewModelTests.testAddCellsOfVaryingSizes`)
			let indexPath = NSIndexPath(forItem: row, inSection: 0)
			delegate.allowedMosaicCellSizesForIndexPath[indexPath] = [size]
		}
		
		// three sections
		delegate.numberOfSections = 3

		
		// create a custom section with three rows
		delegate.numberOfRowsForSection[1] = 3
		
		var indexPath = NSIndexPath(forItem: 0, inSection: 1)
		delegate.sizeforIndexPath[indexPath] = CGSizeMake(200.0, 120.0)
		delegate.allowedMosaicCellSizesForIndexPath[indexPath] = [.CustomSizeOverride]
		
		indexPath = NSIndexPath(forItem: 1, inSection: 1)
		delegate.sizeforIndexPath[indexPath] = CGSizeMake(100.0, 20.0)
		delegate.allowedMosaicCellSizesForIndexPath[indexPath] = [.CustomSizeOverride]
		
		indexPath = NSIndexPath(forItem: 2, inSection: 1)
		delegate.sizeforIndexPath[indexPath] = CGSizeMake(120.0, 99.0)
		delegate.allowedMosaicCellSizesForIndexPath[indexPath] = [.CustomSizeOverride]
		
		let expectedCustomSectionHeight: CGFloat = 239.0
		
		// third section
		indexPath = NSIndexPath(forItem: 0, inSection: 2)
		delegate.allowedMosaicCellSizesForIndexPath[indexPath] = [.BigSquare]
		
		layout.prepareLayout()
		
		let customSectionFrameNode = layout.attributeBuilder.layoutFrameTree.sections[1]
		let frameHeight = customSectionFrameNode.frame.height
		XCTAssertEqual(expectedCustomSectionHeight, frameHeight)
		
	}
}

		
		