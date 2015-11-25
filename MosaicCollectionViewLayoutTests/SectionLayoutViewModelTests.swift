//
//  SectionLayoutViewModelTests.swift
//  SectionLayoutViewModelTests
//
//  Created by Rusty Zarse on 11/24/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import XCTest

@testable import MosaicCollectionViewLayout

class SectionLayoutViewModelTests: XCTestCase {
	
	
	func gf(x x:Int, y:Int, cellSize: MosaicCollectionViewLayout.MosaicCellSize) -> MosaicCollectionViewLayout.SectionLayoutViewModel.GridFrame {
		
		let gridSize: CGSize
		switch cellSize {
		case .SmallSquare:
			gridSize = CGSizeMake(1, 1)
		case .BigSquare:
			gridSize = CGSizeMake(2, 2)
		case .SmallBanner:
			gridSize = CGSizeMake(3, 1)
		}
		let origin = CGPointMake(CGFloat(x), CGFloat(y))
		return  MosaicCollectionViewLayout.SectionLayoutViewModel.GridFrame(origin: origin, size: gridSize)
	}
	
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
		XCTAssertEqual(gf(x: 0, y: 0, cellSize:.SmallSquare), section.cellGridPositions[0])
		// cell 2 will be 1,0,2,2
		XCTAssertEqual(gf(x: 1, y: 0, cellSize:.BigSquare), section.cellGridPositions[1])
		// cell 3 will be 0,1,1,1
		XCTAssertEqual(gf(x: 0, y: 1, cellSize:.SmallSquare), section.cellGridPositions[2])
		// since the last big was on the right, the next should position left
		// cell 4 will initially place left (0,2,1,1) but should then be moved right (2,2,1,1) when
		XCTAssertEqual(gf(x: 2, y: 2, cellSize:.SmallSquare), section.cellGridPositions[3])
		// cell 5 positions left (0,2,2,2)
		XCTAssertEqual(gf(x: 0, y: 2, cellSize:.BigSquare), section.cellGridPositions[4])
		// cell 6 positions right (1,4,2,2) on the next double row
		XCTAssertEqual(gf(x: 1, y: 4, cellSize:.BigSquare), section.cellGridPositions[5])
		// cell 7 right 2,3,1,1 (fills in empty space left by 6)
		XCTAssertEqual(gf(x: 2, y: 3, cellSize:.SmallSquare), section.cellGridPositions[6])
		// cell 8 left (0,4,1,1)
		XCTAssertEqual(gf(x: 0, y: 4, cellSize:.SmallSquare), section.cellGridPositions[7])
		// cell 9 0,5,1,1 (because 6 is consuming 2,5..
		XCTAssertEqual(gf(x: 0, y: 5, cellSize:.SmallSquare), section.cellGridPositions[8])
		// cell 10 0,6,1,1
		XCTAssertEqual(gf(x: 0, y: 6, cellSize:.SmallSquare), section.cellGridPositions[9])
		// cell 11 1,6,1,1
		XCTAssertEqual(gf(x: 1, y: 6, cellSize:.SmallSquare), section.cellGridPositions[10])
		// cell 12 2,6,1,1
		XCTAssertEqual(gf(x: 2, y: 6, cellSize:.SmallSquare), section.cellGridPositions[11])
		
		
		
		
	}
	
	
	func testAddCellsWithSmallBanner() {
		// given 3 column grid where big cells are 2x height and 2x width of small cells
		// and this collection of cell sizes
		let sizes: [MosaicCollectionViewLayout.MosaicCellSize] = [
			.SmallBanner,
			.BigSquare,
			.SmallSquare,
			.SmallSquare,
			.BigSquare,
			.BigSquare,
			.SmallSquare,
			.SmallBanner,
			.SmallSquare,
			.SmallSquare,
			.SmallSquare,
			.SmallSquare
		]
	
		
		// create cell items for sizes
		let cellItems = sizes.map{MosaicCollectionViewLayout.CellLayoutViewModel(cellSize: $0)}
		// create section
		let section = MosaicCollectionViewLayout.SectionLayoutViewModel(cellItems: cellItems)
		
		// They should layout like this
		/*
			  0    1    2
			+---------+----+
		0	|      1       |
			+----+----+----+
		1	|         | 3  |
			|    2    +----+
		2	|         | 4  |
			+----+----+----+
		3	| 7  |         |
			+----+    5    |
		4	| 9  |         |
			+---------+----+
		5	|         | 10 |
			|    6    +----+
		6	|         | 11 |
			+----+----+----+
		7	|      8       |
			+----+----+----+
		8	| 12 |
			+----+
		
		*/
		// x,y,w,h position
		// cell 1 will be 0,0,3,1
		XCTAssertEqual(gf(x: 0, y: 0, cellSize:.SmallBanner), section.cellGridPositions[0])
		// cell 2
		XCTAssertEqual(gf(x: 0, y: 1, cellSize:.BigSquare), section.cellGridPositions[1])
		// cell 3
		XCTAssertEqual(gf(x: 2, y: 1, cellSize:.SmallSquare), section.cellGridPositions[2])
		// cell 4
		XCTAssertEqual(gf(x: 2, y: 2, cellSize:.SmallSquare), section.cellGridPositions[3])
		// cell 5 positions left (0,2,2,2)
		XCTAssertEqual(gf(x: 1, y: 3, cellSize:.BigSquare), section.cellGridPositions[4])
		// cell 6
		XCTAssertEqual(gf(x: 0, y: 5, cellSize:.BigSquare), section.cellGridPositions[5])
		// cell 7
		XCTAssertEqual(gf(x: 0, y: 3, cellSize:.SmallSquare), section.cellGridPositions[6])
		// cell 8
		XCTAssertEqual(gf(x: 0, y: 7, cellSize:.SmallBanner), section.cellGridPositions[7])
		// cell 9
		XCTAssertEqual(gf(x: 0, y: 4, cellSize:.SmallSquare), section.cellGridPositions[8])
		// cell 10
		XCTAssertEqual(gf(x: 2, y: 5, cellSize:.SmallSquare), section.cellGridPositions[9])
		// cell 11
		XCTAssertEqual(gf(x: 2, y: 6, cellSize:.SmallSquare), section.cellGridPositions[10])
		// cell 12
		XCTAssertEqual(gf(x: 0, y: 8, cellSize:.SmallSquare), section.cellGridPositions[11])
		
		
		
		
	}
	
	
}