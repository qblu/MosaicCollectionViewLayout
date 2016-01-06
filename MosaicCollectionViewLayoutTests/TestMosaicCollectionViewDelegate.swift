//
//  TestMosaicCollectionViewDelegate.swift
//  TestMosaicCollectionViewDelegate
//
//  Created by Rusty Zarse on 12/11/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import Foundation

@testable import MosaicCollectionViewLayout

class TestMosaicCollectionViewDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MosaicCollectionViewLayoutDelegate {
	
	var numberOfSections = 1
	var numberOfRowsForSection = [Int: Int]()
	var interitemSpacing: CGFloat = 2.0
	var sectionInsets = UIEdgeInsetsMake(0, 0, 0, 0)
	var headerSize = CGSizeZero
	var footerSize = CGSizeZero
	var sizeforIndexPath = [NSIndexPath: CGSize]()
	var allowedMosaicCellSizesForIndexPath: [NSIndexPath: [MosaicCollectionViewLayout.MosaicCellSize]] = [:]
	
	//MARK: UICollectionViewDataSource
	
	@objc
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return numberOfRowsForSection[section] ?? 10
	}
	
	@objc
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return numberOfSections
	}
	
	
	@objc
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		return UICollectionViewCell()
	}
	
	@objc
	func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		let frame = (kind == UICollectionElementKindSectionHeader) ?
			CGRectMake(0, 0, headerSize.width, headerSize.height) :
			CGRectMake(0, 0, footerSize.width, footerSize.height)
		
		return UICollectionReusableView(frame: frame)
		
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
	
	@objc
	func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, referenceSizeForHeaderInSection: Int) -> CGSize {
		return headerSize
	}
	
	@objc
	func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, referenceSizeForFooterInSection: Int) -> CGSize {
		return footerSize
	}
	
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return sizeforIndexPath[indexPath] ?? CGSize.zero
	}
	
	//Mark: MosaicCollectionViewLayoutDelegate
	func mosaicCollectionViewLayout(layout:MosaicCollectionViewLayout, allowedSizesForItemAtIndexPath indexPath:NSIndexPath) -> [MosaicCollectionViewLayout.MosaicCellSize]? {
		return allowedMosaicCellSizesForIndexPath[indexPath]
	}
	
}