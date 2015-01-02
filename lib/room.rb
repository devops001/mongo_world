
require_relative 'model'
require_relative 'door'

class Room < Model

  @@home = nil

  def initialize
    super
    set('name', '')
    set('desc', '')
    set('items', [])
    set('mobs',  [])
    set('doors', [])
    save!
  end

  def self.create(name, desc)
    room = Room.new
    room.set('name', name)
    room.set('desc', desc)
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

  def connect(other_room)
    already_connected = false
    doors.each { |door| already_connected=true if door['room_id']==other_room.get('_id') }
    if not already_connected
      doors << Door.new(other_room.name, other_room._id).to_h
      set('doors', doors)
      save!
    end
    already_connected = false
    other_doors       = other_room.get('doors')
    other_doors.each { |door| already_connected=true if door['room_id']==get('_id') }
    if not already_connected
      other_doors << Door.new(get('name'), get('_id')).to_h
      other_room.set('doors', other_doors)
      other_room.save!
    end
  end

  def list_doors
    get('doors').map{|d| d['room_name']}.sort.join(', ')
  end

end
