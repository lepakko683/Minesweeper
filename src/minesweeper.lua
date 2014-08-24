--Minesweeper game for TI-nspire calculators

--images TODO: convert images to strings (support for older OS versions)
image_unchecked = image.new(_R.IMG.unchecked)
image_checked = image.new(_R.IMG.checked)
image_mine = image.new(_R.IMG.mine)
image_flag = image.new(_R.IMG.flag)

--images scaled for ui
ui_mine = image.copy(image_mine, 26, 26)
ui_flag = image.copy(image_flag, 26, 26)
ui_unchecked = image.copy(image_unchecked, 16, 16)

--textures (the images that are used for drawing, scaled to right size)
img_unchecked = image.copy(image_unchecked, 64, 64)
img_checked = image.copy(image_checked, 64, 64)
img_mine = image.copy(image_mine, 64, 64)
img_flag = image.copy(image_flag, 64, 64)

--rendering
renderImage = true
currImg = img_unchecked
renderExtra = 0 --0 = nothing, 1 = flag, 2 = mine, 3 = number of mines around

screen = platform.window
scrWidth = screen:width()
scrHeight = screen:height()
mineFieldWidth = math.min(scrWidth, scrHeight)

----[TODO]----
--Only one var for tileWidth (remove tileHeight)


--0 = empty unchecked, 1 = mine, 2 = emptyFlagged, 3 = mineFlagged, 4 = empty checked, 5 = empty checked x mine(s) around
mineField = {}
curLoc = 3 --index of the spot in mineField array that the "cursor" is over
fieldWidth = 10 --in tiles
fieldHeight = 10 --in tiles
fieldMines = 15
tileWidth = 0 --in pixels
tileHeight = 0 --in pixels

--player-related vars
playerDead = false
flagsLeft = fieldMines
landUnchecked = fieldWidth*fieldHeight

function on.construction()
    print("-------------------------------")
    initGame()
    initMineField(fieldWidth,fieldHeight,fieldMines)
    placeMines()
end

function on.paint(gc)
    --Black background for the field
    gc:setColorRGB(0,0,0)
    gc:fillRect(0,0,mineFieldWidth+1,scrHeight)
    
    --Light gray background for info
    gc:setColorRGB(180,180,180)
    gc:fillRect(mineFieldWidth+1,0,scrWidth-mineFieldWidth+1,scrHeight)
    
    local tileType = 0
    for i=0, fieldWidth*fieldHeight-1 do
        tileType = mineField[i]
        if tileType == 0 then
            gc:setColorRGB(0,255,0)
            currImg = img_unchecked
            renderExtra = 0
        end
        if tileType == 1 then
            gc:setColorRGB(255,0,0)
            currImg = img_unchecked
            renderExtra = 0--2 --TODO: change 2 to 0 when done [DEBUG]
        end
        if tileType == 2 or tileType == 3 then
            gc:setColorRGB(255,255,255)
            currImg = img_unchecked
            renderExtra = 1
        end
        if tileType > 3 and tileType < 14 then
            currImg = img_checked
            renderExtra = 3
        end
        drawTile(gc, i)
    end
   
    --draw cursor
    gc:setColorRGB(0,0,255)
    gc:drawRect((curLoc%fieldWidth)*tileWidth+2, math.floor(curLoc/fieldWidth)*tileHeight+2,tileWidth-4,tileHeight-4)
    if playerDead == true then
        local boomWidth = gc:getStringWidth("BOOM!")
        local boomHeight = gc:getStringHeight("BOOM!")
        gc:setColorRGB(0,0,0)
        gc:fillRect(scrWidth/2-(boomWidth+12)/2, scrHeight/2-(boomHeight+9)/2, boomWidth+12, boomHeight+9)
        gc:setColorRGB(255,255,255)
        gc:drawRect(scrWidth/2-(boomWidth+12)/2, scrHeight/2-(boomHeight+9)/2, boomWidth+12, boomHeight+9)
        gc:setColorRGB(255,0,0)
        gc:drawString("BOOM!", scrWidth/2-boomWidth/2, scrHeight/2-boomHeight/2)
    end
    drawUI(gc)
end

--draws the UI on the right side of the minefield
function drawUI(gc)
    gc:setColorRGB(0,0,0)
    
    --Mine count
    gc:drawImage(ui_mine, mineFieldWidth, 0)
    gc:drawString(" =" .. fieldMines, mineFieldWidth+18, 0)
    
    --Land to check left
    gc:drawImage(ui_unchecked, mineFieldWidth+5, 26)
    gc:drawString(" : " .. landUnchecked, mineFieldWidth+18, 22)
    
    --Flags left
    gc:drawImage(ui_flag, mineFieldWidth-1, 42)
    gc:drawString(" : " .. flagsLeft, mineFieldWidth+18, 44)
end

function getMinesAround(index)
    local ret = 0
    local checkPos = 0
    
    for y = -1, 1 do
        for x = -1, 1 do
            if not(index%fieldWidth == 0 and x < 0) then
                if not(index%fieldWidth == fieldWidth-1 and x > 0) then
                    checkPos = index + y*fieldWidth+x
                    if checkPos >= 0 and checkPos < fieldWidth*fieldHeight then
                        if mineField[checkPos] == 1 or mineField[checkPos] == 3 then
                            ret = ret + 1
                        end
                    end
                end
            end
        end
    end
    return ret
