//
//  MosaicCollectionViewLayout.swift
//  MosaicCollectionViewLayout
//
//  Created by Rusty Zarse on 11/23/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

public protocol MosaicCollectionViewLayoutDelegate {

	/// Respond with an array of the `MosaicCollectionViewLayout.MosaicCellSize` that are allowed for the item at the provided `indexPath`.  Returning nil or an empty array indicates any and all and is the default behavior
	func mosaicCollectionViewLayout(layout:MosaicCollectionViewLayout, allowedSizesForItemAtIndexPath indexPath:NSIndexPath) -> [MosaicCollectionViewLayout.MosaicCellSize]?
}

extension MosaicCollectionViewLayoutDelegate {
	
	/// Default implementation returns and empty array, indicating _no restrictions_ or _any and all_
	func mosaicCollectionViewLayout(layout:MosaicCollectionViewLayout, forCollectionView:UICollectionView, allowedSizesForItemAtIndexPath indexPath:NSIndexPath) -> [MosaicCollectionViewLayout.MosaicCellSize] {
		return []
	}
}

public class MosaicCollectionViewLayout: UICollectionViewFlowLayout{
	
	public enum MosaicCellSize {
		case Small
		case Big
	}
	
	public enum CellAlignment {
		case Left
		case Right
	}
	
	// re-initialized in prepareLayout()
	var attributeBuilder: MosaicAttributeBuilder! = nil
	
	//MARK:- UICollectionViewLayout Required Methods
	
	override public func prepareLayout() {
		super.prepareLayout()
		attributeBuilder = MosaicAttributeBuilder(layout: self)
		attributeBuilder.buildSections()
		attributeBuilder.computeFrames()
	}
	
