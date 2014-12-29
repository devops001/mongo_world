
class Player
  attr_accessor :name, :room

  def initialize(db)
    @db   = db
    @name = "player"
    @room = @db.starting_room
  end

end

