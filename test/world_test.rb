
require_relative '../lib/world'
require 'minitest/autorun'

class WorldTest < Minitest::Test

  def setup
    @world = World.new('testdb')
    @db    = @world.instance_variable_get(:@db)
    @home  = @world.create_room!('home','home')
    @user  = @world.create_user!('user','user',@home._id)
    @room  = @world.find_room!(@user.room_id)
  end

  def teardown
    @world.destroy_database!
  end

  def test_instance_models
    assert_equal(Db, @db.class)
  end

  def test_collection_names
    assert_equal(2, @world.collection_names.count)
  end

  def test_destroy_collections!
    assert(@world.all_rooms!.count, 1)
    assert(@world.all_users!.count, 1)
    @world.destroy_collections!
    assert(@world.all_rooms!.count, 0)
    assert(@world.all_users!.count, 0)
  end

  def test_destroy_database!
    assert(@world.all_rooms!.count, 1)
    assert(@world.all_users!.count, 1)
    @world.destroy_database!
    assert(@world.all_rooms!.count, 0)
    assert(@world.all_users!.count, 0)
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
    assert_equal('home', @room.name)

    data = @db.find!('rooms', @room._id)
    data['color'] = 'blue'
    @db.save!('rooms', data)

    assert_raises(NoMethodError) { @room.color }

    @room = @world.find_room!(@user.room_id)
    assert_equal('blue', @room.color)
  end

  def test_save!
    assert_equal(0, @world.get_save_names!.count)
    save = @world.save!('default', @home._id, @user._id)
    assert_equal(1, @world.get_save_names!.count)

    assert(save.user_id)
    assert(save.home_id)
    assert_equal(1, save.rooms.count)
    assert_equal(1, save.users.count)

    @world.save!('save1', @home._id, @user._id)
    assert_equal(2, @world.get_save_names!.count)

    @world.save!('save2', @home._id, @user._id)
    assert_equal(3, @world.get_save_names!.count)

    @world.save!('default', @home._id, @user._id)
    assert_equal(3, @world.get_save_names!.count)
  end

  def test_load_save!
    @home.items << {'name'=>'shoe', 'desc'=>'a velcro shoe'}
    @home.save!

    assert(@world.save!('default', @home._id, @user._id))

    @db.destroy!('rooms', @home._id)
    assert_equal(0, @world.all_rooms!.count)

    assert(@world.load_save!('default'))
    assert_equal(1, @world.all_rooms!.count)

    assert_equal('a velcro shoe', @home.items[0]['desc'])

    assert_equal(false, @world.load_save!('fake_save'))
  end

  def test_get_save_names!
    assert_equal(0, @world.get_save_names!.count)
    @world.save!('default', @home._id, @user._id)
    assert_equal(1, @world.get_save_names!.count)
    @world.save!('default', @home._id, @user._id)
    assert_equal(1, @world.get_save_names!.count)
    @world.save!('another', @home._id, @user._id)
    assert_equal(2, @world.get_save_names!.count)

    names = @world.get_save_names!
    assert(names.include?('default'))
    assert(names.include?('another'))
  end

  def test_get_save_id!
    @world.save!('testworld', @home._id, @user._id)
    10.times.each { |i| @world.save!("save_#{i}", @home._id, @user._id) }
    id1 = @world.get_save_id!('testworld')
    assert(id1)
    id2 = @world.get_save_id!("save_1")
    assert(id2)
    assert(id1 != id2)
    assert_equal(nil, @world.get_save_id!('fake'))
  end

  def test_destroy_save!
    assert(@world.save!('world', @home._id, @user._id))
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

  def test_get_room_from_door_name
    room1 = @world.create_room!('room1', 'room one')
    @world.create_doors!(room1, @room)
    @room = @world.find_room!(@user.room_id)

    room = @world.get_room_from_doors(@room.doors, 'room1')
    assert_equal(room._id,  room1._id)
    assert_equal(room.name, room1.name)

    assert_equal(nil, @world.get_room_from_doors(@room.doors, 'fake_room'))
    assert_equal(nil, @world.get_room_from_doors(@room.doors, 'fake_room2'))
  end

  def test_create_door_data
    door = @world.create_door_data(@home)
    assert_equal('home',    door['room_name'])
    assert_equal(@home._id, door['room_id'])

    room = @world.create_room!('library', 'a library')
    door = @world.create_door_data(room)
    assert_equal('library', door['room_name'])
    assert_equal(room._id,  door['room_id'])
  end

  def test_get_door_index
    room1 = @world.create_room!('library', 'a library')
    room2 = @world.create_room!('lab',     'a laboratory')
    room3 = @world.create_room!('kitchen', 'a kitchen')

    @world.create_doors!(@room, room1)
    @world.create_doors!(@room, room2)
    @world.create_doors!(@room, room3)

    doors = @room.doors
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
    assert_equal(nil, @world.get_remembered_room(@user))
    
    kitchen = @world.create_room!('kitchen', 'a small kitchen')
    @user.remembered = @world.create_door_data(kitchen)
    @user.save!
    
    room = @world.get_remembered_room(@user)
    assert(room)
    assert_equal(kitchen._id,   room._id)
    assert_equal(kitchen.name,  room.name)
    assert_equal(kitchen.desc,  room.desc)
    assert_equal(kitchen.items, room.items)
    assert_equal(kitchen.mobs,  room.mobs)
  end

  def test_all_users!
    assert_equal(1, @world.all_users!.count)
    10.times.each { |i| @world.create_user!("user_#{i}", "a user", @home._id) }
    users = @world.all_users!
    names = users.map { |u| u.name }
    assert_equal(11, users.count)
    10.times.each { |i| assert(names.include?("user_#{i}")) }  
  end

  def test_create_user
    user = @world.create_user('joe', 'man', @home._id)
    assert_equal('joe', user.name)
    assert_equal('man', user.desc)
    assert_equal(@home._id, user.room_id)
    assert_raises(NoMethodError) { user._id }
  end

  def test_create_user!
    user = @world.create_user!('joe', 'man', @home._id)
    assert_equal('joe', user.name)
    assert_equal('man', user.desc)
    assert_equal(@home._id, user.room_id)
    assert(user._id)
    assert(@db.find!('users', user._id))

    10.times.each do |i|
      user = @world.create_user!("user_#{i}", "a user", @home._id)
      assert(user._id)
      assert(@db.find!('users', user._id))
    end
  end

  def test_create_user_from_data
    data = { 'name'=>'joe', 'desc'=>'man', 'room_id'=>4, 'color'=>'red', 'size'=>3}
    user = @world.create_user_from_data(data)
    assert_equal('joe', user.name)
    assert_equal('man', user.desc)
    assert_equal(4,     user.room_id)
    assert_equal('red', user.color)
    assert_equal(3,     user.size)
    assert_raises(NoMethodError) { user._id }

    data = { 'health' => 5 }
    user = @world.create_user_from_data(data)
    assert_equal('user',    user.name)
    assert_equal('a user',  user.desc)
    assert_equal(nil,       user.room_id)
    assert_equal(5,         user.health)
    assert_raises(NoMethodError) { user._id }

    data = {}
    user = @world.create_user_from_data(data)
    assert_equal('user',    user.name)
    assert_equal('a user',  user.desc)
    assert_equal(nil,       user.room_id)
    assert_raises(NoMethodError) { user._id    }
    assert_raises(NoMethodError) { user.health }
  end

  def test_find_user!
    users = []
    10.times.each do |i| 
      users << @world.create_user!("user_#{i}", "a user", @home._id)
    end
    10.times.each do |i|
      user = @world.find_user!(users[i]._id)
      assert(user)
      assert_equal(users[i]._id,  user._id)
      assert_equal(users[i].name, user.name)
      assert_equal(users[i].desc, user.desc)
    end
    10.times.each do |i|
      assert_equal(nil, @world.find_user!(i))
    end
  end

  def test_create_item_data
    item = { 'name'=>'book', 'desc'=>'a book' }
    assert_equal(item, @world.create_item_data(item['name'], item['desc']))
    assert_equal({'name'=>'one','desc'=>'two'}, @world.create_item_data('one', 'two'))
  end

  def test_get_item_data
    assert_equal(nil, @world.get_item_data(@home, 'fake1'))

    @home.items << @world.create_item_data('spoon', 'a spoon')
    @home.save!

    assert_equal(nil, @world.get_item_data(@home, 'fake2'))
    assert_equal('a spoon', @world.get_item_data(@home, 'spoon')['desc'])
  end

  def test_get_item_index
    assert_equal(nil, @world.get_item_index(@home, 'fake1'))
    10.times.each { |i| @world.upsert_item!(@home, @world.create_item_data("item_#{i}", "an item")) }
    10.times.each { |i| assert_equal(i, @world.get_item_index(@home, "item_#{i}")) }
    assert_equal(nil, @world.get_item_index(@home, 'fake1'))
  end

  def test_upsert_item!
    assert_equal(0, @home.items.count)

    data = @world.create_item_data('shoe', 'a shoe')
    @world.upsert_item!(@home, data)
    assert_equal(1, @home.items.count)

    data['desc'] = 'a stuffed clown toy'
    @world.upsert_item!(@home, data)

    assert_equal(1, @home.items.count)

    found = @world.get_item_data(@home, 'shoe')
    assert_equal(found['desc'], 'a stuffed clown toy')

    @world.upsert_item!(@home, {'name'=>'box', 'desc'=>'a box'})
    assert_equal(2, @home.items.count)
  end

  def test_destroy_item!
    assert_equal(0, @home.items.count)
    @world.upsert_item!(@home, {'name'=>'box', 'desc'=>'a box'})
    assert_equal(1, @home.items.count)
    assert(@world.destroy_item!(@home, 'box'))
    assert_equal(0, @home.items.count)
    10.times.each { assert_equal(false, @world.destroy_item!(@home, 'box')) }
    assert_equal(0, @home.items.count)
  end

  def test_create_mob_data
    mob = {'name'=>'frog', 'desc'=>'green'}
    assert_equal(mob, @world.create_mob_data('frog', 'green'))
  end

  def test_upsert_mob!
    assert_equal(0, @home.mobs.count)

    10.times.each { |i| @world.upsert_mob!(@home, @world.create_mob_data("mob_#{i}", "a mob")) }
    assert_equal(10, @home.mobs.count)

    10.times.each { |i| @world.upsert_mob!(@home, @world.create_mob_data("mob_#{i}", "a big mob")) }
    assert_equal(10, @home.mobs.count)

    10.times.each { |i| @world.upsert_mob!(@home, @world.create_mob_data("happy_mob_#{i}", "a happy mob")) }
    assert_equal(20, @home.mobs.count)
  end

  def test_get_mob_index
    10.times.each { |i| @world.upsert_mob!(@home, @world.create_mob_data("mob_#{i}", "a mob")) }
    10.times.each { |i| assert_equal(i, @world.get_mob_index(@home, "mob_#{i}")) }
    assert_equal(nil, @world.get_mob_index(@home, "fake"))
  end

  def test_destroy_mob!
    assert_equal(0, @home.mobs.count)

    10.times.each { |i| @world.upsert_mob!(@home, @world.create_mob_data("mob_#{i}", "a mob")) }
    assert_equal(10, @home.mobs.count)

    10.times.each { |i| assert(@world.destroy_mob!(@home, "mob_#{i}")) }
    assert_equal(0, @home.mobs.count)

    10.times.each { |i| assert_equal(false, @world.destroy_mob!(@home, "fake_#{i}")) }
  end

end
