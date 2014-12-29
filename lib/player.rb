
class Player
  attr_reader :name, :room

  def initialize(db)
    @db   = db
    @name = "player"
    @room = @db.starting_room
  end

  def update
    @room = @db.find_room({'name'=>@room['name']})
  end

end

