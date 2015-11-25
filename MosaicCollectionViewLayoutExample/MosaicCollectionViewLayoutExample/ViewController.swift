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
		collectionView?.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "PlayCell")
		
		(collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset = UIEdgeInsetsMake(20, 0, 20, 0)
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 234
	}
	
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 5
	}
	
	


	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PlayCell", forIndexPath: indexPath)
		cell.backgroundColor = UIColor.yellowColor()
		cell.layer.borderColor = UIColor.orangeColor().CGColor
		cell.layer.borderWidth = 1.0
		return cell
	}
	
}

extension ViewController: MosaicCollectionViewLayoutDelegate {

	func mosaicCollectionViewLayout(layout:MosaicCollectionViewLayout, allowedSizesForItemAtIndexPath indexPath:NSIndexPath) -> [MosaicCollectionViewLayout.MosaicCellSize]?{
		
		if indexPath.row % 3 == 0 {
			return [.Big]
		}
		return nil
	}
	
	
	
}



