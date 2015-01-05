
require 'mongo'
require 'colorize'

class Db
  def initialize(dbname='mongo_world')
    @mongodb = Mongo::MongoClient.new('localhost').db(dbname)
    @debug   = false
  end

  def find!(colname, _id)
    data = @mongodb.collection(colname).find_one({'_id' => _id})
    log "DB FIND ".colorize(:light_green) + "#{colname} ".colorize(:light_blue) + data.inspect
    data
  end

  def save!(colname, data)
    data['_id'] = @mongodb.collection(colname).save(data)
    data.delete(:_id)
    log "DB SAVE ".colorize(:light_green) + "#{colname} ".colorize(:light_blue) + data.inspect
    data
  end

  def log(msg)
    puts msg if @debug
  end

  def toggle_debug
    @debug = !@debug
  end
end

class Model 
  def initialize(db, collection_name, _id=nil)
    @db      = db
    @colname = collection_name
    if _id.nil?
      @data = {}
    else
      data  = @db.find!(@colname, _id)
      @data = data.nil? ? {} : data
    end
  end

  def refresh!
    @data = @db.find!(@colname, @data['_id']) if @data['_id']
  end

  def save!
    @data = @db.save!(@colname, @data) 
  end

  def method_missing(meth, *args, &block)
    if @data.include?(meth.to_s)
      @data[meth.to_s]
    elsif meth =~ /(.*)=/
      @data[$1] = args[0]
    else
      super
    end
  end

  def to_s
    @data.inspect
  end
end
