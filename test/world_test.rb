
require_relative '../lib/world'
require 'minitest/autorun'

class WorldTest < Minitest::Test

  def setup
    @world = World.new('testdb')
    @db    = @world.instance_variable_get(:@db)
  end

  def teardown
    @world.destroy_database!
  end

  def test_instance_models
    assert(@world.home._id)
    assert(@world.user._id) 
  end

  def test_collection_names
    assert_equal(3, @world.collection_names.count)
  end

  def test_destroy_collections!
    assert(@world.all_rooms!.count, 1)
    assert(@world.find_users!.count, 1)
    @world.destroy_collections!
    assert(@world.all_rooms!.count, 0)
    assert(@world.find_users!.count, 0)
  end

  def test_destroy_database!
    assert(@world.all_rooms!.count, 1)
    assert(@world.find_users!.count, 1)
    @world.destroy_database!
    assert(@world.all_rooms!.count, 0)
    assert(@world.find_users!.count, 0)
  end

  def test_create_room
    assert(@world.all_rooms!.count, 1)
    10.times.each do |i|
      name = "room_#{i}"
      desc = "a room with a #{i} painted on the wall"
      room = @world.create_room(name, desc)
      room.save!
      assert_equal(name, room.name)
      assert_equal(desc, room.desc)
    end
    assert(@world.all_rooms!.count, 11)
  end

  def test_update_current_room!
    assert_equal('home', @world.current_room.name)

    data = @db.find!('rooms', @world.current_room._id)
    data['color'] = 'blue'
    @db.save!('rooms', data)

    assert_raises(NoMethodError) { @world.current_room.color }

    @world.update_current_room!
    assert_equal('blue', @world.current_room.color)
  end

  def test_save!
    assert_equal(0, @world.get_save_names!.count)
    save = @world.save!('default')
    assert_equal(1, @world.get_save_names!.count)

    assert(save.user_id)
    assert(save.home_id)
    assert_equal(1, save.rooms.count)
    assert_equal(1, save.users.count)

    @world.save!('save1')
    assert_equal(2, @world.get_save_names!.count)

    @world.save!('save2')
    assert_equal(3, @world.get_save_names!.count)

    @world.save!('default')
    assert_equal(3, @world.get_save_names!.count)
  end

  def test_load_save!
    @world.home.items << {'name'=>'shoe', 'desc'=>'a velcro shoe'}
    @world.home.save!

    assert(@world.save!('default'))

    @db.destroy!('rooms', @world.home._id)
    assert_equal(0, @world.all_rooms!.count)

    assert(@world.load_save!('default'))
    assert_equal(1, @world.all_rooms!.count)

    assert_equal('a velcro shoe', @world.home.items[0]['desc'])

    assert_equal(false, @world.load_save!('fake_save'))
  end

  def test_get_save_names!
    assert_equal(0, @world.get_save_names!.count)
    @world.save!('default')
    assert_equal(1, @world.get_save_names!.count)
    @world.save!('default')
    assert_equal(1, @world.get_save_names!.count)
    @world.save!('another')
    assert_equal(2, @world.get_save_names!.count)

    names = @world.get_save_names!
    assert(names.include?('default'))
    assert(names.include?('another'))
  end

  def test_get_save_id!
    @world.save!('testworld')
    10.times.each { |i| @world.save!("save_#{i}") }
    id1 = @world.get_save_id!('testworld')
    assert(id1)
    id2 = @world.get_save_id!("save_1")
    assert(id2)
    assert(id1 != id2)
    assert_equal(nil, @world.get_save_id!('fake'))
  end

  def test_destroy_save!
    assert(@world.save!('world'))
    assert(@world.get_save_id!('world'))
    assert(@world.destroy_save!('world'))
    assert_equal(nil, @world.get_save_id!('world'))
    assert_equal(false, @world.destroy_save!('world'))
  end

  def test_create_doors!
    room1 = @world.create_room!('room1', 'room one')
    room2 = @world.create_room!('room2', 'room two')
    assert_equal(0, room1.doors.count)
    assert_equal(0, room2.doors.count)
    5.times.each do 
      @world.create_doors!(room1, room2)
      assert_equal(1, room1.doors.count)
      assert_equal(1, room2.doors.count)
      assert_equal('room1',   room2.doors[0]['room_name'])
      assert_equal(room1._id, room2.doors[0]['room_id'])
      assert_equal('room2',   room1.doors[0]['room_name'])
      assert_equal(room2._id, room1.doors[0]['room_id'])
    end
  end

  def test_remove_doors!
    room1 = @world.create_room!('room1', 'room one')
    room2 = @world.create_room!('room2', 'room two')
    @world.create_doors!(room1, room2)
    5.times.each do
      @world.remove_doors!(room1, room2)
      assert_equal(0, room1.doors.count)
      assert_equal(0, room2.doors.count)
    end
  end

  def test_get_room_from_door
    room1 = @world.create_room!('room1', 'room one')
    @world.create_doors!(room1, @world.current_room)
    @world.update_current_room!

    room = @world.get_room_from_door('room1')
    assert_equal(room._id,  room1._id)
    assert_equal(room.name, room1.name)

    assert_equal(nil, @world.get_room_from_door('fake_room'))
    assert_equal(nil, @world.get_room_from_door('fake_room2'))
  end

  def test_create_door_data
    door = @world.create_door_data(@world.home)
    assert_equal('home',          door['room_name'])
    assert_equal(@world.home._id, door['room_id'])

    room = @world.create_room!('library', 'a library')
    door = @world.create_door_data(room)
    assert_equal('library', door['room_name'])
    assert_equal(room._id,  door['room_id'])
  end

  def test_get_door_index
    room1 = @world.create_room!('library', 'a library')
    room2 = @world.create_room!('lab',     'a laboratory')
    room3 = @world.create_room!('kitchen', 'a kitchen')

    @world.create_doors!(@world.current_room, room1)
    @world.create_doors!(@world.current_room, room2)
    @world.create_doors!(@world.current_room, room3)

    doors = @world.current_room.doors
    assert_equal(0,   @world.get_door_index(doors, room1.name))
    assert_equal(1,   @world.get_door_index(doors, room2.name))
    assert_equal(2,   @world.get_door_index(doors, room3.name))
    assert_equal(nil, @world.get_door_index(doors, 'fake_room'))
  end

  def test_set_debug
    5.times.each do
      @world.set_debug(true)
      assert_equal(true, @world.debug?)
    end
    5.times.each do
      @world.set_debug(false)
      assert_equal(false, @world.debug?)
    end
  end

  def test_debug?
    assert_equal(false, @world.debug?, 'should start out with debug turned off')
  end

  def test_find_room!
    hall  = @world.create_room!('hall', 'a hall')
    found = @world.find_room!(hall._id)
    assert(found)
    assert_equal(hall._id,  found._id)
    assert_equal(hall.name, found.name)
    assert_equal(hall.desc, found.desc)
    assert_equal(nil, @world.find_room!(0))
  end

  def test_all_rooms!
    assert_equal(1, @world.all_rooms!.count)
    10.times.each { |i| @world.create_room!("room_#{i}", "a room") }

    rooms = @world.all_rooms!
    assert_equal(11, rooms.count)

    names = rooms.map { |r| r.name }
    10.times.each { |i| assert(names.include?("room_#{i}")) }
  end

  def test_create_room!
    10.times.each do |i|
      room = @world.create_room!("room_#{i}", "a room")
      assert_equal(room.name, @db.find!('rooms', room._id)['name'])
    end
  end

  def test_create_room_from_data
    data = {'_id'=>1, 'name'=>'room', 'desc'=>'a room', 'items'=>[], 'mobs'=>[], 'doors'=>[]}
    room = @world.create_room_from_data(data)
    assert_equal(data['_id'],   room._id)
    assert_equal(data['name'],  room.name)
    assert_equal(data['desc'],  room.desc)
    assert_equal(data['items'], room.items)
    assert_equal(data['mobs'],  room.mobs)
    assert_equal(data['doors'], room.doors)

    data['color'] = 'red'
    room = @world.create_room_from_data(data)
    assert_equal(data['_id'],   room._id)
    assert_equal(data['name'],  room.name)
    assert_equal(data['desc'],  room.desc)
    assert_equal(data['items'], room.items)
    assert_equal(data['mobs'],  room.mobs)
    assert_equal(data['doors'], room.doors)
    assert_equal(data['color'], room.color)

    data = { 'pages' => 3 }
    room = @world.create_room_from_data(data)
    assert_equal('room',   room.name)
    assert_equal('a room', room.desc)
    assert_equal([],       room.items)
    assert_equal([],       room.mobs)
    assert_equal([],       room.doors)
    assert_equal(3,        room.pages)
    assert_raises(NoMethodError) { room._id }
  end

  def test_get_remembered_room
    assert_equal(nil, @world.get_remembered_room)
    
    kitchen = @world.create_room!('kitchen', 'a small kitchen')
    @world.user.remembered = @world.create_door_data(kitchen)
    @world.user.save!
    
    room = @world.get_remembered_room
    assert(room)
    assert_equal(kitchen._id,  room._id)
    assert_equal(kitchen.name, room.name)
    assert_equal(kitchen.desc, room.desc)
    assert_equal(kitchen.items, room.items)
    assert_equal(kitchen.mobs,  room.mobs)
  end

  def test_find_users!
  end

  def test_create_user
  end

  def test_create_user!
  end

  def test_create_user_from_data
  end

  def test_create_item_data
  end

  def test_get_item_data
  end

  def test_get_item_index
  end

  def test_upsert_item!
  end

  def test_destroy_item!
  end

  def test_create_mob_data
  end


end