end

function openAround(index)
    if mineField[index] == 0 then
        if openSpot(index) == false then
            return
        end
        if index + fieldWidth < fieldWidth*fieldHeight then
            openAround(index+fieldWidth)
        end
        if index - fieldWidth > -1 then
            openAround(index-fieldWidth)
        end
        if index%fieldWidth < fieldWidth-1 then
            openAround(index+1)
        end
        if index%fieldWidth > 0 then
            openAround(index-1)
        end
    end
end

function openSpot(index)
    local mAr = getMinesAround(index)
    mineField[index] = 4 + mAr
    screen:invalidate()
    if mAr > 0 then
        return false
    else
        return true
    end
end

function checkSpot()
    if mineField[curLoc] == 0 then
        --mineField[curLoc] = 4 + getMinesAround(curLoc)
        openAround(curLoc)
    end
    if mineField[curLoc] == 1 then
        playerDead = true
    end
    screen:invalidate()
end

function flagSpot()
    if mineField[curLoc] < 2 and flagsLeft > 0 then
        mineField[curLoc] = mineField[curLoc] + 2
        flagsLeft = flagsLeft - 1
    else
        if mineField[curLoc] == 2 or mineField[curLoc] == 3 then
            mineField[curLoc] = mineField[curLoc] - 2
            flagsLeft = flagsLeft + 1
        end
    end
    screen:invalidate()
end

function moveCursor(key)
    if key == "left" and (curLoc % fieldWidth > 0) then
        curLoc = curLoc - 1
    end
    if key == "right" and (curLoc % fieldWidth < fieldWidth-1) then
        curLoc = curLoc + 1
    end
    if key == "up" and (math.floor(curLoc / fieldWidth) > 0) then
        curLoc = curLoc - fieldWidth
    end
    if key == "down" and (math.floor(curLoc / fieldWidth) < fieldHeight-1) then
        curLoc = curLoc + fieldWidth
    end
    screen:invalidate()
end

function drawTile(gc,index)
    local tilex = (index%fieldWidth)*tileWidth
    local tiley = math.floor(index/fieldWidth)*tileHeight
    --change to drawImage
    gc:drawImage(currImg, tilex, tiley, tileWidth, tileHeight)
    --gc:fillRect(tilex, tiley, tileWidth, tileHeight)
    
    if renderExtra == 1 then
        gc:drawImage(img_flag, tilex, tiley, tileWidth, tileHeight)
    end
    if renderExtra == 2 then
        gc:drawImage(img_mine, tilex, tiley, tileWidth, tileHeight)
    end
    if renderExtra == 3 then
        local minesAr = mineField[index]-4
        if minesAr > 0 then
            gc:setColorRGB(255,0,0)
            gc:drawString(minesAr, tilex+(tileWidth/2-gc:getStringWidth(minesAr)/2), tiley+(tileHeight/2-gc:getStringHeight(minesAr)/2))
        end
    end
end

--initialize tile width etc.
function initGame()
    math.randomseed(timer.getMilliSecCounter())
    playerDead = false
    curLoc=0
    tileWidth = math.floor(mineFieldWidth/fieldWidth)
    tileHeight = math.floor(mineFieldWidth/fieldHeight)
    img_unchecked = image.copy(image_unchecked, tileWidth, tileHeight)
    img_checked = image.copy(image_checked, tileWidth, tileHeight)
    img_mine = image.copy(image_mine, tileWidth, tileHeight)
    img_flag = image.copy(image_flag, tileWidth, tileHeight)
end

function initMineField(width, height, mines)
    if width > 64 or height > 64 then
        return --There needs to be a limit
    end
    for i=0, width*height-1 do
        mineField[i]=0
    end
end

function resetGame()
    initMineField(fieldWidth, fieldHeight, 0)
    playerDead = false
    flagsLeft = fieldMines
    placeMines()
end

function placeMines()
    if fieldWidth < 2 and fieldHeight < 2 then
        return
    end
    
    if fieldWidth*fieldHeight < fieldMines then
        fieldMines = math.floor((fieldWidth/2)*(fieldHeight/2))
    end
    
    local killLoop = 1000
    local placedMines = 0
    local randNum = 0
    
    while placedMines < fieldMines and killLoop > 0 do
        randNum = math.random(fieldWidth*fieldHeight-1)
        if mineField[randNum] == 0 then
            mineField[randNum] = 1
            placedMines = placedMines + 1
        end
        killLoop = killLoop - 1
    end
    print("FieldMines: " .. fieldMines)
    print("Field size: " .. fieldWidth .. " x " .. fieldHeight)
    print("PlacedMines: " .. placedMines)
    if killLoop > 0 then
        print("Placed " .. placedMines .. " mines successfully after " .. 1000-killLoop .. " cycles")
    else
        print("Mine placing failed")
    end
end

function on.arrowKey(key)
    moveCursor(key)
end

function on.enterKey()
    checkSpot()
end

function on.tabKey()
    flagSpot()
end
