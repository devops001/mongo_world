
require_relative '../lib/client'

class ClientTest < Minitest::Test

  def setup
    @client = Client.new(false)
  end

  def test_home
    assert(@client.home)
    assert_equal('home', @client.home.name)
  end

  def test_player
    assert(@client.player)
    assert_equal('home', @client.player.get_room!.name)
  end


end

