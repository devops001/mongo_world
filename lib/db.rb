
require 'mongo'
require 'colorize'

class Db
  def initialize(dbname='mongo_world')
    @dbname  = dbname
    @mongo   = Mongo::MongoClient.new('localhost')
    @mongodb = @mongo.db(@dbname)
    @debug   = false
  end

  def find!(colname, _id=nil)
    if _id.nil?
      data = @mongodb.collection(colname).find_one()
    else
      data = @mongodb.collection(colname).find_one({'_id' => _id})
    end
    log "DB FIND ".colorize(:light_green) + "#{colname} ".colorize(:light_blue) + data.inspect
    data
  end

  def all!(colname)
    data = @mongodb.collection(colname).find()
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

  def destroy!(colname)
    @mongodb.collection(colname).remove()
    log "DB DELETE ".colorize(:light_red) + "#{colname} ".colorize(:light_blue)
  end

  def destroy_all!
    @mongo.drop_database(@dbname)
    @mongodb = @mongo.db(@dbname)
    log "DB DELETE ALL".colorize(:light_red)
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
