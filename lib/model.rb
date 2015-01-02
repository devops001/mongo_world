
require 'mongo'

class Model
  @@collection = nil

  def self.init(dbname=nil)
    dbname ||= 'mongo_world'
    db = Mongo::MongoClient.new('localhost').db(dbname)
    @@collection = db.collection(self.name)
  end

  def self.collection=(mongo_collection)
    @@collection = mongo_collection
  end

  def self.collection
    @@collection
  end

  def self.get_data(_id)
    data = @@collection.find_one(:_id=>_id)
    self.keys_to_syms(data)
  end

  def self.find(_id)
    instance = self.new
    instance.send(:data=, self.get_data(_id))
    instance
  end

  def initialize
    @data = {}
  end

  def refresh!
    @data = self.class.get_data(get(:_id))
  end

  def save!
    set(:_id, @@collection.save(@data))
  end

  def get(key)
    @data[key.to_sym]
  end

  def set(key, value)
    @data[key.to_sym] = value
  end

  def data
    @data
  end

  def method_missing(meth, *args, &block) 
    if @data.include?(meth.to_sym)
      get(meth)
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

    def self.keys_to_syms(hash)
      hash.inject({}){|symkeys,(k,v)| symkeys[k.to_sym]=v; symkeys}
    end
end

