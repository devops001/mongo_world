
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

  def test_home
    assert_equal(Room.home.name, @player.get_room!.name)
  end

  def test_create!
    tom = Player.create!('tom', Room.home)
    assert_equal(Room.home.name, tom.get_room!.name)
  end

  def test_set_room!
    kitchen = Room.create!('kitchen', 'a kitchen')
    @player.set_room!(kitchen)
    assert_equal('kitchen', @player.get_room!.name)
  end

end

