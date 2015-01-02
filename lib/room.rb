
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

end
