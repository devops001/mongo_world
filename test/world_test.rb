
require_relative '../lib/world'

class WorldTest < Minitest::Test

  def setup
    @world = World.new('testdb')
    @db    = @world.instance_variable_get(:@db)
    @home  = @world.instance_variable_get(:@home)
    @user  = @world.instance_variable_get(:@user)
  end

  def teardown
    @world.destroy_database!
  end

  def test_instance_models
    assert(@home._id)
    assert(@user._id) 
  end

  def test_collection_names
    assert_equal(3, @world.collection_names.count)
  end

  def test_destroy_collections!
    assert(@world.find_rooms!.count, 1)
    assert(@world.find_users!.count, 1)
    @world.destroy_collections!
    assert(@world.find_rooms!.count, 0)
    assert(@world.find_users!.count, 0)
  end

  def test_destroy_database!
    assert(@world.find_rooms!.count, 1)
    assert(@world.find_users!.count, 1)
    @world.destroy_database!
    assert(@world.find_rooms!.count, 0)
    assert(@world.find_users!.count, 0)
  end

  def test_create_room
    assert(@world.find_rooms!.count, 1)
    10.times.each do |i|
      name = "room_#{i}"
      desc = "a room with a #{i} painted on the wall"
      room = @world.create_room(name, desc)
      room.save!
      assert_equal(name, room.name)
      assert_equal(desc, room.desc)
    end
    assert(@world.find_rooms!.count, 11)
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
    data = @db.find!('rooms', @world.home._id)
    data['items'] << {'name'=>'shoe', 'desc'=>'a velcro shoe'}
    @db.save!('rooms', data)

    assert(@world.save!('default'))

    @db.destroy!('rooms', @world.home._id)
    assert_equal(0, @world.find_rooms!.count)

    assert(@world.load_save!('default'))
    assert_equal(1, @world.find_rooms!.count)

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
  end

  def test_find_rooms!
  end

  def test_create_room!
  end

  def test_create_room_from_data
  end

  def test_get_remembered_room
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
