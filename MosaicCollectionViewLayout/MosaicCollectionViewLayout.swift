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
	
	/// A size calibrated to 1x1 squares
	public typealias GridSize = (width:Int, height:Int)
	
	public enum MosaicCellSize {
		case SmallSquare
		case BigSquare
		case SmallBanner
		
		public var gridSize: GridSize {
			get {
				switch self {
				case .SmallSquare:
					return (width:1, height: 1)
				case .BigSquare:
					return (width:2, height: 2)
				case .SmallBanner:
					return (width:3, height: 1)
				}
			}
		}
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
		return attributeBuilder.layoutFrameTree.contentSize
	}
	
	override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		
		guard self.collectionView != nil else {
			return nil
		}
		
		return attributeBuilder.layoutAttributesForElementsInRect(rect)
		
	}
	
	
	override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
		
		let attributes = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath) ?? UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
		
		return attributeBuilder.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath, startingAttributes: attributes)
	}

}

protocol MosaicFrameNode{
	var frame: CGRect { get }
}

extension MosaicCollectionViewLayout {
	//MARK:- Build Layout
	typealias FrameNodeImpl = MosaicFrameNode
	class MosaicAttributeBuilder {
		
		struct MosaicLayoutFrameTree {
			struct SectionFrameNode: MosaicFrameNode {
				struct CellFrameNode: MosaicFrameNode {
					let frame: CGRect
				}
				
				let frame: CGRect
				let cells: [CellFrameNode]
				init(cells: [CellFrameNode]) {
					self.cells = cells
					let rect =  MosaicLayoutFrameTree.computeContainerFrame(cells.map({$0 as MosaicFrameNode}))
					self.frame = rect
				}
			}
		
			
			let sections: [SectionFrameNode]
			let frame: CGRect
			let contentSize: CGSize
			
			init(sections: [SectionFrameNode]) {
				self.sections = sections
				let rect = MosaicLayoutFrameTree.computeContainerFrame(sections.map({$0 as MosaicFrameNode}))
				self.frame = rect
				
				self.contentSize = CGSizeMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
			}
			
			private static func computeContainerFrame(frameNodes:[FrameNodeImpl]) -> CGRect {
				var rect = CGRect(x: CGFloat.max, y: CGFloat.max, width: 0.0, height: 0.0)
				for frameNode in frameNodes {
					if frameNode.frame.origin.x < rect.origin.x {
						rect.origin.x = frameNode.frame.origin.x
					}
					// sum the origin and the width to get total width
					let frameWidth = frameNode.frame.origin.x + frameNode.frame.size.width
					// if that exceeds the rect
					if frameWidth > rect.origin.x + rect.size.width {
						// subtract the rect origin from the total width so overall width of the container now matches the overall width of the frame
						rect.size.width = frameWidth - rect.origin.x
					}
					
					if frameNode.frame.origin.y < rect.origin.y {
						rect.origin.y = frameNode.frame.origin.y
					}

					let frameHeight = frameNode.frame.origin.y + frameNode.frame.size.height
					if frameHeight > rect.origin.y + rect.size.height {
						rect.size.height = frameHeight - rect.origin.y
					}
				}
				return rect
			}
			
			private static func computeAdjustedFrame(size: CGSize, edgeInsets: UIEdgeInsets) -> CGRect {
				return CGRect(origin: CGPoint(x: edgeInsets.left, y: edgeInsets.top), size: CGSize(width: size.width + edgeInsets.right, height: size.height + edgeInsets.bottom))
			}
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
		//TODO: refactor this to reflect sections and cells
		var layoutFrameTree = MosaicLayoutFrameTree(sections: [])
		
		/*
		var sectionInset: UIEdgeInsets
		
		let columnWidth: CGFloat
		let interItemSpacing: CGFloat
		*/
		
		init(layout: MosaicCollectionViewLayout) {
			self.layout = layout
			self.mosaicLayoutDelegate = layout.collectionView?.delegate as? MosaicCollectionViewLayoutDelegate
		}
		
		
		
		//MARK- UICollectionViewFlowLayout Methods
		
		func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
			let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
			itemAttributes.frame = frameForItemAtIndexPath(indexPath)
			return itemAttributes
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
		
