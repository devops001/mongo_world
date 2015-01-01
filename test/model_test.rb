
require_relative '../lib/model'

class ModelTest < Minitest::Test

  def setup
    Model.collection = Mongo::MongoClient.new('localhost').db("test_mongo_world").collection('models')
  end

  def teardown
    Model.collection.remove()
  end

  def test_new
    model = Model.new
    assert(model)
    assert(model.data)
  end

  def test_save!
    model = Model.new
    model.save!
    assert(model.get('_id'))
    assert_equal(model.get('_id'), model.get(:_id))
    model.save!
    model.save!
  end

  def test_set_and_get
    model = Model.new
    model.set('one', 1)
    model.set(:two,  2)
    assert_equal(1, model.get('one'))
    assert_equal(2, model.get('two'))
    assert_equal(1, model.get(:one))
    assert_equal(2, model.get(:two))
  end

  def test_refresh!
    model = Model.new
    model.set(:color, 'red')
    model.save!
    model.set(:color, 'blue')
    model.refresh!
    assert_equal('red', model.get(:color))
  end

end
