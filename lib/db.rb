
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

  def destroy!(colname, _id)
    @mongodb.collection(colname).remove({'_id'=>_id})
    log "DB DELETE ".colorize(:light_red) + "#{colname} ".colorize(:light_blue) + _id.to_s
  end

  def destroy_collection!(colname)
    @mongodb.collection(colname).remove()
    log "DB DELETE ".colorize(:light_red) + "#{colname} ".colorize(:light_blue)
  end

  def destroy_all!
    @mongo.drop_database(@dbname)
    @mongodb = @mongo.db(@dbname)
    log "DB DELETE ALL".colorize(:light_red)
  end
end

