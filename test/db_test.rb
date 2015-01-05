#!/usr/bin/env ruby

require_relative '../lib/db'

class DbTest < Minitest::Test

  def setup
    @db = Db.new('testdb')
  end

  def test_basic_usage
    player1       = Model.new(@db, 'players')
    player1.name  = 'tom'
    player1.level = 4
    player1.save!

    player2 = Model.new(@db, 'players', player1._id)
    assert_equal(player1.name, player2.name)
    assert_equal(player1.level, player2.level)
  end

end
