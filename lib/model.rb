
require 'mongo'
require 'colorize'

class Model
  @collection = nil
  @@debug     = false

  def Model.debug
    @@debug
  end

  def Model.debug=(bool)
    @@debug = bool
  end

  def self.init!(dbname=nil)
    dbname ||= 'mongo_world'
    db = Mongo::MongoClient.new('localhost').db(dbname)
    @collection = db.collection(self.name)
  end

  def self.collection=(mongo_collection)
    @collection = mongo_collection
  end

  def self.collection
    @collection
  end

  def self.get_data!(_id)
    @collection.find_one('_id'=>_id)
  end

  def self.find!(_id)
    data = self.get_data!(_id)
    if data
      instance = self.new
      instance.send('data=', data)
      instance
    else
      puts "WARN".colorize(:light_magenta) +" #{self.name}#find!(#{_id}) not found" if Model.debug
      nil
    end
  end

  def self.destroy_all!
    @collection.remove() if @collection
  end

  def initialize
    @data = {}
  end

  def refresh!
    @data = self.class.get_data!(get('_id'))
  end

  def save!
    id = self.class.collection.save(@data)
    set('_id', id)
    @data.delete(:_id)
    puts "SAVED".colorize(:light_green) + " #{self.class.name}: #{@data.inspect}" if Model.debug
    true
  end

  def get(key)
    @data[key.to_s]
  end

  def set(key, value)
    @data[key.to_s] = value
  end

  def data
    @data
  end

  def method_missing(meth, *args, &block) 
    if @data.include?(meth.to_s)
      value = get(meth)
      value
    elsif meth.to_s =~ /(.*)=$/
      set($1, args.first)
    else
      super
    end
  end

  private
    def data=(data)
      @data = data
    end
end

