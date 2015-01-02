
require_relative '../lib/player'

class PlayerTest < Minitest::Test

  def setup
    Player.init('testdb')
    @player = Player.create('player', Room.home)
  end

  def test_name
    assert_equal("player", @player.name)
  end

  def test_home
    assert_equal(Room.home.name, @player.room.name)
  end

end

