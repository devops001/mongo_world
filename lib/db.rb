
require 'mongo'

class Database
  attr_reader :dbname, :rooms

  def initialize(dbname="mongo_world")
    @dbname = dbname
    @mongo  = Mongo::MongoClient.new('localhost')
    @db     = @mongo.db(@dbname)
    @rooms  = @db.collection('rooms')
    @items  = @db.collection('items')
    @mobs   = @db.collection('mobs')
    clear_all
    starting_room
  end

  def clear_all
    @rooms.remove()
    @items.remove()
    @mobs.remove()
  end

  def starting_room_name
    'home'
  end

  def starting_room
    room = @rooms.find_one({'name'=>starting_room_name})
    if not room
      id   = create_room(starting_room_name, "a small white room")
      room = @rooms.find_one(id)
    end
    room
  end

  #########################
  ## FIND
  #########################
  
  def find_room(name)
    @rooms.find_one({'name'=>name})
  end

  def find_item(name)
    @items.find_one({'name'=>name})
  end

  def find_mob(name)
    @mobs.find_one({'name'=>name})
  end

  #########################
  ## CREATE
  #########################

  def create_room(name, desc, linked_room_name=nil)
    doors = []
    if name != starting_room_name
      if linked_room_name
        doors << linked_room_name
      else
        doors << starting_room_name()
      end
      linked_room = find_room(doors.first)
      linked_room['doors'] << name
      @rooms.save(linked_room) 
    end
    @rooms.insert({'name'=>name, 'desc'=>desc, 'doors'=>doors, 'mobs'=>[], 'items'=>[]})
  end

  def create_item(name, desc)
    @items.insert({'name'=>name, 'desc'=>desc})
  end

  def create_mob(name, desc)
    @mobs.insert({'name'=>name, 'desc'=>desc})
  end

  #########################
  ## ADD
  #########################

  def add_item(room_name, item_name)
    room  = find_room(room_name)
    item  = find_item(item_name)
    room['items'] << item
    @rooms.save(room)
  end 

  def add_mob(room_name, mob_name)
    room = find_room(room_name)
    mob  = find_mob(mob_name)
    room['mobs'] << mob
    @rooms.save(room)
  end

  #########################
  ## LIST
  #########################

  def list_items_in_room(room_name, attr='name')
    room = find_room(room_name)
    room['items'].map{|item| item[attr]}.join(', ')
  end

  def list_mobs_in_room(room_name, attr='name')
    room = find_room(room_name)
    room['mobs'].map{|mob| mob[attr]}.join(', ')
  end

  def list_doors_in_room(room_name)
    find_room(room_name)['doors'].join(', ')
  end

end

