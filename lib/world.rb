
require_relative 'db'

class World

	def initialize(dbname)
		@dbname = dbname
		@db     = Db.new(dbname)
    @home   = create_room!('home', 'a home')
    @user   = create_user!('user', 'a user', @home._id)
		@room   = @home
  end

	def collection_names
		%w/rooms users items/
	end

	def destroy_collections!
		collection_names.each { |name| @db.destroy_collection!(name) }
	end

	def destroy_database!
		@db.destroy_all!
	end

	########################
	## rooms:
	########################

	def rooms!
		rooms = []
		@db.all!('rooms').each do |data|
      rooms << create_room_from_data(data)
		end
		rooms
	end

	def create_room(name, desc)
		room       = Model.new(@db, 'rooms')
		room.name  = name
		room.desc  = desc
		room.items = []
		room.mobs  = []
		room.doors = []
		room
	end

	def create_room!(name, desc)
		room = create_room(name, desc)
		room.save!
		room
	end

	def create_room_from_data(data)
		room       = Model.new(@db, 'rooms')
		room.name  = data['name']  or 'room'
		room.desc  = data['desc']  or 'a room'
		room.doors = data['doors'] or []
		room.items = data['items'] or []
		room.mobs  = data['mobs']  or []
		room
	end

	########################
	## users:
	########################

	def users!
		users = []
		@db.all!('users').each do |data|
      users << create_user_from_data(data)
		end
    users
	end

	def create_user(name, desc, room_id)	
		user            = Model.new(@db, 'users')
    user.name       = name
    user.desc       = desc
    user.room_id    = room_id
    user.remembered = nil
		user
	end

	def create_user!(name, desc, room_id)
		user = create_user(name, desc, room_id)
		user.save!
		user
	end

	def create_user_from_data(data)
		user            = Model.new(@db, 'users')
		user.name       = data['name']       or 'user'
		user.desc       = data['desc']       or 'a user'
		user.room_id    = data['room_id']    or @home._id
		user.remembered = data['remembered'] or nil
		user
	end


end

