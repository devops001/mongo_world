
require_relative '../lib/db'
require_relative '../lib/player'

class PlayerTest < Minitest::Test

  def setup
    @db     = Database.new('test')
    @player = Player.new(@db.starting_room)
  end

  def test_name
    assert_equal("player", @player.name)
  end

  def test_starting_room
    assert_equal(@db.starting_room['name'], @player.room['name'])
  end

end

