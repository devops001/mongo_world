
require_relative '../lib/world'

class WorldTest < Minitest::Test

  def setup
    @world = World.new('testdb')
    @db    = @world.instance_variable_get(:@db)
    @home  = @world.instance_variable_get(:@home)
    @room  = @world.instance_variable_get(:@room)
    @user  = @world.instance_variable_get(:@user)
  end

  def teardown
    @world.destroy_database!
  end

  def test_instance_models
    assert(@home._id)
    assert(@room._id) 
    assert(@user._id) 
  end

  def test_collection_names
    assert_equal(3, @world.collection_names.count)
  end

  def test_destroy_collections!
    assert(@world.rooms!.count, 1)
    assert(@world.users!.count, 1)
    @world.destroy_collections!
    assert(@world.rooms!.count, 0)
    assert(@world.users!.count, 0)
  end

  def test_destroy_database!
    assert(@world.rooms!.count, 1)
    assert(@world.users!.count, 1)
    @world.destroy_database!
    assert(@world.rooms!.count, 0)
    assert(@world.users!.count, 0)
  end

  def test_create_room
    assert(@world.rooms!.count, 1)
    10.times.each do |i|
      name = "room_#{i}"
      desc = "a room with a #{i} painted on the wall"
      room = @world.create_room(name, desc)
      room.save!
      assert_equal(name, room.name)
      assert_equal(desc, room.desc)
    end
    assert(@world.rooms!.count, 11)
  end

  def test_update_current_room!
    assert_equal('home', @world.room.name)

    data = @db.find!('rooms', @world.room._id)
    data['color'] = 'blue'
    @db.save!('rooms', data)

    assert_raises(NoMethodError) { @world.room.color }

    @world.update_current_room!
    assert_equal('blue', @world.room.color)
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
    assert_equal(0, @world.rooms!.count)

    assert(@world.load_save!('default'))
    assert_equal(1, @world.rooms!.count)

    assert_equal('a velcro shoe', @world.home.items[0]['desc'])

    assert_equal(false, @world.load_save!('fake_save'))
  end

  def test_get_save_names!
  end

  def test_get_save_id!
  end

  def test_destroy_save!
  end

  def test_create_doors!
  end

  def test_remove_doors!
  end

  def test_get_room_from_door
  end

  def test_create_door_data
  end

  def test_get_door_index
  end

  def test_set_debug
  end

  def test_debug?
  end

  def test_room!
  end

  def test_rooms!
  end

  def test_create_room!
  end

  def test_create_room_from_data
  end

  def test_get_remembered_room
  end

  def test_users!
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
