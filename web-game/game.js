/* ====================
   Delta修复 - 游戏逻辑
   ==================== */

// 游戏状态
const state = {
    currentLevel: 0,
    steps: 0,
    gridState: [],
    rowHints: [],
    columnHints: [],
    showPuzzle: false,
    nonogramCompleted: false,
    filledCells: [],
    showCompletionLink: false,
    
    // 拼图状态
    puzzleGrid: [],
    selectedPiece: -1,
    pieceRotation: [0, 0, 0, 0],
    placedPieces: 0
};

// 常量
const GRID_SIZE = 5;
const EMPTY = 0;
const FILLED = 1;
const MARKED = 2;

// 谜题数据
const puzzles = [
    [
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0],
        [1, 1, 1, 1, 1],
        [0, 0, 1, 0, 0],
        [0, 0, 1, 0, 0]
    ],
    [
        [1, 1, 0, 0, 0],
        [0, 1, 1, 0, 0],
        [0, 0, 1, 1, 0],
        [0, 0, 0, 1, 1],
        [0, 0, 0, 0, 1]
    ],
    [
        [1, 1, 1, 0, 0],
        [1, 1, 1, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 1, 1, 1, 0],
        [0, 0, 1, 0, 0]
    ]
];

// 拼图模块
const polyominoPieces = [
    { name: '长条', shape: [[1, 1, 1]], color: '#FF6B6B' },
    { name: '方块', shape: [[1, 1], [1, 1]], color: '#4ECDC4' },
    { name: 'L形', shape: [[1, 0], [1, 1]], color: '#FFE66D' },
    { name: '直线', shape: [[1, 1]], color: '#95E1D3' }
];

// ==================== 
// 初始化
// ==================== 
function init() {
    initNonogramGame();
    updateUI();
}

function initNonogramGame() {
    state.gridState = [];
    for (let i = 0; i < GRID_SIZE; i++) {
        state.gridState.push(new Array(GRID_SIZE).fill(EMPTY));
    }
    state.steps = 0;
    calculateHints();
}

function calculateHints() {
    const solution = puzzles[state.currentLevel];
    state.rowHints = [];
    state.columnHints = [];

    // 计算行提示
    for (let i = 0; i < GRID_SIZE; i++) {
        const hint = [];
        let count = 0;
        for (let j = 0; j < GRID_SIZE; j++) {
            if (solution[i][j] === FILLED) {
                count++;
            } else if (count > 0) {
                hint.push(count);
                count = 0;
            }
        }
        if (count > 0) hint.push(count);
        state.rowHints.push(hint.length > 0 ? hint : [0]);
    }

    // 计算列提示
    for (let j = 0; j < GRID_SIZE; j++) {
        const hint = [];
        let count = 0;
        for (let i = 0; i < GRID_SIZE; i++) {
            if (solution[i][j] === FILLED) {
                count++;
            } else if (count > 0) {
                hint.push(count);
                count = 0;
            }
        }
        if (count > 0) hint.push(count);
        state.columnHints.push(hint.length > 0 ? hint : [0]);
    }
}

// ==================== 
// UI渲染
// ==================== 
function updateUI() {
    updateLevelInfo();
    renderGrid();
    renderHints();
    
    // 更新界面显示
    document.getElementById('nonogram-section').classList.toggle('active', !state.showPuzzle && !state.showCompletionLink);
    document.getElementById('puzzle-section').classList.toggle('active', state.showPuzzle && !state.showCompletionLink);
    document.getElementById('completion-section').classList.toggle('active', state.showCompletionLink);
    
    if (state.showPuzzle) {
        renderPuzzleGrid();
        renderPuzzlePieces();
        updatePuzzleProgress();
    }
}

function updateLevelInfo() {
    document.getElementById('level-text').textContent = `关卡 ${state.currentLevel + 1} / ${puzzles.length}`;
    document.getElementById('steps-text').textContent = `步数: ${state.steps}`;
}

function renderHints() {
    // 渲染列提示（包含左上角空白）
    const colHintsEl = document.getElementById('column-hints');
    colHintsEl.innerHTML = '';
    
    // 左上角空白区域
    const emptyCorner = document.createElement('div');
    emptyCorner.className = 'column-hint';
    colHintsEl.appendChild(emptyCorner);
    
    // 列提示
    state.columnHints.forEach(hint => {
        const colDiv = document.createElement('div');
        colDiv.className = 'column-hint';
        hint.forEach(num => {
            const span = document.createElement('span');
            span.textContent = num;
            colDiv.appendChild(span);
        });
        colHintsEl.appendChild(colDiv);
    });

    // 渲染行提示
    const rowHintsEl = document.getElementById('row-hints');
    rowHintsEl.innerHTML = '';
    state.rowHints.forEach(hint => {
        const rowDiv = document.createElement('div');
        rowDiv.className = 'row-hint';
        hint.forEach(num => {
            const span = document.createElement('span');
            span.textContent = num;
            rowDiv.appendChild(span);
        });
        rowHintsEl.appendChild(rowDiv);
    });
}

