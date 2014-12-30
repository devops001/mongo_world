
require_relative '../lib/db'

class DatabaseTest < Minitest::Test

  def setup
    @db = Database.new("test_mongo_world")
  end

  def teardown
    @db.clear_all
  end

  def test_create_room
    assert_equal(1, @db.rooms.count)
    @db.create_room("green", "a green room")
    @db.create_room("blue",  "a blue room")
    assert_equal(3, @db.rooms.count)
  end
end