	override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		let superAttributes = super.layoutAttributesForItemAtIndexPath(indexPath)!
		let mosaicAttributes = attributeBuilder.layoutAttributesForItemAtIndexPath(indexPath)
		superAttributes.frame = mosaicAttributes!.frame
		return superAttributes
	}
	
	override public func collectionViewContentSize() -> CGSize {
		return attributeBuilder.frameTree.frame.size
	}
	
	override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		
		guard self.collectionView != nil else {
			return nil
		}
		
		return attributeBuilder.layoutAttributesForElementsInRect(rect)
		
	}
	
	//MARK:- Build Layout
	
	class MosaicAttributeBuilder {
		
		struct MosaicFrameNode {
			var frame:CGRect = CGRectZero
			var childFrames = [MosaicFrameNode]()
		}
		
		let layout: MosaicCollectionViewLayout
		
		var collectionView: UICollectionView {
			get{
				return layout.collectionView!
			}
		}
		
		let mosaicLayoutDelegate: MosaicCollectionViewLayoutDelegate?
		
		var sections = [SectionLayoutViewModel]()
		/// used for fast lookup of layoutAttributesForElementsInRect
		var itemFrameForIndexPath = [(indexPath:NSIndexPath, frame:CGRect)]()
		var frameTree = MosaicFrameNode()
		
		/*
		var sectionInset: UIEdgeInsets
		
		let columnWidth: CGFloat
		let interItemSpacing: CGFloat
		*/
		
		init(layout: MosaicCollectionViewLayout) {
			self.layout = layout
			self.mosaicLayoutDelegate = layout.collectionView?.delegate as? MosaicCollectionViewLayoutDelegate
		}
		
		//MARK: build layout grid
		
		func buildSections() {
			sections = [SectionLayoutViewModel]()
			
			let sectionCount = collectionView.numberOfSections()
			for sectionIndex in 0..<sectionCount {
				var cellItems = [CellLayoutViewModel]()
				for cellIndex in 0..<collectionView.numberOfItemsInSection(sectionIndex) {
					let cellIndexPath = NSIndexPath(forItem:cellIndex, inSection:sectionIndex)
					cellItems.append(cellItemForIndexPath(cellIndexPath))
				}
				let section = SectionLayoutViewModel(cellItems: cellItems)
				sections.append(section)
			}
		}
		
		private func cellItemForIndexPath(indexPath: NSIndexPath) ->  CellLayoutViewModel {
			let allowedSizes: [MosaicCellSize]
			// request delegate allowed sizes
			if let sizes = mosaicLayoutDelegate?.mosaicCollectionViewLayout(layout, allowedSizesForItemAtIndexPath: indexPath) {
				// delegate responded with sizes
				allowedSizes = sizes
			} else {
				// no restictions
				allowedSizes = []
			}
			
			// choose the first allowed size or default to .Small
			let cellSize = allowedSizes.first ?? .Small
			
			return CellLayoutViewModel(cellSize: cellSize, allowedCellSizes: allowedSizes)
		}
		
		//MARK: build attributes
		
		func computeFrames() {
			// TODO: support horizontal scroll direction
			/*let contentSize = layout.scrollDirection == .Vertical ?
				CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0) :
				CGSize(width: 0, height: collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom)
			*/
			
			var contentSize = CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0)
			
			// reset frame tree
			frameTree = MosaicFrameNode()
			// reset origin Ys 
			itemFrameForIndexPath = []
			//TODO: content offset for header

			// compute each section height
			for (sectionIndex, section) in sections.enumerate() {
				//TODO: support horizontal scroll direction
				//TODO: support interitem spacing
				//TODO: support inset margin
				let sectionInset = insetForSection(sectionIndex)
				// scale factor converts 1x1 grid into pixel frames.  Subtract 1  from width to ensure fit
				let unitPixelScaleFactor = (contentSize.width - 1 - (sectionInset.left + sectionInset.right)) / CGFloat(section.constrainedSideGridLength)
				
				// section origin starts at the vertical extent of contentSize
				let sectionOrigin = CGPoint(x: sectionInset.left, y:contentSize.height + sectionInset.top)
				// used to keep track of section's longest vertical extent
				var sectionHeight: CGFloat = 0.0
				// the frames coresponding to the cells, calculated from their grid frames
				var cellFrames = [MosaicFrameNode]()
				
				for (rowIndex, gridFrame) in section.cellGridPositions.enumerate() {
					
					// TODO: support horizontal scroll direction, interitem spacing in these calculations
					// calculate x and y positions using grid frame and scale factor + section origin
					let xPos = gridFrame.origin.x * unitPixelScaleFactor
					let yPos = gridFrame.origin.y * unitPixelScaleFactor
					// origin should include the section origin offset
					let origin = CGPoint(x: xPos + sectionOrigin.x, y: yPos + sectionOrigin.y)
					// calculate size using grid frame * scale factor
					let size = CGSize(width: gridFrame.size.width * unitPixelScaleFactor, height: gridFrame.size.height * unitPixelScaleFactor)
					let cellFrame = CGRect(origin: origin, size: size)
					// mosaic items interleave so it is not trivial to simply sum heights in a single column.  easier to:
					// compute relative y pos + height
					let cellFrameVerticalExtent = yPos + size.height
					// if this is the new high value
					if cellFrameVerticalExtent > sectionHeight {
						// update section height
						sectionHeight = cellFrameVerticalExtent
					}
					cellFrames.append(MosaicFrameNode(frame: cellFrame, childFrames: []))
					// used for fast lookup of items in rect
					itemFrameForIndexPath.append((indexPath:NSIndexPath(forItem: rowIndex, inSection: sectionIndex), frame:cellFrame))
				}
				
				let sectionSize = CGSize(width: contentSize.width - sectionInset.left + sectionInset.right, height: sectionHeight + sectionInset.bottom)
				
				let sectionFrame = CGRect(origin: sectionOrigin, size: sectionSize)
				
				let sectionFrameNode = MosaicFrameNode(frame: sectionFrame, childFrames: cellFrames)
				
				//TODO: move this calculation into the MosaicFrameNode
				contentSize.height = sectionFrame.origin.y + sectionFrame.size.height
				frameTree.childFrames.append(sectionFrameNode)
			}
			itemFrameForIndexPath.sortInPlace{$0.frame.origin.y < $1.frame.origin.y}
			frameTree.frame = CGRect(origin: CGPointZero, size: contentSize)
		}
	
		func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
			let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
			itemAttributes.frame = frameForItemAtIndexPath(indexPath)
			return itemAttributes
		}
		
		private func frameForItemAtIndexPath(indexPath: NSIndexPath) -> CGRect {
			let frame = frameTree.childFrames[indexPath.section].childFrames[indexPath.row].frame
			return frame
		}
		
		private func insetForSection(section: Int) -> UIEdgeInsets {
			if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
				inset = delegate.collectionView?(
					collectionView,
					layout: layout,
					insetForSectionAtIndex: section
				){
				return inset
			}
			return layout.sectionInset
		}
		
		func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
			var layoutAttributes = [UICollectionViewLayoutAttributes]()
			
			for section in 0..<sections.count {
				let sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)
				
				if let headerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: sectionIndexPath) where headerAttributes.frame.size != CGSizeZero && CGRectIntersectsRect(headerAttributes.frame, rect) {
					layoutAttributes.append(headerAttributes)
				}
				
				if let footerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, atIndexPath: sectionIndexPath) where footerAttributes.frame.size != CGSizeZero && CGRectIntersectsRect(footerAttributes.frame, rect) {
					layoutAttributes.append(footerAttributes)
				}
			}
			
			var minY = CGFloat(0), maxY = CGFloat(0)
			
			if (layout.scrollDirection == .Vertical) {
				minY = CGRectGetMinY(rect) - CGRectGetHeight(rect)
				maxY = CGRectGetMaxY(rect)
			} else {
				minY = CGRectGetMinX(rect) - CGRectGetWidth(rect)
				maxY = CGRectGetMaxX(rect)
			}
			
			let itemOriginYs = itemFrameForIndexPath.map{$0.frame.origin.y}
			let lowerIndex = binarySearch(itemOriginYs, value: minY)
			let upperIndex = binarySearch(itemOriginYs, value: maxY)
			
			for lookupIndex in lowerIndex..<upperIndex {
				let indexPath = itemFrameForIndexPath[lookupIndex].indexPath
				let attr = self.layoutAttributesForItemAtIndexPath(indexPath)!
				layoutAttributes.append(attr)
			}
			
			return layoutAttributes
		}
		
		private func binarySearch<T: Comparable>(array: Array<T>, value:T) -> Int{
			var imin=0, imax=array.count
			while imin<imax {
				let imid = imin+(imax-imin)/2
				
				if array[imid] < value {
					imin = imid+1
				} else {
					imax = imid
				}
			}
			return imin
		}
		
		func mayber() {
			
			
			
			/*sizeForCellSize = [
			.Small: CGSize(width: 50, height: 50),
			.Big:	CGSize(width: 100, height: 100)
			]
			sectionInset = UIEdgeInsets()
			interItemSpacing = 1.0
			let numberOfColumns = 3
			
			//TODO: calculate the origin of each section by summing the heights of previous sections
			contentLayoutFrame = CGRect(x: 0, y: 20, width: collectionView.contentSize.width, height: 200)
			// subtract the sum of the interItem space from the total width and divide by the number of columns
			columnWidth = ( contentLayoutFrame.size.width - interItemSpacing * (CGFloat(numberOfColumns - 1)) ) / CGFloat(numberOfColumns)
			*/
		}
	}
}


