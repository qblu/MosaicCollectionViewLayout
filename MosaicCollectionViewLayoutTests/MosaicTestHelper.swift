//
//  MosaicTestHelper.swift
//  MosaicCollectionViewLayout
//
//  Created by Rusty Zarse on 12/11/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import Foundation
@testable import MosaicCollectionViewLayout

class MosaicTestHelper {
	static func gridFrame(x x:Int, y:Int, cellSize: MosaicCollectionViewLayout.MosaicCellSize) -> MosaicCollectionViewLayout.SectionLayoutViewModel.GridFrame {
		
		let gridSize: CGSize
		switch cellSize {
		case .SmallSquare:
			gridSize = CGSizeMake(1, 1)
		case .BigSquare:
			gridSize = CGSizeMake(2, 2)
		case .SmallBanner, .CustomSizeOverride:
			gridSize = CGSizeMake(3, 1)
		}
		let origin = CGPointMake(CGFloat(x), CGFloat(y))
		return  MosaicCollectionViewLayout.SectionLayoutViewModel.GridFrame(origin: origin, size: gridSize)
	}
}