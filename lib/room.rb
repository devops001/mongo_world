
require_relative 'model'
require_relative 'door'

class Room < Model

  def initialize
    super
    set('name', '')
    set('desc', '')
    set('doors',[])
  end

  def save!
    same_name = self.class.collection.find({'name' => get('name')})
    if super
      same_name.each do |data|
        if data['_id'] != get('_id')
          puts "DELETE".colorize(:light_yellow) + " #{data.inspect}" if Model.debug
          self.class.collection.remove({'_id' => data['_id']})
        end
      end
      true
    else
      false
    end
  end

  def self.create!(name, desc)
    room = Room.new
    room.set('name', name)
    room.set('desc', desc)
    room.save!
    room
  end

  def connect!(other_room)
    already_connected = false
    doors.each { |door| already_connected=true if door['room_id']==other_room.get('_id') }
    if not already_connected
      doors << Door.new(other_room.name, other_room._id).to_h
      set('doors', doors)
      return false if not save!
    end
    already_connected = false
    other_doors       = other_room.get('doors')
    other_doors.each { |door| already_connected=true if door['room_id']==get('_id') }
    if not already_connected
      other_doors << Door.new(get('name'), get('_id')).to_h
      other_room.set('doors', other_doors)
      return false if not other_room.save!
    end
    true
  end

  def list_doors
    get('doors').map{|d| d['room_name']}.sort.join(', ')
  end

end