extension MosaicCollectionViewLayout {
	/// Layout details for positioning and sizing cells
	class CellLayoutViewModel {
		var cellSize: MosaicCellSize {
			didSet {
				assert(allowedCellSizes.isEmpty || allowedCellSizes.contains(cellSize), "`allowedCellSizes` must either be empty or it must be inclusive of `cellSize`")
			}
		}
		let allowedCellSizes: [MosaicCellSize]
		
		init(cellSize: MosaicCellSize, allowedCellSizes: [MosaicCellSize] = []) {
			self.allowedCellSizes = allowedCellSizes
			self.cellSize = cellSize
		}
	}
	
	/// Abstracts the position and size metrics and behavior for placing mosaic style cells in a grid.  Simplifies the layout logic by reducing position and size concerns to 1x1 squares.  After the `SectionLayoutViewModel` is calculated, `UICollectionView` layout requires only basic arithmatic
	class SectionLayoutViewModel {
		/// A rect calibrated to 1x1 squares in a grid
		typealias GridFrame = CGRect
		/// A size calibrated to 1x1 squares
		typealias GridSize = (width:Int, height:Int)
		/// The length of the constrained side of the grid perpendicular to the scroll direction
		let constrainedSideGridLength: Int
		/// The collection of cells meta data used to layout the collection
		var cells: [CellLayoutViewModel]
		/// The calculated grid positions derived from `cells`
		let cellGridPositions: [GridFrame]
	
		init(cellItems: [CellLayoutViewModel], constrainedSideGridLength: Int = 3) {
			self.cells = cellItems
			self.constrainedSideGridLength = constrainedSideGridLength
			// calculate the grid positions of the cell items
			self.cellGridPositions = SectionLayoutViewModel.calculateGridPositions(cellItems, constrainedSideGridLength: constrainedSideGridLength)
		}
		
