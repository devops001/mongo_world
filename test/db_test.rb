
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

	def test_doors_from_create_room
		assert_equal(0, @db.starting_room['doors'].count)
		@db.create_room("lab", "a science lab")
		assert_equal(1, @db.starting_room['doors'].count)
		assert_equal(1, @db.find_room("lab")['doors'].count)

    @db.create_room("kitchen", "a clean kitchen", "lab")
		assert_equal(1, @db.find_room("kitchen")['doors'].count)
		assert_equal(2, @db.find_room("lab")['doors'].count)
		assert_equal(1, @db.starting_room['doors'].count)
	end

end
