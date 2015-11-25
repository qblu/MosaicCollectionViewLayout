//
//  ViewController.swift
//  MosaicCollectionViewLayoutExample
//
//  Created by Rusty Zarse on 11/23/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import UIKit
import MosaicCollectionViewLayout

class ViewController: UICollectionViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		(collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset = UIEdgeInsetsMake(20, 0, 20, 0)
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 100
	}
	
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 5
	}
	
	


	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("playCell", forIndexPath: indexPath)
		cell.backgroundColor = UIColor.yellowColor()
		cell.layer.borderColor = UIColor.orangeColor().CGColor
		cell.layer.borderWidth = 1.0
		if let label = cell.contentView.viewWithTag(21) as? UILabel {
			label.text = "\(indexPath.row)"
		}
		return cell
	}
	
	
	override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
		
		if kind == UICollectionElementKindSectionHeader {
			return collectionView.dequeueReusableSupplementaryViewOfKind( UICollectionElementKindSectionHeader, withReuseIdentifier:"header", forIndexPath:indexPath)
		}
	
 
		if kind == UICollectionElementKindSectionFooter {
			return collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier:"footer", forIndexPath:indexPath)
		}
	
		return UICollectionReusableView()
	}
	
}

extension ViewController: MosaicCollectionViewLayoutDelegate {

	func mosaicCollectionViewLayout(layout:MosaicCollectionViewLayout, allowedSizesForItemAtIndexPath indexPath:NSIndexPath) -> [MosaicCollectionViewLayout.MosaicCellSize]?{
		
		//if indexPath.row > 12 && indexPath.row < 20 {
		//	return [.Big]
		//}
		
		if indexPath.row == 0 || indexPath.row == 10 {
			return [.SmallBanner]
		}
		
		if indexPath.row % 3 == 0 {
			return [.BigSquare]
		}
		return nil
	}
	
	
	
}



