//
//  ViewController.swift
//  MosaicCollectionViewLayoutExample
//
//  Created by Rusty Zarse on 11/23/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.collectionView?.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "PlayCell")
	}
	
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 23
	}
	
	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PlayCell", forIndexPath: indexPath)
		cell.backgroundColor = UIColor.yellowColor()
		return cell
	}
	
}