function renderGrid() {
    const gridEl = document.getElementById('grid');
    gridEl.innerHTML = '';
    
    for (let i = 0; i < GRID_SIZE; i++) {
        for (let j = 0; j < GRID_SIZE; j++) {
            const cell = document.createElement('div');
            cell.className = 'cell';
            
            if (state.gridState[i][j] === FILLED) {
                cell.classList.add('filled');
            } else if (state.gridState[i][j] === MARKED) {
                cell.classList.add('marked');
            }
            
            // 点击事件
            cell.addEventListener('click', () => onCellClick(i, j));
            
            // 长按事件（标记X）
            let pressTimer;
            cell.addEventListener('touchstart', (e) => {
                pressTimer = setTimeout(() => {
                    onCellLongPress(i, j);
                }, 500);
            });
            cell.addEventListener('touchend', () => {
                clearTimeout(pressTimer);
            });
            cell.addEventListener('touchmove', () => {
                clearTimeout(pressTimer);
            });
            
            // 右键事件（PC端）
            cell.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                onCellLongPress(i, j);
            });
            
            gridEl.appendChild(cell);
        }
    }
}

// ==================== 
// 游戏逻辑
// ==================== 
function onCellClick(row, col) {
    if (state.gridState[row][col] === FILLED) {
        state.gridState[row][col] = EMPTY;
    } else {
        state.gridState[row][col] = FILLED;
    }
    state.steps++;
    updateUI();
}

function onCellLongPress(row, col) {
    if (state.gridState[row][col] === MARKED) {
        state.gridState[row][col] = EMPTY;
    } else {
        state.gridState[row][col] = MARKED;
    }
    state.steps++;
    updateUI();
}

function checkSolution() {
    const solution = puzzles[state.currentLevel];
    let isCorrect = true;

    for (let i = 0; i < GRID_SIZE; i++) {
        for (let j = 0; j < GRID_SIZE; j++) {
            const playerFilled = state.gridState[i][j] === FILLED;
            const solutionFilled = solution[i][j] === FILLED;
            if (playerFilled !== solutionFilled) {
                isCorrect = false;
                break;
            }
        }
        if (!isCorrect) break;
    }

    if (isCorrect) {
        // 记录填充的格子
        state.filledCells = [];
        for (let i = 0; i < GRID_SIZE; i++) {
            for (let j = 0; j < GRID_SIZE; j++) {
                if (state.gridState[i][j] === FILLED) {
                    state.filledCells.push([i, j]);
                }
            }
        }
        
        initPuzzleForFilledCells();
        state.nonogramCompleted = true;
        state.showPuzzle = true;
        
        showToast('数织完成！现在用拼图填充');
        updateUI();
    } else {
        showToast('答案不正确，请继续尝试');
    }
}

function resetGame() {
    initNonogramGame();
    updateUI();
    showToast('已重置游戏');
}

function nextLevel() {
    state.currentLevel = (state.currentLevel + 1) % puzzles.length;
    state.showPuzzle = false;
    state.nonogramCompleted = false;
    state.showCompletionLink = false;
    initNonogramGame();
    updateUI();
    showToast(`第 ${state.currentLevel + 1} 关`);
}

// ==================== 
// 拼图逻辑
// ==================== 
function initPuzzleForFilledCells() {
    state.puzzleGrid = [];
    for (let i = 0; i < GRID_SIZE; i++) {
        const row = [];
        for (let j = 0; j < GRID_SIZE; j++) {
            row.push(-1); // -1表示不可用
        }
        state.puzzleGrid.push(row);
    }
    
    // 标记可用区域
    state.filledCells.forEach(([r, c]) => {
        state.puzzleGrid[r][c] = 0; // 0表示可用
    });
    
    state.selectedPiece = -1;
    state.pieceRotation = [0, 0, 0, 0];
    state.placedPieces = 0;
}

function renderPuzzleGrid() {
    const gridEl = document.getElementById('puzzle-grid');
    gridEl.innerHTML = '';
    gridEl.style.gridTemplateColumns = `repeat(${GRID_SIZE}, 50px)`;
    
    for (let i = 0; i < GRID_SIZE; i++) {
        for (let j = 0; j < GRID_SIZE; j++) {
            const cell = document.createElement('div');
            cell.className = 'puzzle-cell';
            
            const value = state.puzzleGrid[i][j];
            if (value === -1) {
                cell.classList.add('unavailable');
            } else if (value === 0) {
                cell.classList.add('available');
            } else {
                cell.style.background = polyominoPieces[value - 1].color;
            }
            
            cell.addEventListener('click', () => onPuzzleCellClick(i, j));
            gridEl.appendChild(cell);
        }
    }
}

