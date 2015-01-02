
require_relative 'model'

class Room < Model

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
    save!
  end

end
