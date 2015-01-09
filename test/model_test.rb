#!/usr/bin/env ruby

require_relative '../lib/model'

class ModelTest < Minitest::Test

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

  def test_new
    item = Model.new(@db, 'items')
    assert_raises(NoMethodError) { item._id  }
  end

  def test_save!
    item = Model.new(@db, 'items')
    item.name = 'thing'
    item.code = 837
    item.save!

    found = @db.find!('items', item._id)
    assert_equal(item._id,  found['_id'])
    assert_equal(item.name, found['name'])
    assert_equal(item.code, found['code'])
  end


  def test_refresh!
    item = Model.new(@db, 'items')
    item.name = 'first_name'
    item.save!

    @db.save!('items', {'_id'=>item._id, 'name'=>'second_name'})

    assert_equal('first_name', item.name)

    item.refresh!
    assert_equal('second_name', item.name)
  end
  
  def test_method_missing
    item = Model.new(@db, 'items')

    assert_raises(NoMethodError) { item.name               }
    assert_raises(NoMethodError) { item.armchair_color     }
    assert_raises(NoMethodError) { item.bird_beak_whistles }

    s = 'foo'
    h = {'r'=>20, 'g'=>135, 'b'=>200}
    a = [:one, :two, :three]

    item.name               = s
    item.armchair_color     = h
    item.bird_beak_whistles = a

    assert_equal(s, item.name)
    assert_equal(h, item.armchair_color)
    assert_equal(a, item.bird_beak_whistles)

    item.save!
    assert_equal(s, item.name)
    assert_equal(h, item.armchair_color)
    assert_equal(a, item.bird_beak_whistles)
  end

  def test_to_s
    item = Model.new(@db, 'items')
    assert_equal("{}", item.to_s)

    item.name = 'item3'
    assert_equal("{\"name\"=>\"item3\"}", item.to_s)

    item.things = []
    assert_equal("{\"name\"=>\"item3\", \"things\"=>[]}", item.to_s)
  end

end
