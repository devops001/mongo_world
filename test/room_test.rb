
require_relative '../lib/room'

class RoomTest < Minitest::Test

  def setup
    Room.init!('testdb')
  end

  def teardown
    Room.destroy_all!
  end

  def test_new
    room = Room.new
    assert(room)
    assert(room.data)
  end

  def test_save!
    room = Room.new
    room.save!
    assert(room.get('_id'))
    assert_equal(room.get('_id'), room.get('_id'))
    room.save!
    room.save!
  end

  def test_set_and_get
    room = Room.new
    room.set('one', 1)
    room.set(:two,  2)
    assert_equal(1, room.get('one'))
    assert_equal(2, room.get('two'))
    assert_equal(1, room.get(:one))
    assert_equal(2, room.get(:two))
  end

  def test_refresh!
    room = Room.new
    room.set('color', 'red')
    room.save!
    room.set('color', 'blue')
    room.refresh!
    assert_equal('red', room.get('color'))
  end

  def test_find!
    room = Room.new
    room.set('color', 'red')
    room.save!
    room2 = Room.find!(room.get('_id'))
    assert(room2)
    assert_equal(room.get('_id'), room2.get('_id'))
    assert_equal(room.get('color'), room2.get('color'))
  end

  def test_connect!
    blue = Room.create!('blue', 'a blue room')
    red  = Room.create!('red', 'a red room')

    blue.connect!(red)
    assert_equal(1, blue.doors.count)
    assert_equal(1, red.doors.count)
    assert_equal('red',  blue.doors[0]['room_name'])
    assert_equal('blue', red.doors[0]['room_name'])
    assert_equal(blue._id, red.doors[0]['room_id'])
    assert_equal(red._id,  blue.doors[0]['room_id'])

    red.connect!(blue)  #<- shouldn't connect! again if already exists
    assert_equal(1, blue.doors.count)
    assert_equal(1, red.doors.count)
    assert_equal('red',  blue.doors[0]['room_name'])
    assert_equal('blue', red.doors[0]['room_name'])
    assert_equal(blue._id, red.doors[0]['room_id'])
    assert_equal(red._id,  blue.doors[0]['room_id'])
  end

  def test_list_doors
    blue  = Room.create!('blue',  'a blue room')
    red   = Room.create!('red',   'a red room')
    green = Room.create!('green', 'a green room')
    black = Room.create!('black', 'a black room')

    blue.connect!(red)
    assert_equal('blue', red.list_doors)
    assert_equal('red',  blue.list_doors)
    assert_equal('',     green.list_doors)
    assert_equal('',     black.list_doors)

    blue.connect!(green)
    assert_equal('blue',       red.list_doors)
    assert_equal('green, red', blue.list_doors)
    assert_equal('blue',       green.list_doors)
    assert_equal('',           black.list_doors)

    black.connect!(green)
    assert_equal('blue',        red.list_doors)
    assert_equal('green, red',  blue.list_doors)
    assert_equal('black, blue', green.list_doors)
    assert_equal('green',       black.list_doors)
  end



end





