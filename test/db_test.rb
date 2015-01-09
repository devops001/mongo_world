
require_relative '../lib/db'

class DbTest < Minitest::Test

  def setup
    @db = Db.new('testdb')
  end

  def teardown
    @db.destroy_all!
  end

  def test_toggle_debug
    assert_equal(false, @db.debug?)

    assert_equal(true,  @db.toggle_debug)
    assert_equal(true, @db.debug?)

    assert_equal(false,  @db.toggle_debug)
    assert_equal(false, @db.debug?)
  end

  def test_log
    # nothing to test
  end

  def test_save!
    data  = {'one'=>1, 'two'=>2}
    saved = @db.save!('items', data)

    assert_equal(true, saved.include?('_id'))
    assert_equal(true, saved.include?('one'))
    assert_equal(true, saved.include?('two'))

    assert_equal(false, saved.include?(:_id))
    assert_equal(false, saved.include?(:one))
    assert_equal(false, saved.include?(:two))

    assert_equal(data['one'], saved['one'])
    assert_equal(data['two'], saved['two'])
  end


  def test_find!
    saved = @db.save!('items', {'one'=>1, 'two'=>2})
    found = @db.find!('items', saved['_id'])

    assert_equal(saved['_id'], found['_id'])
    assert_equal(saved['one'], found['one'])
    assert_equal(saved['two'], found['two'])
  end

  def test_all!
    items = []
    10.times.each_with_index do |i|
      items << @db.save!('items', {'name'=>"item_#{i}", 'desc'=>'an item'})
    end

    found = @db.all!('items')
    assert_equal(items.count, found.count)

    items.each_with_index do |item, i|
      assert_equal(item['_id'],  items[i]['_id'])
      assert_equal(item['name'], items[i]['name'])
      assert_equal(item['desc'], items[i]['desc'])
    end

    assert_equal(0, @db.all!('fake_collection').count)
  end

  def test_destroy!
    saved = @db.save!('items', {'name'=>'red'})
    found = @db.find!('items', saved['_id'])
    assert_equal(saved['name'], found['name'])

    @db.destroy!('items', saved['_id'])
    assert_nil(@db.find!('items', saved['_id']))
  end

  def test_destroy_collection!
    saved = @db.save!('items', {'name'=>'red'})
    found = @db.find!('items', saved['_id'])
    assert_equal(saved['name'], found['name'])

    @db.destroy_collection!('items')
    assert_nil(@db.find!('items', saved['_id']))
  end

  def test_destroy_all!
    item = @db.save!('items', {'name'=>'red'})
    book = @db.save!('books', {'name'=>'blue'})
    assert_equal(item['name'], @db.find!('items', item['_id'])['name'])
    assert_equal(book['name'], @db.find!('books', book['_id'])['name'])

    @db.destroy_all!
    assert_nil(@db.find!('items', item['_id']))
    assert_nil(@db.find!('books', book['_id']))
    assert_equal(0, @db.all!('items').count)
    assert_equal(0, @db.all!('books').count)
  end

end
