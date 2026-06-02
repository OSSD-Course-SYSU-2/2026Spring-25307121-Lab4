import prompt from '@ohos.prompt'
import common from '@ohos.app.ability.common'

interface Polyomino {
  name: string
  shape: number[][]
  color: string
}

@Entry
@Component
struct Index {
  @State showPuzzle: boolean = false
  @State nonogramCompleted: boolean = false
  @State filledCells: number[][] = []
  @State showCompletionLink: boolean = false
  @State gridState: number[][] = []
  @State currentLevel: number = 0
  @State steps: number = 0
  @State rowHints: number[][] = []
  @State columnHints: number[][] = []

  @State puzzleGrid: number[][] = []
  @State selectedPiece: number = -1
  @State pieceRotation: number[] = [0, 0, 0, 0]
  @State placedPieces: number = 0

  @State isDragging: boolean = false
  @State dragX: number = 0
  @State dragY: number = 0
  @State hoverRow: number = -1
  @State hoverCol: number = -1
  @State previewRotation: number[] = [0, 0, 0, 0]

  private readonly GRID_SIZE: number = 5
  private readonly EMPTY: number = 0
  private readonly FILLED: number = 1
  private readonly MARKED: number = 2
  private readonly CELL_SIZE: number = 40
  private readonly PUZZLE_CELL_SIZE: number = 50
  private readonly ROW_HINT_WIDTH: number = 80

