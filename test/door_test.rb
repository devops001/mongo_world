
require_relative '../lib/room'
require_relative '../lib/door'

class DoorTest < Minitest::Test

  def setup
    Room.init!('testdb')
    @home = Room.create!('home', 'a small white room')
    @lab  = Room.create!('lab', 'a lab')
  end

  def test_to_h
    hash = Door.new('home', @home._id).to_h
    assert_equal(hash['room_name'], @home.name)
    assert_equal(hash['room_id'],   @home._id)

    hash = Door.new(@lab.name, @lab._id).to_h
    assert_equal(hash['room_name'], @lab.name)
    assert_equal(hash['room_id'],   @lab._id)
  end



end

