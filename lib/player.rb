
require_relative 'model'
require_relative 'room'

class Player < Model

  def initialize
    super
  end

  def self.create(name, room)
    player      = Player.new
    player.room = room
    player.set(:name, name)
    player.save!
    player
  end

  def room=(room)
    set(:room_id, room.get(:_id))
  end

  def room
    Room.find(get(:room_id))
  end

  def name
    get(:name)
  end

end

