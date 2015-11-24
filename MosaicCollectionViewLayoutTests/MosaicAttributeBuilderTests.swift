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
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testAddCellsOfVaryingSizes() {
		// given 3 column grid where big cells are 2x height and 2x width of small cells
		// and this collection of cell sizes
		let sizes: [MosaicCollectionViewLayout.MosaicCellSize] = [
			.Small,
			.Big,
			.Small,
			.Small,
			.Big,
			.Big,
			.Small,
			.Small,
			.Small,
			.Small,
			.Small,
			.Small
		]
		
		func gf(x x:Int, y:Int, cellSize: MosaicCollectionViewLayout.MosaicCellSize) -> MosaicCollectionViewLayout.SectionLayoutViewModel.GridFrame {
			let cellSideLength = cellSize == .Small ? 1 : 2
			return  MosaicCollectionViewLayout.SectionLayoutViewModel.GridFrame(x: x, y: y, width:cellSideLength, height: cellSideLength)
		}
		
		// create cell items for sizes
		let cellItems = sizes.map{MosaicCollectionViewLayout.CellLayoutViewModel(cellSize: $0)}
		// create section
		let section = MosaicCollectionViewLayout.SectionLayoutViewModel(cellItems: cellItems)
		
		// They should layout like this
		/*
		  0    1    2
		
		+----+---------+
	0	| 1  |         |
		+----+    2    |
	1	| 3  |         |
		+----+----+----+
	2	|         | 4  |
		|    5    +----+
	3	|         | 7  |
		+----+----+----+
	4	| 8  |         |
		+----+    6    |
	5	| 9  |         |
		+---------+----+
	6	| 10 | 11 | 12 |
		+----+----+----+
		
		*/
		// x,y,w,h position
		// cell 1 will be 0,0,1,1
		XCTAssertEqual(gf(x: 0, y: 0, cellSize:.Small), section.cellGridPositions[0])
		// cell 2 will be 1,0,2,2
		XCTAssertEqual(gf(x: 1, y: 0, cellSize:.Big), section.cellGridPositions[1])
		// cell 3 will be 0,1,1,1
		XCTAssertEqual(gf(x: 0, y: 1, cellSize:.Small), section.cellGridPositions[2])
		// since the last big was on the right, the next should position left
		// cell 4 will initially place left (0,2,1,1) but should then be moved right (2,2,1,1) when
		XCTAssertEqual(gf(x: 2, y: 2, cellSize:.Small), section.cellGridPositions[3])
		// cell 5 positions left (0,2,2,2)
		XCTAssertEqual(gf(x: 0, y: 2, cellSize:.Big), section.cellGridPositions[4])
		// cell 6 positions right (1,4,2,2) on the next double row
		XCTAssertEqual(gf(x: 1, y: 4, cellSize:.Big), section.cellGridPositions[5])
		// cell 7 right 2,3,1,1 (fills in empty space left by 6)
		XCTAssertEqual(gf(x: 2, y: 3, cellSize:.Small), section.cellGridPositions[6])
		// cell 8 left (0,4,1,1)
		XCTAssertEqual(gf(x: 0, y: 4, cellSize:.Small), section.cellGridPositions[7])
		// cell 9 0,5,1,1 (because 6 is consuming 2,5..
		XCTAssertEqual(gf(x: 0, y: 5, cellSize:.Small), section.cellGridPositions[8])
		// cell 10 0,6,1,1
		XCTAssertEqual(gf(x: 0, y: 6, cellSize:.Small), section.cellGridPositions[9])
		// cell 11 1,6,1,1
		XCTAssertEqual(gf(x: 1, y: 6, cellSize:.Small), section.cellGridPositions[10])
		// cell 12 2,6,1,1
		XCTAssertEqual(gf(x: 2, y: 6, cellSize:.Small), section.cellGridPositions[11])
		
		
		
		
		
		
		
	}
	
}
