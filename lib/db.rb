
require 'mongo'

class Database
  attr_reader :dbname

  def initialize(dbname="mongo_world")
    @dbname = dbname
    @mongo  = Mongo::MongoClient.new('localhost')
    @db     = @mongo.db(@dbname)
    @rooms  = @db.collection('rooms')
    @rooms.remove()
  end

  def rooms
    @rooms.find()
  end

  def starting_room
    name = "starting_room"
    room = @rooms.find_one({:name => name})
    if not room
       @rooms.insert({:name => name, :desc => "a small white room"})
      room = @rooms.find_one({:name => name})
    end
    room
  end
end