		func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath, startingAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes? {

			let attributes = startingAttributes ?? UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
			
			
			//TODO: support offset and inset
			//let offset:CGFloat = collectionView.contentOffset.y + collectionView.contentInset.top
			guard layoutFrameTree.sections.count > indexPath.section else {
				// layout frame tree is not yet calculated, return starting attributes
				return attributes
			}
			
			let startingViewFrame = attributes.frame
			let sectionFrame = layoutFrameTree.sections[indexPath.section].frame
			switch elementKind {
			case UICollectionElementKindSectionHeader:
				//TODO: subtracting header height here to get this working but this logic needs to be refactored into layoutFrameTree
				let headerFrame = CGRect(x: sectionFrame.origin.x, y: sectionFrame.origin.y - startingViewFrame.size.height, width: sectionFrame.size.width, height: startingViewFrame.height)
				attributes.frame = headerFrame
				return attributes
			case UICollectionElementKindSectionFooter:
				//TODO: _not_ subtracting footer height here.  This logic needs to be refactored into layoutFrameTree and validated to be properly considering insets, offsets, etc
				let footerFrame = CGRect(x: sectionFrame.origin.x, y: sectionFrame.origin.y + sectionFrame.size.height, width: sectionFrame.size.width, height: startingViewFrame.height)
				attributes.frame = footerFrame
				return attributes
			default:
				return nil
			}
			
		}
		
		//MARK: Build Layout Grid
		
		/// Builds layout view model, establishing the template grid
		func buildSections() {
			sections = [SectionLayoutViewModel]()
			
			let sectionCount = collectionView.numberOfSections()
			for sectionIndex in 0..<sectionCount {
				var cellItems = [CellLayoutViewModel]()
				// count big squares
				var bigSquareCount = 0
				for cellIndex in 0..<collectionView.numberOfItemsInSection(sectionIndex) {
					let cellIndexPath = NSIndexPath(forItem:cellIndex, inSection:sectionIndex)
					// shoot for every 3 items
					let candidateCellSize: MosaicCellSize =  bigSquareCount <= cellIndex / 3 ? .BigSquare : .SmallSquare
					let cellItem = cellItemForIndexPath(cellIndexPath, candidateSize: candidateCellSize)
					cellItems.append(cellItem)
					// increment the counter
					if cellItem.cellSize == .BigSquare {
						bigSquareCount++
					}
				}
				let section = SectionLayoutViewModel(cellItems: cellItems)
				sections.append(section)
			}
		}
		
		//MARK: Attributes Composition
		
		/// Calculates frames and builds layout structures
		func computeFrames() {
			// TODO: support horizontal scroll direction
			/*let contentSize = layout.scrollDirection == .Vertical ?
				CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0) :
				CGSize(width: 0, height: collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom)
			*/
			
			var contentSize = CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0)
			
			let contentInset = collectionView.contentInset
			
			// reset frame tree
			var sectionFrames: [MosaicLayoutFrameTree.SectionFrameNode] = []
			// reset origin Ys 
			itemFrameForIndexPath = []
			//TODO: content offset for header
			
			// compute each section height
			for (sectionIndex, section) in sections.enumerate() {
				//TODO: support horizontal scroll direction
				//TODO: support interitem spacing
				let sectionInset = insetForSection(sectionIndex)
				// scale factor converts 1x1 grid into pixel frames.  Subtract 1 from width to ensure fit
				let unitPixelScaleFactor = (contentSize.width - 1 - (sectionInset.left + sectionInset.right)) / CGFloat(section.constrainedSideGridLength)
				
				// get the header and footer sizes to use in frame calculations
				let headerSize = frameForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, inSection:sectionIndex)?.size ?? CGSizeZero
				let footerSize = frameForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, inSection:sectionIndex)?.size ?? CGSizeZero
				
				
				// section origin starts horizontally at the content and section insets and vertically at the vertical extent of contentSize + the height of the header + the section and content insets
				let sectionOrigin = CGPoint(x: sectionInset.left + contentInset.left, y:contentSize.height + sectionInset.top + contentInset.top + headerSize.height)
				
				// the frames coresponding to the cells, calculated from their grid frames
				var cellFrames: [MosaicLayoutFrameTree.SectionFrameNode.CellFrameNode] = []
				