function renderPuzzlePieces() {
    const piecesEl = document.getElementById('puzzle-pieces');
    piecesEl.innerHTML = '';
    
    polyominoPieces.forEach((piece, index) => {
        const pieceEl = document.createElement('div');
        pieceEl.className = 'puzzle-piece';
        if (state.selectedPiece === index) {
            pieceEl.classList.add('selected');
        }
        
        const shape = getRotatedShape(index);
        const shapeGrid = document.createElement('div');
        shapeGrid.style.display = 'grid';
        shapeGrid.style.gridTemplateColumns = `repeat(${shape[0].length}, 20px)`;
        shapeGrid.style.gap = '0';
        
        shape.forEach(row => {
            row.forEach(cell => {
                const cellEl = document.createElement('div');
                cellEl.style.width = '20px';
                cellEl.style.height = '20px';
                cellEl.style.background = cell === 1 ? piece.color : 'transparent';
                cellEl.style.borderRadius = '0';
                cellEl.style.border = cell === 1 ? '1px solid rgba(0, 229, 255, 0.5)' : 'none';
                cellEl.style.boxSizing = 'border-box';
                shapeGrid.appendChild(cellEl);
            });
        });
        
        pieceEl.appendChild(shapeGrid);
        
        const nameEl = document.createElement('div');
        nameEl.className = 'puzzle-piece-name';
        nameEl.textContent = piece.name;
        pieceEl.appendChild(nameEl);
        
        pieceEl.addEventListener('click', () => {
            if (state.selectedPiece === index) {
                // 旋转
                state.pieceRotation[index] = (state.pieceRotation[index] + 1) % 4;
                showToast('已旋转模块');
            } else {
                state.selectedPiece = index;
            }
            updateUI();
        });
        
        piecesEl.appendChild(pieceEl);
    });
}

function updatePuzzleProgress() {
    document.getElementById('puzzle-progress').textContent = 
        `已放置: ${state.placedPieces} / ${state.filledCells.length} 格`;
}

function getRotatedShape(pieceIndex) {
    const piece = polyominoPieces[pieceIndex];
    let shape = piece.shape.map(row => [...row]);
    const rotation = state.pieceRotation[pieceIndex];
    
    for (let r = 0; r < rotation; r++) {
        const newShape = [];
        const rows = shape.length;
        const cols = shape[0].length;
        for (let j = 0; j < cols; j++) {
            const newRow = [];
            for (let i = rows - 1; i >= 0; i--) {
                newRow.push(shape[i][j]);
            }
            newShape.push(newRow);
        }
        shape = newShape;
    }
    return shape;
}

function onPuzzleCellClick(row, col) {
    if (state.puzzleGrid[row][col] === -1) {
        showToast('该区域不可放置');
        return;
    }
    
    if (state.selectedPiece === -1) {
        showToast('请先选择一个模块');
        return;
    }
    
    if (state.puzzleGrid[row][col] > 0) {
        showToast('该位置已被占用');
        return;
    }
    
    if (canPlacePiece(state.selectedPiece, row, col)) {
        placePiece(state.selectedPiece, row, col);
        state.selectedPiece = -1;
        checkPuzzleComplete();
    } else {
        showToast('无法放置：超出边界或重叠');
    }
}

function canPlacePiece(pieceIndex, startRow, startCol) {
    const shape = getRotatedShape(pieceIndex);
    const rows = shape.length;
    const cols = shape[0].length;
    
    if (startRow + rows > GRID_SIZE || startCol + cols > GRID_SIZE) {
        return false;
    }
    
    for (let i = 0; i < rows; i++) {
        for (let j = 0; j < cols; j++) {
            if (shape[i][j] === 1) {
                if (state.puzzleGrid[startRow + i][startCol + j] !== 0) {
                    return false;
                }
            }
        }
    }
    return true;
}

function placePiece(pieceIndex, startRow, startCol) {
    const shape = getRotatedShape(pieceIndex);
    const rows = shape.length;
    const cols = shape[0].length;
    
    for (let i = 0; i < rows; i++) {
        for (let j = 0; j < cols; j++) {
            if (shape[i][j] === 1) {
                state.puzzleGrid[startRow + i][startCol + j] = pieceIndex + 1;
            }
        }
    }
    state.placedPieces++;
    updateUI();
}

function checkPuzzleComplete() {
    let filledCount = 0;
    for (let i = 0; i < GRID_SIZE; i++) {
        for (let j = 0; j < GRID_SIZE; j++) {
            if (state.puzzleGrid[i][j] > 0) {
                filledCount++;
            }
        }
    }
    
    if (filledCount === state.filledCells.length) {
        if (state.currentLevel === 2) {
            state.showCompletionLink = true;
            showToast('恭喜通关！所有关卡已完成');
        } else {
            showToast(`恭喜通关！第 ${state.currentLevel + 1} 关完成`);
            setTimeout(nextLevel, 2500);
        }
        updateUI();
    }
}

function resetPuzzle() {
    initPuzzleForFilledCells();
    updateUI();
    showToast('已重置拼图');
}

function restartGame() {
    state.currentLevel = 0;
    state.showCompletionLink = false;
    state.showPuzzle = false;
    state.nonogramCompleted = false;
    initNonogramGame();
    updateUI();
}

// ==================== 
// 工具函数
// ==================== 
function showToast(message) {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 2000);
}

// 初始化游戏
window.addEventListener('DOMContentLoaded', init);
