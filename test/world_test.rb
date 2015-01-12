
require_relative '../lib/world'

class WorldTest < Minitest::Test

  def setup
    @world = World.new('testdb')
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

end

