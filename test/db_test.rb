require_relative 'test_helper'
require_relative '../lib/db'

class DatabaseTest < Minitest::Test

  def setup
    @db = Database.new("test_mongo_world")
  end

  def teardown
    @db.reset
  end

  def test_add_room
    @db.add_room("green", "a green room")
    @db.add_room("blue",  "a blue room")

    @db.rooms.each do |room|
      puts room.inspect
    end
  end
end
