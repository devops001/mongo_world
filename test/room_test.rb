
require_relative '../lib/room'

class RoomTest < Minitest::Test

  def setup
    Room.init('testdb')
  end

  def teardown
    Room.collection.remove()
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
    assert_equal(room.get('_id'), room.get(:_id))
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
    room.set(:color, 'red')
    room.save!
    room.set(:color, 'blue')
    room.refresh!
    assert_equal('red', room.get(:color))
  end

  def test_find
    room = Room.new
    room.set(:color, 'red')
    room.save!

    room2 = Room.find(room.get(:_id))
    assert(room2)
    assert_equal(room.get(:_id), room2.get(:_id))
    assert_equal(room.get(:color), room2.get(:color))
  end

end