		/// enumerates the provided `CellItems` and calcuates where each should be placed on the section grid
		private static func calculateGridPositions(cellItems: [CellLayoutViewModel], constrainedSideGridLength:Int) -> [GridFrame] {
			var gridFrames = [GridFrame]()
			
			/// walks through progression of candidate `GridFrame`s to determine the next available _slot_ that will fit the target `CellLayoutViewModel`
			let nextAvailableFrameForCellItem = {
				(cellItem: CellLayoutViewModel) -> GridFrame in
				// get the grid size for cell size
				let gridSize = gridSizeForCellSize(cellItem.cellSize)
				// start with the initial candidate grid frame
				var candidateFrame = GridFrame(x: 0, y: 0, width: gridSize.width, height: gridSize.height)
				while true {
					// see if the proposed frame intersects any frame
					let occupied = gridFrames.reduce(false){$0 || $1.intersects(candidateFrame)}
					
					// no intersection, use it
					if !occupied{
						return candidateFrame
					}
					
					// increment pependicular to vertical scroll direction
					candidateFrame.offsetInPlace(dx: 1, dy: 0)
					
					// ensure there is room for the cell approaching the constrained side's edge
					if(candidateFrame.origin.x + candidateFrame.size.width > CGFloat(constrainedSideGridLength)) {
						// cell exceeds available space, increment in the scroll direction and reset perpendicular index
						candidateFrame.offsetInPlace(dx: 0, dy: 1)
						candidateFrame.origin.x = 0
					}
				}
			}
			
			// first item should start left
			var lastBigCellAligned = CellAlignment.Right
			// unless the first item is .Small
			if let firstItem = cellItems.first where firstItem.cellSize == .Small {
				lastBigCellAligned = .Left
			}
			
			for cellItem in cellItems {
				let gridFrame = nextAvailableFrameForCellItem(cellItem)
				
				// if this is a big cell
				if cellItem.cellSize == .Big {
					let currentCellAlignment: CellAlignment = Int(gridFrame.origin.x) == xPostitionForBigCell(.Left) ? .Left : .Right
					switch (lastBigCellAligned, currentCellAlignment) {
						// if the previous .Big was positioned .Left and current also .Left
						//     or both .Right
					case (.Right, .Right),
						(.Left, .Left):
						
						let targetCellAlignment: CellAlignment = lastBigCellAligned == .Left ? .Right : .Left
						// try bumping previous .Small cell to fit this cell
						// offset candidate frame 1 unit previous
						var adjustedFrame = targetCellAlignment == .Left ?
							gridFrame.offsetBy(dx: -1, dy: 0):
							gridFrame.offsetBy(dx: 0, dy: -1)
						
						// set x pos
						adjustedFrame.origin.x = CGFloat(xPostitionForBigCell(targetCellAlignment))
						
						// find the intersecting grid frame(s)
						let intersectingFrames = gridFrames.filter({$0.intersects(adjustedFrame)})
						// if there is only 1 and it is a .Small
						if intersectingFrames.count == 1 && intersectingFrames[0].size.width == 1 {
							let moveCellIdx = gridFrames.indexOf(intersectingFrames[0])!
							// append the offset frame
							gridFrames.append(adjustedFrame)
							// update the item with rect zero so it doesn't interfere with next frame
							gridFrames[moveCellIdx] = GridFrame(x: 0, y: 0, width: 0, height: 0)
							// update the moved item with the next available frame and
							gridFrames[moveCellIdx] = nextAvailableFrameForCellItem(cellItems[moveCellIdx])
							
						} else {
							// next row or column
							var nextRowFrame = targetCellAlignment == .Left ?
								gridFrame.offsetBy(dx: 0, dy: 1):
								gridFrame.offsetBy(dx: 1, dy: 0)
							
							nextRowFrame.origin.x = CGFloat(xPostitionForBigCell(targetCellAlignment))
							gridFrames.append(nextRowFrame)
						}
						lastBigCellAligned = targetCellAlignment

						
					default:
						gridFrames.append(gridFrame)
						lastBigCellAligned = (gridFrame.origin.x == CGFloat(xPostitionForBigCell(.Left))) ? .Left : .Right
						break
					}
					
				} else {
					gridFrames.append(gridFrame)
				}
			}
			return gridFrames
		}
		
		private static func gridSizeForCellSize(cellSize:MosaicCellSize) -> GridSize {
			return cellSize == .Small ? GridSize(width:1, height:1) : GridSize(width:2, height:2)
		}
	
		private static func xPostitionForBigCell(aligned:CellAlignment) -> Int {
			return aligned == .Left ? 0 : 1
		}
	}
}

