
require_relative '../lib/room'
require_relative '../lib/player'

class PlayerTest < Minitest::Test

  def setup
    Room.init!('testdb')
    Player.init!('testdb')
    @player = Player.create!('player', Room.home)
  end

  def test_name
    assert_equal("player", @player.name)
  end

  def test_create!
    tom = Player.create!('tom', Room.home)
    assert(tom.get('_id'))
  end

  def test_room_accessors
    assert_equal(Room.home.name, @player.get_room!.name)
    kitchen = Room.create!('kitchen', 'a kitchen')
    @player.set_room!(kitchen)
    assert_equal('kitchen', @player.get_room!.name)
  end


end

