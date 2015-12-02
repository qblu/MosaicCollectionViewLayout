////
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
		case CustomSizeOverride
		
		public var gridSize: GridSize {
			get {
				switch self {
				case .SmallSquare:
					return (width:1, height: 1)
				case .BigSquare:
					return (width:2, height: 2)
				case .SmallBanner, .CustomSizeOverride:
					// custom override will consume the entire width but height will be determined by the provided frame
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
		
		guard let attributes = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath) else {
			// if super did not return attributes, this supplementary view is not to be presented
			return nil
		}
		
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
				let headerFrame: CGRect?
				let footerFrame: CGRect?
				init(
					cells: [CellFrameNode],
					headerFrame: CGRect? = nil,
					footerFrame: CGRect? = nil
					) {
						//TODO: change headerFrame and footerFrame to size only to remove amiibuity of how its used
						self.cells = cells
						
						// compute frame of all cells
						var rect = MosaicLayoutFrameTree.computeContainerFrame(cells.map({$0 as MosaicFrameNode}))
						
						if let header = headerFrame {
							// expand rect to include header
							rect = CGRectUnion(rect, header)
							self.headerFrame = header
						} else {
							self.headerFrame = nil
						}
						
						if let footer = footerFrame {
							// expand rect to include footer
							rect = CGRectUnion(rect, footer)
							self.footerFrame = footer
						} else {
							self.footerFrame = nil
						}
						
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
				guard var rect = frameNodes.first?.frame else {
					return CGRectZero
				}
				
				for frameNode in frameNodes {
					rect = CGRectUnion(rect, frameNode.frame)
				}
				return rect
			}
			
			private static func expandRect(parentRect: CGRect, toContainChild childRect: CGRect) -> CGRect {
				var rect = parentRect
				
				if childRect.origin.x < rect.origin.x {
					rect.origin.x = childRect.origin.x
				}
				// sum the origin and the width to get total width
				let frameWidth = childRect.origin.x + childRect.size.width
				// if that exceeds the rect
				if frameWidth > rect.origin.x + rect.size.width {
					// subtract the rect origin from the total width so overall width of the container now matches the overall width of the frame
					rect.size.width = frameWidth - rect.origin.x
				}
				
				if childRect.origin.y < rect.origin.y {
					rect.origin.y = childRect.origin.y
				}
				
				let frameHeight = childRect.origin.y + childRect.size.height
				if frameHeight > rect.origin.y + rect.size.height {
					rect.size.height = frameHeight - rect.origin.y
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
		/// precalculated hierarchy of frames per section for header, cell and footer
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
			
			// for each section
			for section in 0..<sections.count {
				let sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)
				
				// if a positive size header frame was computed that intersects the rect
				if let headerFrame = layoutFrameTree.sections[section].headerFrame,
					headerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(
						UICollectionElementKindSectionHeader,
						atIndexPath: sectionIndexPath
					) where headerFrame.size != CGSizeZero &&
						CGRectIntersectsRect(headerFrame, rect) {
							
							headerAttributes.frame = headerFrame
							layoutAttributes.append(headerAttributes)
				}
				
				// repeat for the footer
				if let footerFrame = layoutFrameTree.sections[section].footerFrame,
					footerAttributes = layout.layoutAttributesForSupplementaryViewOfKind(
						UICollectionElementKindSectionFooter,
						atIndexPath: sectionIndexPath
					) where footerFrame.size != CGSizeZero &&
						CGRectIntersectsRect(footerFrame, rect) {
							footerAttributes.frame = footerFrame
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
			
			let attributes = startingAttributes
			
			//TODO: support offset and inset
			//let offset:CGFloat = collectionView.contentOffset.y + collectionView.contentInset.top
			guard layoutFrameTree.sections.count > indexPath.section else {
				// layout frame tree is not yet calculated, return starting attributes
				return attributes
			}
			
			let section = layoutFrameTree.sections[indexPath.section]
			
			switch elementKind {
			case UICollectionElementKindSectionHeader:
				attributes.frame = section.headerFrame ?? CGRectZero
				return attributes
			case UICollectionElementKindSectionFooter:
				attributes.frame = section.footerFrame ?? CGRectZero
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
					
					let candidateCellSize: MosaicCellSize
					
					if let _ = sizeForItemAtIndexPath(cellIndexPath) {
						candidateCellSize = .CustomSizeOverride
					} else {
						// shoot for every 3 items
						candidateCellSize =  bigSquareCount <= cellIndex / 3 ? .BigSquare : .SmallSquare
					}
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
		
		func calculateContentWidth() -> CGFloat {
			return collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
		}
		
		//MARK: Attributes Composition
		
		/// Calculates frames and builds layout structures
		func computeFrames() {
			// TODO: support horizontal scroll direction
			/*let contentSize = layout.scrollDirection == .Vertical ?
			CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0) :
			CGSize(width: 0, height: collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom)
			*/
			
			var contentSize = CGSize(width: calculateContentWidth(), height: 0)
			
			//TODO: contentInset is 0, -64 and is not behaving as expected
			//let contentInset = collectionView.contentInset
			
			// reset frame tree
			var sectionFrames: [MosaicLayoutFrameTree.SectionFrameNode] = []
			// reset origin Ys
			itemFrameForIndexPath = []
			//TODO: content offset for header
			
			// compute each section height
			for (sectionIndex, section) in sections.enumerate() {
				//TODO: support horizontal scroll direction
				
				let sectionInset = insetForSection(sectionIndex)
				let interitemSpacing = interitemSpacingForSection(sectionIndex)
				let lineSpacing = lineSpacingForSection(sectionIndex)
				
				// scale factor converts 1x1 grid into pixel frames.  Subtract 1 from width to ensure fit
				// sum all interitem spacing
				let summedIteritemSpacing = CGFloat(section.constrainedSideGridLength - 1) * interitemSpacing
				let unitPixelScaleFactor = (contentSize.width - sectionInset.left - sectionInset.right - summedIteritemSpacing) / CGFloat(section.constrainedSideGridLength)
				
				// section origin starts horizontally at the content insets and vertically at the vertical extent of contentSize
				let sectionOrigin = CGPoint(x:0.0, y:contentSize.height)
				
				// get the header and footer sizes to use in frame calculations
				var headerFrame = frameForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, inSection:sectionIndex)
				headerFrame?.origin = sectionOrigin
				
				let headerSize = headerFrame?.size ?? CGSizeZero
				var sectionVerticalExtent: CGFloat = headerSize.height
				
				// the frames coresponding to the cells, calculated from their grid frames
				var cellFrames: [MosaicLayoutFrameTree.SectionFrameNode.CellFrameNode] = []
				
				for (rowIndex, gridFrame) in section.cellGridPositions.enumerate() {
					
					//TODO: support horizontal scroll direction in these calculations
					// calculate x and y positions
					// using grid frame and scale factor plus grad frame calculated interitem and line spacing plus section inset
					let indexPath = NSIndexPath(forItem: rowIndex, inSection: sectionIndex)
					
					let xPos = gridFrame.origin.x * unitPixelScaleFactor + interitemSpacing * CGFloat(Int(gridFrame.origin.x) % section.constrainedSideGridLength) + sectionInset.left
					let yPos = gridFrame.origin.y * unitPixelScaleFactor + lineSpacing * CGFloat(gridFrame.origin.y) + sectionInset.top
					// origin should offset using the section origin which was computed including the section and content inset + height of header
					let origin = CGPoint(x: xPos + sectionOrigin.x, y: yPos + sectionOrigin.y + headerSize.height)
					let size: CGSize
					// ask for an overriden item size
					if let overrideSize = sizeForItemAtIndexPath(indexPath) {
						// size overridden by delegate
						assert(sections[indexPath.section].cells[indexPath.row].cellSize == .CustomSizeOverride)
						// incorporate this into the build sections routine
						size = overrideSize
					} else {
						// calculate size using grid frame * scale factor
						size = CGSize(
							width: gridFrame.size.width * unitPixelScaleFactor + interitemSpacing * (gridFrame.size.width - 1),
							height: gridFrame.size.height * unitPixelScaleFactor + lineSpacing * (gridFrame.size.height - 1)
						)
					}
					let cellFrame = CGRect(origin: origin, size: size)
					cellFrames.append(MosaicLayoutFrameTree.SectionFrameNode.CellFrameNode(frame: cellFrame))
					// used for fast lookup of items in rect
					itemFrameForIndexPath.append((indexPath: indexPath, frame: cellFrame))
					if cellFrame.origin.y + cellFrame.size.height > sectionVerticalExtent {
						sectionVerticalExtent = cellFrame.origin.y + cellFrame.size.height
					}
				}
				
				// add the section inset bottom
				sectionVerticalExtent += sectionInset.bottom
				
				// create the footer frame, if any
				var footerFrame = frameForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, inSection:sectionIndex)
				footerFrame?.origin.y = sectionVerticalExtent
				
				let sectionFrameNode = MosaicLayoutFrameTree.SectionFrameNode(cells: cellFrames, headerFrame: headerFrame, footerFrame: footerFrame)
				
				sectionFrames.append(sectionFrameNode)
				// recalculate contentSize with addition of new section + footer height and section and content inset bottoms
				let newContentSize = MosaicLayoutFrameTree(sections: sectionFrames).contentSize
				contentSize = CGSizeMake(newContentSize.width, newContentSize.height)
				
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
		
		private func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize? {
			if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
				size = delegate.collectionView?(
					collectionView,
					layout: layout,
					sizeForItemAtIndexPath: indexPath) {
						return size
			}
			
			return nil
		}
		
		/// Returns the frame for the supplementary view (header/footer) at the given index path
		private func frameForSupplementaryViewOfKind(kind: String, inSection sectionIndex: Int) -> CGRect? {
			let sectionIndexPath = NSIndexPath(forItem: 0, inSection: sectionIndex)
			if let supplementaryViewAttributes = layout.layoutAttributesForSupplementaryViewOfKind(kind, atIndexPath: sectionIndexPath) {
				return supplementaryViewAttributes.frame
			}
			return nil
		}
		
		private func interitemSpacingForSection(section: Int) -> CGFloat {
			if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
				minimumInteritemSpacing = delegate.collectionView?(
					collectionView,
					layout: layout,
					minimumInteritemSpacingForSectionAtIndex: section
				){
					return minimumInteritemSpacing
			}
			return layout.minimumInteritemSpacing
		}
		
		private func lineSpacingForSection(section: Int) -> CGFloat {
			if let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
				minimumLineSpacing = delegate.collectionView?(
					collectionView,
					layout: layout,
					minimumLineSpacingForSectionAtIndex: section
				){
					return minimumLineSpacing
			}
			return layout.minimumLineSpacing
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
