
require 'mongo'

class Database
  attr_reader :dbname

  def initialize(dbname="mongo_world")
    @dbname = dbname
    @mongo  = Mongo::MongoClient.new('localhost')
    @db     = @mongo.db(@dbname)
    @rooms  = @db.collection('rooms')
    @items  = @db.collection('items')
    @mobs   = @db.collection('mobs')
    clear_all
  end

  def clear_all
    @rooms.remove()
    @items.remove()
    @mobs.remove()
  end

  def starting_room
    name = 'starting_room'
    room = @rooms.find_one({'name'=>name})
    if not room
      id   = create_room(name, "a small white room")
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

  def create_room(name, desc, mobs=[], items=[])
    @rooms.insert({'name'=>name, 'desc'=>desc, 'mobs'=>mobs, 'items'=>items})
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

end

