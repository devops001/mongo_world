
require_relative 'db'
require_relative 'model'

class World
  attr_reader :home, :user, :current_room

  def initialize(dbname)
    @dbname = dbname
    @db     = Db.new(dbname)
    @home   = create_room!('home', 'a home')
    @user   = create_user!('user', 'a user', @home._id)
    update_current_room!
  end

  def update_current_room!
    @current_room = Model.new(@db, 'rooms', @user.room_id)
  end

  ########################
  ## saving:
  ########################

  def save!(saved_name)
    saved          = Model.new(@db, 'saves', get_save_id!(saved_name))
    saved.rooms    = @db.all!('rooms')
    saved.users    = @db.all!('users')
    saved.user_id  = @user._id
    saved.home_id  = @home._id
    saved.name     = saved_name
    saved.saved_at = Time.now
    saved.save!
    saved
  end

  def load_save!(saved_name)
    id = get_save_id!(saved_name)
    return false if id.nil?
    destroy_collections!
    saved = Model.new(@db, 'saves', id)
    saved.rooms.each do |room_data|
      @db.save!('rooms', room_data)
    end
    saved.users.each do |user_data|
      @db.save!('users', user_data)
    end
    @home = Model.new(@db, 'rooms', saved.home_id)
    @user = Model.new(@db, 'users', saved.user_id)
    @current_room = Model.new(@db, 'rooms', @user.room_id)
    true
  end

  def get_save_names!
    @db.all!('saves').map{|d| d['name']}
  end

  def get_save_id!(name)
    found = []
    @db.all!('saves').each do |data|
      found << data if data['name'] == name
    end
    return found.count==1 ? found[0]['_id'] : nil
  end

  def destroy_save!(name)
    id = get_save_id!(name)
    if id
      @db.destroy!('saves', id)
      true
    else
      false
    end
  end

  ########################
  ## doors:
  ########################

  def create_doors!(room1, room2)
    index1 = get_door_index(room1.doors, room2.name)
    index2 = get_door_index(room2.doors, room1.name)
    if index1.nil?
      room1.doors << create_door_data(room2)
    else
      room1.doors[index1] = create_door_data(room2)
    end
    if index2.nil?
      room2.doors << create_door_data(room1)
    else
      room2.doors[index2] = create_door_data(room1)
    end
    room1.save!
    room2.save!
  end

  def remove_doors!(room1, room2)
    index1 = get_door_index(room1.doors, room2.name)
    index2 = get_door_index(room2.doors, room1.name)
    if index1
      room1.doors.delete_at(index1)
      room1.save!
    end
    if index2
      room2.doors.delete_at(index2)
      room2.save!
    end
  end

  def get_room_from_door(room_name)
    index = get_door_index(@current_room.doors, room_name)
    index.nil? ? nil : Model.new(@db, 'rooms', @current_room.doors[index]['room_id'])
  end

  def create_door_data(room)
    {'room_id'=>room._id, 'room_name'=>room.name}
  end
  
  def get_door_index(doors, room_name)
    index = nil
    doors.each_with_index do |door,i|
      if door['room_name'] == room_name
        index = i
        break
      end
    end
    index
  end

  ########################
  ## database:
  ########################

  def set_debug(bool)
    @db.set_debug(bool)
  end

  def debug?
    @db.debug?
  end

  def collection_names
    %w/rooms users items/
  end

  def destroy_collections!
    collection_names.each { |name| @db.destroy_collection!(name) }
  end

  def destroy_database!
    @db.destroy_all!
  end

  ########################
  ## rooms:
  ########################

  def find_room!(_id)
    data = @db.find!('rooms', _id)
    data.nil? ? nil : create_room_from_data(data)
  end 

  def find_rooms!
    rooms = []
    @db.all!('rooms').each do |data|
      rooms << create_room_from_data(data)
    end
    rooms
  end

  def create_room(name, desc)
    room       = Model.new(@db, 'rooms')
    room.name  = name
    room.desc  = desc
    room.items = []
    room.mobs  = []
    room.doors = []
    room
  end

  def create_room!(name, desc)
    room = create_room(name, desc)
    room.save!
    room
  end

  def create_room_from_data(data)
    room       = Model.new(@db, 'rooms')
    room._id   = data['_id']
    room.name  = data['name']  or 'room'
    room.desc  = data['desc']  or 'a room'
    room.doors = data['doors'] or []
    room.items = data['items'] or []
    room.mobs  = data['mobs']  or []
    room
  end

  def get_remembered_room
    return nil if @user.remembered.nil?
    find_room!(@user.remembered['room_id'])
  end

  ########################
  ## users:
  ########################

  def find_users!
    users = []
    @db.all!('users').each do |data|
      users << create_user_from_data(data)
    end
    users
  end

  def create_user(name, desc, room_id)  
    user            = Model.new(@db, 'users')
    user.name       = name
    user.desc       = desc
    user.room_id    = room_id
    user.remembered = nil
    user
  end

  def create_user!(name, desc, room_id)
    user = create_user(name, desc, room_id)
    user.save!
    user
  end

  def create_user_from_data(data)
    user            = Model.new(@db, 'users')
    user.name       = data['name']       or 'user'
    user.desc       = data['desc']       or 'a user'
    user.room_id    = data['room_id']    or @home._id
    user.remembered = data['remembered'] or nil
    user
  end

  ########################
  ## items:
  ########################

  def create_item_data(name, desc)
    {'name'=>name, 'desc'=>desc}
  end

  def get_item_data(room, item_name)
    room.items.each do |item|
      return item if item['name'] == item_name
    end
    nil
  end

  def get_item_index(room, item_name)
    room.items.each_with_index do |item, i|
      return i if item['name'] == item_name
    end
    nil
  end

  def upsert_item!(room, item_data)
    index = get_item_index(room, item_data['name'])
    if index
      room.items[index] = item_data
    else
      room.items << item_data
    end
    room.save!
  end

  def destroy_item!(room, item_name)
    index = get_item_index(room, item_name)
    if index
      room.items.delete_at(index)
      room.save!
      true
    else
      false
    end
  end

  ########################
  ## mobs:
  ########################

  def create_mob_data(name, desc)
    {'name'=>name, 'desc'=>desc}
  end

end