				for (rowIndex, gridFrame) in section.cellGridPositions.enumerate() {
					
					//TODO: support horizontal scroll direction and interitem spacing in these calculations
					// calculate x and y positions 
					// using grid frame and scale factor
					let xPos = gridFrame.origin.x * unitPixelScaleFactor
					let yPos = gridFrame.origin.y * unitPixelScaleFactor
					// origin should offset using the section origin which was computed including the section and content inset
					let origin = CGPoint(x: xPos + sectionOrigin.x, y: yPos + sectionOrigin.y)
					// calculate size using grid frame * scale factor
					let size = CGSize(width: gridFrame.size.width * unitPixelScaleFactor, height: gridFrame.size.height * unitPixelScaleFactor)
					let cellFrame = CGRect(origin: origin, size: size)
					cellFrames.append(MosaicLayoutFrameTree.SectionFrameNode.CellFrameNode(frame: cellFrame))
					// used for fast lookup of items in rect
					itemFrameForIndexPath.append((indexPath:NSIndexPath(forItem: rowIndex, inSection: sectionIndex), frame:cellFrame))
				}
			
				let sectionFrameNode = MosaicLayoutFrameTree.SectionFrameNode(cells: cellFrames)
				
				sectionFrames.append(sectionFrameNode)
				// recalculate contentSize with addition of new section + footer height and section and content inset bottoms
				let newContentSize = MosaicLayoutFrameTree(sections: sectionFrames).contentSize
				contentSize = CGSizeMake(newContentSize.width, newContentSize.height + footerSize.height + sectionInset.bottom + contentInset.bottom)
			}
			
			layoutFrameTree = MosaicLayoutFrameTree(sections: sectionFrames)
			
			itemFrameForIndexPath.sortInPlace{$0.frame.origin.y < $1.frame.origin.y}
		}
		
		//MARK:- Attribute Acquisition
		
		/// returns a cell item configured for the `indexPath`
		private func cellItemForIndexPath(indexPath: NSIndexPath, candidateSize: MosaicCellSize) ->  CellLayoutViewModel {
			let allowedSizes: [MosaicCellSize]
			
			// request delegate allowed sizes
			if let sizes = mosaicLayoutDelegate?.mosaicCollectionViewLayout(layout, allowedSizesForItemAtIndexPath: indexPath) {
				// delegate responded with sizes
				allowedSizes = sizes
			} else {
				// no restictions
				allowedSizes = []
			}
			
			let cellSize = allowedSizes.isEmpty || allowedSizes.contains(candidateSize) ? candidateSize: allowedSizes.first!
			
			return CellLayoutViewModel(cellSize: cellSize, allowedCellSizes: allowedSizes)
		}
		
		/// Returns the frame for the item at the given index path
		private func frameForItemAtIndexPath(indexPath: NSIndexPath) -> CGRect {
			let frame = layoutFrameTree.sections[indexPath.section].cells[indexPath.row].frame
			return frame
		}
		
		/// Returns the frame for the supplementary view (header/footer) at the given index path
		private func frameForSupplementaryViewOfKind(kind: String, inSection sectionIndex: Int) -> CGRect? {
			let sectionIndexPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
			if let supplementaryViewAttributes = layout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: sectionIndexPath) {
				return supplementaryViewAttributes.frame
			}
			return nil
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

		
		//MARK:- Optimization Helpers
		
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
	
	/// Abstracts the position and size metrics and behavior for placing mosaic style cells in a grid.  Simplifies the layout logic by reducing position and size concerns to 1x1 squares.  After the `SectionLayoutViewModel` is calculated, `UICollectionView` layout requires only basic arithmatic.  The class inherits from Chuck Norris
	class SectionLayoutViewModel {
		/// A rect calibrated to 1x1 squares in a grid
		typealias GridFrame = CGRect
		
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
				// start with the initial candidate grid frame
				var candidateFrame = GridFrame(x: 0, y: 0, width: cellItem.cellSize.gridSize.width, height: cellItem.cellSize.gridSize.height)
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
			if let firstItem = cellItems.first where firstItem.cellSize == .SmallSquare {
				lastBigCellAligned = .Left
			}
			
			for cellItem in cellItems {
				let gridFrame = nextAvailableFrameForCellItem(cellItem)
				
				// if this is a big cell
				if cellItem.cellSize == .BigSquare {
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
			return cellSize == .SmallSquare ? GridSize(width:1, height:1) : GridSize(width:2, height:2)
		}
	
		private static func xPostitionForBigCell(aligned:CellAlignment) -> Int {
			return aligned == .Left ? 0 : 1
		}
	}
}
