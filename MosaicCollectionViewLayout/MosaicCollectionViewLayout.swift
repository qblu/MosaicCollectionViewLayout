//
//  MosaicCollectionViewLayout.swift
//  MosaicCollectionViewLayout
//
//  Created by Rusty Zarse on 11/23/15.
//  Copyright © 2015 com.levous. All rights reserved.
//

class MosaicCollectionViewLayout: UICollectionViewLayout{
	
	enum MosaicCellSize {
		case Small
		case Big
	}
	
	enum CellAlignment {
		case Left
		case Right
	}
	
	
	//MARK:- UICollectionViewLayout Required Methods
	
	override func prepareLayout() {
		let sectionCount = collectionView!.numberOfSections()
		
	}
	
	//MARK:- Build Layout
	
	func mosaicCellSizeForIndexPath(indexPath: NSIndexPath) -> MosaicCellSize {
		return .Small
	}
	
	
	struct MosaicAttributeBuilder {
		/*

NOTES:
		forget the column mess.  Instead, track a grid.  Place items in the next available position where they can consume n squares
		.Big wants to alternate so interrogate the previous left/right and displace unfinished rows if smalls if possible
		finished row of smalls are not displaced
		fill in empty spots with smalls
		each cell item has a starting point in the grid and height and width in squares
		calculate grid positions and sizes only
		when a frame is requested, use the gride position and size to calculate the appropriate frame for each cell
	
		maintain the index position of the original item

*/
		
		struct SectionBuilder {
			
			var cellCount = 0
			let sizeForCellSize: [MosaicCellSize: CGSize]
			var sectionInset: UIEdgeInsets
			let columnWidth: CGFloat
			let interItemSpacing: CGFloat;
			let contentLayoutFrame: CGRect
			
			init(cells: [CellLayoutViewModel], collectionView: UICollectionView) {
				sizeForCellSize = [
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
			
			}
		}
	}
}

extension MosaicCollectionViewLayout {
	class CellLayoutViewModel {
		let cellSize: MosaicCellSize
		init(cellSize: MosaicCellSize) {
			self.cellSize = cellSize
		}
	}
	
	/// Abstracts the behavior for placing mosaic style cells in a grid.  Simplifies the layout logic by reducing position and size concerns to 1x1 squares.  After the `SectionLayoutViewModel` is calculated, `UICollectionView` layout requires only basic arithmatic
// The class inherits from Chuck Norris
	class SectionLayoutViewModel {
		/// A rect calibrated to 1x1 squares in a grid
		typealias GridFrame = CGRect
		/// A size calibrated to 1x1 squares
		typealias GridSize = (width:Int, height:Int)
		/// The length of the constrained side of the grid perpendicular to the scroll direction
		let constrainedSideLength: Int
		/// The collection of cells meta data used to layout the collection
		var cells: [CellLayoutViewModel]
		/// The calculated grid positions derived from `cells`
		let cellGridPositions: [GridFrame]
	
		init(cellItems: [CellLayoutViewModel], constrainedSideLength: Int = 3) {
			self.cells = cellItems
			self.constrainedSideLength = constrainedSideLength
			// calculate the grid positions of the cell items
			self.cellGridPositions = SectionLayoutViewModel.calculateGridPositions(cellItems, constrainedSideLength: constrainedSideLength)
		}
		
		/// enumerates the provided `CellItems` and calcuates where each should be placed on the section grid
		private static func calculateGridPositions(cellItems: [CellLayoutViewModel], constrainedSideLength:Int) -> [GridFrame] {
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
					if(candidateFrame.origin.x + candidateFrame.size.width > CGFloat(constrainedSideLength)) {
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
