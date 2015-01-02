
require_relative 'model'

class Room < Model

  @@home = nil

  def initialize
    super
    set(:name, '')
    set(:desc, '')
    set(:items, [])
    set(:mobs,  [])
    set(:doors, [])
    save!
  end

  def self.create(name, desc)
    room = Room.new
    room.set(:name, name)
    room.set(:desc, desc)
    room.save!
    room
  end

  def self.home
    if @@home.nil?
      @@home = Room.create('home', 'a small white room')
    else
      @@home.refresh!
    end
    @@home
  end

  def add_door_to(other_room)
    doors = get(:doors)
    doors << other_room._id
    set(:doors, doors)
    save!
    other_doors = other_room.get(:doors)
    other_doors << get(:_id)
    other_room.set(:doors, other_doors)
    other_room.save!
  end

end