  private puzzles: number[][][] = [
    [
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [1, 1, 1, 1, 1],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0]
    ],
    [
      [1, 0, 0, 0, 0],
      [1, 1, 0, 0, 0],
      [0, 1, 1, 0, 0],
      [0, 0, 1, 1, 0],
      [0, 0, 0, 1, 1]
    ],
    [
      [1, 1, 1, 0, 0],
      [1, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0]
    ]
  ]

  private polyominoPieces: Polyomino[] = [
    {
      name: '长条',
      shape: [[1, 1, 1]],
      color: '#FF6B6B'
    },
    {
      name: '方块',
      shape: [[1, 1], [1, 1]],
      color: '#4ECDC4'
    },
    {
      name: 'L形',
      shape: [[1, 0], [1, 1]],
      color: '#FFE66D'
    },
    {
      name: '直线',
      shape: [[1, 1]],
      color: '#95E1D3'
    }
  ]

  aboutToAppear() {
    this.initNonogramGame()
  }

  initPuzzleGame() {
    this.puzzleGrid = []
    for (let i = 0; i < this.GRID_SIZE; i++) {
      let row: number[] = []
      for (let j = 0; j < this.GRID_SIZE; j++) {
        row.push(0)
      }
      this.puzzleGrid.push(row)
    }
    this.selectedPiece = -1
    this.pieceRotation = [0, 0, 0, 0]
    this.previewRotation = [0, 0, 0, 0]
    this.placedPieces = 0
    this.isDragging = false
    this.hoverRow = -1
    this.hoverCol = -1
  }

  initNonogramGame() {
    this.gridState = []
    for (let i = 0; i < this.GRID_SIZE; i++) {
      let row: number[] = []
      for (let j = 0; j < this.GRID_SIZE; j++) {
        row.push(this.EMPTY)
      }
      this.gridState.push(row)
    }
    this.steps = 0
    this.calculateHints()
  }

  rotatePiece(pieceIndex: number) {
    this.pieceRotation[pieceIndex] = (this.pieceRotation[pieceIndex] + 1) % 4
    this.pieceRotation = [...this.pieceRotation]
    prompt.showToast({
      message: '已旋转模块',
      duration: 1000
    })
  }

  previewRotate(pieceIndex: number) {
    this.previewRotation[pieceIndex] = (this.pieceRotation[pieceIndex] + 1) % 4
    this.previewRotation = [...this.previewRotation]
  }

  clearPreview(pieceIndex: number) {
    this.previewRotation[pieceIndex] = this.pieceRotation[pieceIndex]
    this.previewRotation = [...this.previewRotation]
  }

  getRotatedShape(pieceIndex: number, rotation?: number): number[][] {
    let piece = this.polyominoPieces[pieceIndex]
    let shape = piece.shape
    let rot = rotation !== undefined ? rotation : this.pieceRotation[pieceIndex]

    for (let r = 0; r < rot; r++) {
      let newShape: number[][] = []
      let rows = shape.length
      let cols = shape[0].length
      for (let j = 0; j < cols; j++) {
        let newRow: number[] = []
        for (let i = rows - 1; i >= 0; i--) {
          newRow.push(shape[i][j])
        }
        newShape.push(newRow)
      }
      shape = newShape
    }
    return shape
  }

  canPlacePiece(pieceIndex: number, startRow: number, startCol: number): boolean {
    if (startRow < 0 || startCol < 0) return false
    
    let shape = this.getRotatedShape(pieceIndex)
    let rows = shape.length
    let cols = shape[0].length

    if (startRow + rows > this.GRID_SIZE || startCol + cols > this.GRID_SIZE) {
      return false
    }

    for (let i = 0; i < rows; i++) {
      for (let j = 0; j < cols; j++) {
        if (shape[i][j] === 1) {
          if (this.puzzleGrid[startRow + i][startCol + j] !== 0) {
            return false
          }
        }
      }
    }
    return true
  }

  placePiece(pieceIndex: number, startRow: number, startCol: number) {
    let shape = this.getRotatedShape(pieceIndex)
    let rows = shape.length
    let cols = shape[0].length

    for (let i = 0; i < rows; i++) {
      for (let j = 0; j < cols; j++) {
        if (shape[i][j] === 1) {
          this.puzzleGrid[startRow + i][startCol + j] = pieceIndex + 1
        }
      }
    }
    this.placedPieces++
    this.puzzleGrid = JSON.parse(JSON.stringify(this.puzzleGrid))
    console.log('放置模块后，placedPieces: ' + this.placedPieces)
    this.checkPuzzleComplete()
  }

  onPuzzleCellClick(row: number, col: number) {
    if (this.puzzleGrid[row][col] === -1) {
      prompt.showToast({
        message: '该区域不可放置',
        duration: 1500
      })
      return
    }
    
    if (this.selectedPiece === -1) {
      prompt.showToast({
        message: '请先选择一个模块',
        duration: 1500
      })
      return
    }

    if (this.puzzleGrid[row][col] > 0) {
      prompt.showToast({
        message: '该位置已被占用',
        duration: 1500
      })
      return
    }

    if (this.canPlacePiece(this.selectedPiece, row, col)) {
      this.placePiece(this.selectedPiece, row, col)
      this.selectedPiece = -1
      this.isDragging = false
    } else {
      prompt.showToast({
        message: '无法放置：超出边界或重叠',
        duration: 1500
      })
    }
  }

  onCellHover(row: number, col: number) {
    this.hoverRow = row
    this.hoverCol = col
  }

  onCellLeave() {
    this.hoverRow = -1
    this.hoverCol = -1
  }

  getHoverCells(): number[][] {
    if (this.selectedPiece === -1 || this.hoverRow === -1 || this.hoverCol === -1) {
      return []
    }

    let shape = this.getRotatedShape(this.selectedPiece)
    let cells: number[][] = []
    
    for (let i = 0; i < shape.length; i++) {
      for (let j = 0; j < shape[0].length; j++) {
        if (shape[i][j] === 1) {
          cells.push([this.hoverRow + i, this.hoverCol + j])
        }
      }
    }
    
    return cells
  }

  isHoverCell(row: number, col: number): boolean {
    let hoverCells = this.getHoverCells()
    for (let cell of hoverCells) {
      if (cell[0] === row && cell[1] === col) {
        return true
      }
    }
    return false
  }

  canPlaceAtHover(): boolean {
    if (this.selectedPiece === -1 || this.hoverRow === -1 || this.hoverCol === -1) {
      return false
    }
    return this.canPlacePiece(this.selectedPiece, this.hoverRow, this.hoverCol)
  }

  onPieceDragStart(pieceIndex: number, x: number, y: number) {
    this.selectedPiece = pieceIndex
    this.isDragging = true
    this.dragX = x
    this.dragY = y
  }

  onPieceDragMove(x: number, y: number) {
    if (this.isDragging) {
      this.dragX = x
      this.dragY = y
    }
  }

  onPieceDragEnd() {
    this.isDragging = false
  }

  checkPuzzleComplete() {
    let filledCount = 0
    for (let i = 0; i < this.GRID_SIZE; i++) {
      for (let j = 0; j < this.GRID_SIZE; j++) {
        if (this.puzzleGrid[i][j] > 0) {
          filledCount++
        }
      }
    }

    console.log('filledCount: ' + filledCount + ', filledCells.length: ' + this.filledCells.length + ', currentLevel: ' + this.currentLevel)

    if (filledCount === this.filledCells.length) {
      if (this.currentLevel === 2) {
        console.log('显示通关界面')
        this.showCompletionLink = true
        this.showPuzzle = false
        prompt.showToast({
          message: '恭喜通关！所有关卡已完成',
          duration: 3000
        })
      } else {
        prompt.showToast({
          message: '恭喜通关！第 ' + (this.currentLevel + 1) + ' 关完成',
          duration: 3000
        })
        setTimeout(() => {
          this.nextLevel()
        }, 2500)
      }
    }
  }

  resetPuzzle() {
    this.initPuzzleForFilledCells()
    prompt.showToast({
      message: '已重置拼图',
      duration: 1500
    })
  }

  skipPuzzle() {
    this.currentLevel = (this.currentLevel + 1) % this.puzzles.length
    this.showPuzzle = false
    this.nonogramCompleted = false
    this.initNonogramGame()
    prompt.showToast({
      message: '跳过拼图，进入下一关',
      duration: 1500
    })
  }

  openLink() {
    let context = getContext(this) as common.UIAbilityContext
    let linkUrl = 'https://endfield.hypergryph.com/wllp/AlA8352RcilJqN2i?sub_channel=840&hg_media=custom_bingbrand&hg_link_code=5GbX53Kp'
    
    context.openLink(linkUrl).then(() => {
      console.log('成功打开链接')
    }).catch((err: Error) => {
      console.error('打开链接失败: ' + err.message)
      prompt.showToast({
        message: '无法打开链接',
        duration: 2000
      })
    })
  }

  calculateHints() {
    let solution = this.puzzles[this.currentLevel]
    this.rowHints = []
    this.columnHints = []

    for (let i = 0; i < this.GRID_SIZE; i++) {
      let hintArr: number[] = []
      let count = 0
      for (let j = 0; j < this.GRID_SIZE; j++) {
        if (solution[i][j] === this.FILLED) {
          count++
        } else if (count > 0) {
          hintArr.push(count)
          count = 0
        }
      }
      if (count > 0) {
        hintArr.push(count)
      }
      this.rowHints.push(hintArr.length > 0 ? hintArr : [0])
    }

    for (let j = 0; j < this.GRID_SIZE; j++) {
      let hintArr: number[] = []
      let count = 0
      for (let i = 0; i < this.GRID_SIZE; i++) {
        if (solution[i][j] === this.FILLED) {
          count++
        } else if (count > 0) {
          hintArr.push(count)
          count = 0
        }
      }
      if (count > 0) {
        hintArr.push(count)
      }
      this.columnHints.push(hintArr.length > 0 ? hintArr : [0])
    }

    console.log('Row Hints: ' + JSON.stringify(this.rowHints))
    console.log('Column Hints: ' + JSON.stringify(this.columnHints))
  }

  onCellClick(row: number, col: number) {
    if (this.gridState[row][col] === this.FILLED) {
      this.gridState[row][col] = this.EMPTY
    } else {
      this.gridState[row][col] = this.FILLED
    }
    this.steps++
    this.gridState = JSON.parse(JSON.stringify(this.gridState))
  }

  onCellLongPress(row: number, col: number) {
    if (this.gridState[row][col] === this.MARKED) {
      this.gridState[row][col] = this.EMPTY
    } else {
      this.gridState[row][col] = this.MARKED
    }
    this.steps++
    this.gridState = JSON.parse(JSON.stringify(this.gridState))
  }

  checkSolution() {
    let solution = this.puzzles[this.currentLevel]
    let isCorrect = true

    for (let i = 0; i < this.GRID_SIZE; i++) {
      for (let j = 0; j < this.GRID_SIZE; j++) {
        let playerFilled = this.gridState[i][j] === this.FILLED
        let solutionFilled = solution[i][j] === this.FILLED
        if (playerFilled !== solutionFilled) {
          isCorrect = false
          break
        }
      }
      if (!isCorrect) break
    }

    if (isCorrect) {
      this.filledCells = []
      for (let i = 0; i < this.GRID_SIZE; i++) {
        for (let j = 0; j < this.GRID_SIZE; j++) {
          if (this.gridState[i][j] === this.FILLED) {
            this.filledCells.push([i, j])
          }
        }
      }
      
      this.initPuzzleForFilledCells()
      this.nonogramCompleted = true
      this.showPuzzle = true
      
      prompt.showToast({
        message: '数织完成！现在用拼图填充',
        duration: 2000
      })
    } else {
      prompt.showToast({
        message: '答案不正确，请继续尝试',
        duration: 2000
      })
    }
  }

  initPuzzleForFilledCells() {
    this.puzzleGrid = []
    for (let i = 0; i < this.GRID_SIZE; i++) {
      let row: number[] = []
      for (let j = 0; j < this.GRID_SIZE; j++) {
        row.push(-1)
      }
      this.puzzleGrid.push(row)
    }
    
    for (let cell of this.filledCells) {
      this.puzzleGrid[cell[0]][cell[1]] = 0
    }
    
    this.selectedPiece = -1
    this.pieceRotation = [0, 0, 0, 0]
    this.previewRotation = [0, 0, 0, 0]
    this.placedPieces = 0
    this.isDragging = false
    this.hoverRow = -1
    this.hoverCol = -1
  }

  resetGame() {
    this.initNonogramGame()
    prompt.showToast({
      message: '已重置游戏',
      duration: 1500
    })
  }

  nextLevel() {
    this.currentLevel = (this.currentLevel + 1) % this.puzzles.length
    this.showPuzzle = false
    this.nonogramCompleted = false
    this.showCompletionLink = false
    this.initNonogramGame()
    prompt.showToast({
      message: '第 ' + (this.currentLevel + 1) + ' 关',
      duration: 1500
    })
  }

  build() {
    Stack() {
      Column() {
        if (this.showCompletionLink) {
          this.buildCompletionInterface()
        } else if (this.showPuzzle) {
          this.buildPuzzleInterface()
        } else {
          this.buildNonogramInterface()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#0D0D1A')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)

      if (this.isDragging && this.selectedPiece !== -1) {
        this.buildDraggingPiece()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildCompletionInterface() {
    Column() {
      Text('恭喜通关！')
        .fontSize(48)
        .fontColor('#FFD700')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100, bottom: 30 })

      Text('你已完成所有关卡')
        .fontSize(20)
        .fontColor('#AAAAAA')
        .margin({ bottom: 50 })

      Column() {
        Text('点击下方链接继续')
          .fontSize(16)
          .fontColor('#888888')
          .margin({ bottom: 20 })

        Text('https://endfield.hypergryph.com/wllp/AlA8352RcilJqN2i')
          .fontSize(14)
          .fontColor('#00E5FF')
          .fontWeight(FontWeight.Bold)
          .decoration({ type: TextDecorationType.Underline, color: '#00E5FF' })
          .margin({ bottom: 10 })
          .onClick(() => {
            this.openLink()
          })
      }
      .padding(30)
      .backgroundColor('#1A1A2E')
      .border({ width: 2, color: '#FFD700', radius: 12 })
      .margin({ bottom: 40 })

      Button('重新开始')
        .width(150)
        .height(50)
        .fontSize(18)
        .backgroundColor('#1A1A2E')
        .fontColor('#FFD700')
        .border({ width: 2, color: '#FFD700', radius: 10 })
        .onClick(() => {
          this.currentLevel = 0
          this.showCompletionLink = false
          this.showPuzzle = false
          this.nonogramCompleted = false
          this.initNonogramGame()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildDraggingPiece() {
    Column() {
      ForEach(this.getRotatedShape(this.selectedPiece), (shapeRow: number[], rowIdx: number) => {
        Row() {
          ForEach(shapeRow, (cell: number, colIdx: number) => {
            Rect()
              .width(40)
              .height(40)
              .fill(cell === 1 ? this.polyominoPieces[this.selectedPiece].color : 'transparent')
              .opacity(cell === 1 ? 0.7 : 0)
              .margin(1)
          }, (cell: number, colIdx: number) => 'drag-' + rowIdx + '-' + colIdx)
        }
      }, (shapeRow: number[], rowIdx: number) => 'drag-row-' + rowIdx)
    }
    .position({ x: this.dragX - 40, y: this.dragY - 40 })
    .zIndex(999)
  }

  @Builder
  buildPuzzleInterface() {
    Column() {
      Text('拼图填充')
        .fontSize(32)
        .fontColor('#FFD700')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 10 })

      Text('用拼图模块填充数织完成的区域')
        .fontSize(16)
        .fontColor('#AAAAAA')
        .margin({ bottom: 20 })

      Text('已放置: ' + this.placedPieces + ' / ' + this.filledCells.length + ' 格')
        .fontSize(14)
        .fontColor('#888888')
        .margin({ bottom: 15 })

      Column() {
        ForEach(this.puzzleGrid, (row: number[], rowIndex: number) => {
          Row() {
            ForEach(row, (cell: number, colIndex: number) => {
              Stack() {
                Rect()
                  .width(this.PUZZLE_CELL_SIZE - 4)
                  .height(this.PUZZLE_CELL_SIZE - 4)
                  .fill(this.getPuzzleCellColorWithHover(cell, rowIndex, colIndex))
                  .radius(4)
                  .border({
                    width: this.isHoverCell(rowIndex, colIndex) ? 3 : 1,
                    color: this.getHoverBorderColor(rowIndex, colIndex)
                  })
              }
              .width(this.PUZZLE_CELL_SIZE)
              .height(this.PUZZLE_CELL_SIZE)
              .margin(2)
              .onClick(() => {
                this.onPuzzleCellClick(rowIndex, colIndex)
              })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Move) {
                  this.onCellHover(rowIndex, colIndex)
                } else if (event.type === TouchType.Up) {
                  this.onCellLeave()
                }
              })
            }, (cell: number, colIndex: number) => 'puzzle-' + rowIndex + '-' + colIndex + '-' + cell)
          }
        }, (row: number[], rowIndex: number) => 'puzzle-row-' + rowIndex + '-' + row.join(','))
      }
      .backgroundColor('#1A1A2E')
      .border({ width: 2, color: '#FFD700', radius: 8 })
      .padding(10)
      .margin({ bottom: 20 })

      Text('选择模块（点击选中，再点击旋转，点击网格放置）')
        .fontSize(14)
        .fontColor('#888888')
        .margin({ bottom: 10 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
        ForEach(this.polyominoPieces, (piece: Polyomino, index: number) => {
          Column() {
            Row() {
              Column() {
                ForEach(this.getRotatedShape(index), (shapeRow: number[], rowIdx: number) => {
                  Row() {
                    ForEach(shapeRow, (cell: number, colIdx: number) => {
                      Rect()
                        .width(20)
                        .height(20)
                        .fill(cell === 1 ? piece.color : 'transparent')
                        .margin(1)
                    }, (cell: number, colIdx: number) => 'shape-' + index + '-' + rowIdx + '-' + colIdx)
                  }
                }, (shapeRow: number[], rowIdx: number) => 'shape-row-' + index + '-' + rowIdx)
              }
              .padding(5)
              .backgroundColor('#1A1A2E')
              .border({
                width: this.selectedPiece === index ? 3 : 1,
                color: this.selectedPiece === index ? '#FFD700' : '#444444',
                radius: 6
              })
              .onClick(() => {
                if (this.selectedPiece === index) {
                  this.rotatePiece(index)
                } else {
                  this.selectedPiece = index
                }
              })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.onPieceDragStart(index, event.touches[0].x, event.touches[0].y)
                } else if (event.type === TouchType.Move) {
                  this.onPieceDragMove(event.touches[0].x, event.touches[0].y)
                } else if (event.type === TouchType.Up) {
                  this.onPieceDragEnd()
                }
              })

              Column() {
                ForEach(this.getRotatedShape(index, this.previewRotation[index] !== this.pieceRotation[index] ? this.previewRotation[index] : (this.pieceRotation[index] + 1) % 4), (shapeRow: number[], rowIdx: number) => {
                  Row() {
                    ForEach(shapeRow, (cell: number, colIdx: number) => {
                      Rect()
                        .width(12)
                        .height(12)
                        .fill(cell === 1 ? piece.color : 'transparent')
                        .opacity(cell === 1 ? 0.6 : 0)
                        .margin(0.5)
                    }, (cell: number, colIdx: number) => 'preview-' + index + '-' + rowIdx + '-' + colIdx)
                  }
                }, (shapeRow: number[], rowIdx: number) => 'preview-row-' + index + '-' + rowIdx)
              }
              .padding(3)
              .backgroundColor('#0D0D1A')
              .border({ width: 1, color: '#444444', radius: 4 })
              .margin({ left: 8 })
              .visibility(this.selectedPiece === index ? Visibility.Visible : Visibility.None)
            }

            Text(piece.name)
              .fontSize(12)
              .fontColor('#AAAAAA')
              .margin({ top: 5 })
          }
          .margin({ left: 10, right: 10, bottom: 15 })
        }, (piece: Polyomino, index: number) => 'piece-' + index)
      }
      .width('90%')
      .margin({ bottom: 20 })

      Row() {
        Button('重置拼图')
          .width(110)
          .height(45)
          .fontSize(16)
          .backgroundColor('#1A1A2E')
          .fontColor('#00E5FF')
          .border({ width: 2, color: '#00E5FF', radius: 10 })
          .onClick(() => {
            this.resetPuzzle()
          })

        Blank().width(20)

        Button('检查完成')
          .width(110)
          .height(45)
          .fontSize(16)
          .backgroundColor('#1A1A2E')
          .fontColor('#FFD700')
          .border({ width: 2, color: '#FFD700', radius: 10 })
          .onClick(() => {
            this.checkPuzzleComplete()
          })
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildNonogramInterface() {
    Column() {
      Text('Delta修复')
        .fontSize(32)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 10 })

      Text('关卡 ' + (this.currentLevel + 1) + ' / ' + this.puzzles.length + '  |  步数: ' + this.steps)
        .fontSize(16)
        .fontColor('#AAAAAA')
        .margin({ bottom: 15 })

      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('')
                .width(this.ROW_HINT_WIDTH)
                .height(60)
            }
            
            ForEach(this.columnHints, (hint: number[], index: number) => {
              Column() {
                ForEach(hint, (num: number, numIndex: number) => {
                  Text(num.toString())
                    .fontSize(12)
                    .fontColor('#00E5FF')
                    .fontWeight(FontWeight.Bold)
                    .height(18)
                }, (num: number, numIndex: number) => 'col-hint-' + index + '-' + numIndex)
              }
              .width(this.CELL_SIZE)
              .height(60)
              .justifyContent(FlexAlign.End)
              .alignItems(HorizontalAlign.Center)
            }, (hint: number[], index: number) => 'col-' + index + '-' + hint.join(','))
          }

          ForEach(this.gridState, (row: number[], rowIndex: number) => {
            Row() {
              Row() {
                ForEach(this.rowHints[rowIndex], (num: number, numIndex: number) => {
                  Text(num.toString())
                    .fontSize(12)
                    .fontColor('#00E5FF')
                    .fontWeight(FontWeight.Bold)
                    .width(16)
                    .textAlign(TextAlign.Center)
                }, (num: number, numIndex: number) => 'row-hint-' + rowIndex + '-' + numIndex)
              }
              .width(this.ROW_HINT_WIDTH)
              .height(this.CELL_SIZE)
              .justifyContent(FlexAlign.End)
              .alignItems(VerticalAlign.Center)
              .margin({ right: 5 })

              ForEach(row, (cell: number, colIndex: number) => {
                Stack() {
                  Rect()
                    .width(this.CELL_SIZE - 2)
                    .height(this.CELL_SIZE - 2)
                    .fill(this.getCellColor(cell))
                    .radius(2)

                  if (cell === this.MARKED) {
                    Text('X')
                      .fontSize(20)
                      .fontColor('#FF4444')
                      .fontWeight(FontWeight.Bold)
                  }
                }
                .width(this.CELL_SIZE)
                .height(this.CELL_SIZE)
                .margin(1)
                .onClick(() => {
                  this.onCellClick(rowIndex, colIndex)
                })
                .gesture(
                  LongPressGesture({ repeat: false })
                    .onAction(() => {
                      this.onCellLongPress(rowIndex, colIndex)
                    })
                )
              }, (cell: number, colIndex: number) => 'cell-' + rowIndex + '-' + colIndex + '-' + cell)
            }
            .justifyContent(FlexAlign.Start)
          }, (row: number[], rowIndex: number) => 'row-' + rowIndex + '-' + row.join(','))
        }
        .backgroundColor('#1A1A2E')
        .border({ width: 2, color: '#00E5FF', radius: 8 })
        .padding(10)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .width('100%')
      .height(350)
      .margin({ top: 5 })

      Text('点击: 填充/取消  |  长按: 标记X/取消')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 15, bottom: 10 })

      Row() {
        Button('重置')
          .width(90)
          .height(45)
          .fontSize(16)
          .backgroundColor('#1A1A2E')
          .fontColor('#FFD700')
          .border({ width: 2, color: '#FFD700', radius: 10 })
          .onClick(() => {
            this.resetGame()
          })

        Blank().width(15)

        Button('检查')
          .width(90)
          .height(45)
          .fontSize(16)
          .backgroundColor('#1A1A2E')
          .fontColor('#FFD700')
          .border({ width: 2, color: '#FFD700', radius: 10 })
          .onClick(() => {
            this.checkSolution()
          })

        Blank().width(15)

        Button('下一关')
          .width(90)
          .height(45)
          .fontSize(16)
          .backgroundColor('#1A1A2E')
          .fontColor('#FFD700')
          .border({ width: 2, color: '#FFD700', radius: 10 })
          .onClick(() => {
            this.nextLevel()
          })
      }
      .margin({ top: 5 })

      Row() {
        this.buildLegendItem('#00E5FF', '已填充')
        Blank().width(20)
        this.buildLegendItem('#0D0D1A', '空白')
        Blank().width(20)
        this.buildLegendItem('#1A1A2E', '标记X')
      }
      .margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildLegendItem(color: string, text: string) {
    Row() {
      Rect()
        .width(20)
        .height(20)
        .fill(color)
        .border({ width: 1, color: '#00E5FF' })
        .radius(4)
      Blank().width(5)
      Text(text)
        .fontSize(12)
        .fontColor('#888888')
    }
  }

  private getPuzzleCellColorWithHover(pieceIndex: number, row: number, col: number): string {
    if (this.isHoverCell(row, col)) {
      if (this.canPlaceAtHover()) {
        return this.hexToRgba(this.polyominoPieces[this.selectedPiece].color, 0.5)
      } else {
        return 'rgba(255, 68, 68, 0.5)'
      }
    }
    return this.getPuzzleCellColor(pieceIndex)
  }

  private getHoverBorderColor(row: number, col: number): string {
    if (this.isHoverCell(row, col)) {
      if (this.canPlaceAtHover()) {
        return '#00FF00'
      } else {
        return '#FF0000'
      }
    }
    return '#00E5FF'
  }

  private getPuzzleCellColor(pieceIndex: number): string {
    if (pieceIndex === -1) {
      return '#0A0A15'
    }
    if (pieceIndex === 0) {
      return '#1A1A2E'
    }
    return this.polyominoPieces[pieceIndex - 1].color
  }

  private getCellColor(state: number): string {
    switch (state) {
      case this.FILLED:
        return '#FFD700'
      case this.MARKED:
        return '#1A1A2E'
      default:
        return '#0D0D1A'
    }
  }

  private hexToRgba(hex: string, alpha: number): string {
    let r = parseInt(hex.slice(1, 3), 16)
    let g = parseInt(hex.slice(3, 5), 16)
    let b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
}
