
require_relative 'model'
require_relative 'room'

class Player < Model

  def initialize
    super
  end

  def self.create!(name, room)
    player = Player.new
    player.set(:name, name)
    player.room = room
    player
  end

  def room=(room)
    id = room.get('_id')
    set('room_id', id)
    save!
  end

  def room
    id = get('room_id')
    Room.find!(id)
  end

end

