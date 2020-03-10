require 'ruby2d'
set width: 1100, height:1000, title: "Slide Over by Savi, concept by CaryKH", fullscreen: false

class Game
  attr_reader :x, :y, :width, :height, :size
  def initialize(size, width, height, x, y)
    @x = x
    @y = y

    @width = width
    @height = height

    @size = size
    @grid = []

    @timerStart = 0
    @timeElapsed = 0
    @timerEnable = false
    @timerLabel = Text.new("0", x:850, y: 50, size: 28)
    @moves = 0
    @movesLabel = Text.new("0", x:850, y: 100, size: 28)

    buildGrid()
    renderGrid()
  end

  def buildGrid()
    pixels = @size ** 2
    letter = "a"
    pixels.times do
      @grid.push(Tile.new(@size, @width, letter))
      letter.next!
    end
    @grid.each_with_index do |tile, i|
      tile.row = i % @size
      tile.col = (i / @size).floor
      tile.correctRow = i % @size
      tile.correctCol = (i / @size).floor
    end
  end

  def renderGrid()
    @grid.each_with_index do |tile, i|
      indexInRow = i % @size
      currentCol = (i / @size).floor
      y = @y + currentCol * (@height / @size)
      x = @x + indexInRow * (@width  / @size)
      tile.model.x = x.to_i
      tile.model.y = y.to_i
      tile.name.x = (x + (@width / @size / 4.5)).to_i
      tile.name.y = (y - (@width / @size / 4.5)).to_i
      tile.model.color.r = 1 - (indexInRow / @size.to_f)
      tile.model.color.b = 1 - (currentCol / @size.to_f)
      tile.model.color.g = 0 + (currentCol / @size.to_f)
    end
  end

  def refresh()
    @grid.each_with_index do |tile, i|
      y = @y + tile.col * (@height / @size)
      x = @x + tile.row * (@width  / @size)
      tile.model.x = x.to_i
      tile.model.y = y.to_i
      tile.name.x = (x + (@width / @size / 4.5)).to_i
      tile.name.y = (y - (@width / @size / 4.5)).to_i
    end
  end

  def startTimer()
    @timerEnable = true
    @timerStart = Time.now.to_f
    @timeElapsed = 0
  end

  def stopTimer()
    @timerEnable = false
  end

  def timerStep()
    if @timerEnable
      @timeElapsed = (Time.now.to_f.round(2) - @timerStart.round(2)).round(2)
      @timerLabel.text = @timeElapsed.to_s
    end
    @movesLabel.text = @moves.to_s
  end

  def checkWinState()
    correctTiles = 0
    @grid.each do |tile|
      if tile.col == tile.correctCol && tile.row == tile.correctRow
        correctTiles += 1
      end
    end
    if correctTiles == @size ** 2
      stopTimer()
    end
  end

  def shuffle(shuffles = 100)
    shuffles.times do

      tile = @grid.sample(1)[0]
      direction = [-1,1].sample(1)[0]
      colorrow = ['col','row'].sample(1)[0]

      if colorrow == 'col'
        moveCol(tile.col, direction)
      elsif colorrow == 'row'
        moveRow(tile.row, direction)
      end

    end
    @moves = 0
  end

  def moveRow(row, direction)
    @moves += 1
    @grid.each_with_index do |tile, i|
      if tile.row == row
        tile.col += direction
        if tile.col >= @size
          tile.col = 0
        elsif tile.col < 0
          tile.col = @size - 1
        end
        refresh()
      end
    end
  end

  def moveCol(col, direction)
    @moves += 1
    @grid.each_with_index do |tile, i|
      if tile.col == col
        tile.row += direction
        if tile.row >= @size
          tile.row = 0
        elsif tile.row < 0
          tile.row = @size - 1
        end
        refresh()
      end
    end
  end

  def draggingFrom(from)
    if @timerEnable == false
      startTimer()
      @moves = 0
    end

    @draggedFrom = Struct.new(:x,:y,:col,:row).new(from.x, from.y, 0, 0)
    @grid.each do |tile|
      if tile.model.contains?(from.x, from.y)
        @draggedFrom.row = tile.row
        @draggedFrom.col = tile.col
      end
    end
  end

  def draggedTo(now)
    if @draggedFrom.x - (@width / @size) >= now.x || @draggedFrom.x + (@width / @size) <= now.x
      if now.x > @draggedFrom.x
        moveCol(@draggedFrom.col, 1)
      elsif now.x < @draggedFrom.x
        moveCol(@draggedFrom.col,-1)
      end
      draggingFrom(now)
    elsif @draggedFrom.y - (@width / @size) >= now.y || @draggedFrom.y + (@width / @size) <= now.y
      if now.y > @draggedFrom.y
        moveRow(@draggedFrom.row, 1)
      elsif now.y < @draggedFrom.y
        moveRow(@draggedFrom.row,-1)
      end
      draggingFrom(now)
    end
  end

end

class Tile
  attr_accessor :model, :name, :row, :col, :correctRow, :correctCol
  def initialize(tiles, width, letter)
    margin = 0
    @row = 0
    @col = 0
    @correctCol = 0
    @correctRow = 0
    @size = (width / tiles) - margin
    @name = Text.new(letter, x: 0, y:0, size: (@size * 0.8), z: 100)
    @model = Square.new(x: 0, y: 0, size: @size)
  end
end

game = Game.new(5, 800,800, 10, 10)
game.shuffle(0)

update do
  game.timerStep
  game.checkWinState
end

on :mouse do |event|
  if @dragging == nil
    @dragging = {}
  end
  if event.type == :down
    @dragging[event.button] = true
    @dragging[:from] = Struct.new(:x,:y).new(event.x, event.y)
    game.draggingFrom(@dragging[:from])
  end
  if event.type == :up
    @dragging[event.button] = false
  end

  if @dragging[:left]
    if event.x.between?(game.x, game.x + game.width) && event.y.between?(game.y, game.y + game.height)
      game.draggedTo(Struct.new(:x,:y).new(event.x, event.y))
    end
  end
end

show()
