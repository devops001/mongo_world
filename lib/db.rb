
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
      id   = create_room(name, "a small white room")
      room = @rooms.find_one(id)
    end
    room
  end

  def create_room(name, desc, mobs=[], items=[])
    @rooms.insert({:name=>name, :desc=>desc, :mobs=>mobs, :items=>items})
  end
end

