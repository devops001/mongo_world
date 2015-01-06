#!/usr/bin/env ruby

require_relative '../lib/db'

class DbTest < Minitest::Test

  def setup
    @db = Db.new('testdb')
  end

  def teardown
    @db.destroy_all!
  end

  def test_basic_usage
    user1       = Model.new(@db, 'users')
    user1.name  = 'tom'
    user1.level = 4
    user1.save!

    user2 = Model.new(@db, 'users', user1._id)
    assert_equal(user1.name, user2.name)
    assert_equal(user1.level, user2.level)
  end

end
