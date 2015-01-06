#!/usr/bin/env ruby

require 'shellwords'
require_relative 'db'

class Client

  ##########################################
  ## initializing:
  ##########################################

  def initialize
    initialize_data
    initialize_commands
    @is_running = false
  end

  def initialize_data
    @db = Db.new
    @db.destroy_collection!('rooms')
    @db.destroy_collection!('users')
    @db.destroy_collection!('items')

    @home = Model.new(@db, 'rooms')
    @home.name  = 'home'
    @home.desc  = 'a home'
    @home.doors = [];
    @home.items = [];
    @home.save!

    @user = Model.new(@db, 'users')
    @user.name       = 'user'
    @user.desc       = 'a user'
    @user.room_id    = @home._id
    @user.remembered = nil
    @user.save!

    update_room!
  end

  def initialize_commands
    @cmd = {
      'exit'  => lambda { @is_running=false },
      'clear' => lambda { puts `clear` },
      'room'  => lambda { puts @room },
      'save'  => lambda { |name='default'| save(name) },
      'ls_saves'  => lambda { ls_saves },
      'load_save'   => lambda { |name='default'| load_save(name) },
      'rm_save'     => lambda { |name| rm_save(name) },
      'debug' => lambda {
        print "debug is ".colorize(:light_black)
        puts @db.toggle_debug ? "on".colorize(:light_green) : "off".colorize(:light_red)
      },
      'ls'    => lambda {
        doors = @room.doors.map { |door| door['room_name'] }.join(', ').colorize(:light_blue)
        items = @room.items.map { |item| item['name'] }.join(', ').colorize(:light_yellow)
        puts @room.name.colorize(:light_blue) +": ".colorize(:light_black) + @room.desc.colorize(:white)
        puts "doors: [".colorize(:light_black) + doors +"]".colorize(:light_black) if doors.length>0
        puts "items: [".colorize(:light_black) + items +"]".colorize(:light_black) if items.length>0
      },
      'cd' => lambda { |room_name=nil|
        if room_name.nil?
          next_room_id = @home._id
        else
          next_room_id = nil
          @room.doors.each do |door|
            if door['room_name'] == room_name
              next_room_id = door['room_id']
              break
            end
          end
        end
        if next_room_id
          @room = Model.new(@db, 'rooms', next_room_id)
          @user.room_id = next_room_id
          @user.save!
        else
          puts "there is no door for \"#{room_name}\""
        end
      },
      'mkdir' => lambda { |name, desc='a room'|
        room = Model.new(@db, 'rooms')
        room.name  = name
        room.desc  = desc
        room.items = []
        room.doors = [ {'room_name'=>@room.name, 'room_id'=>@room._id} ]

        exists = false
        @room.doors.each do |existing_door|
          if existing_door['room_name'] == room.name
            puts "INFO: ".colorize(:light_black) + " saving over existing room ".colorize(:light_cyan) + room.name.colorize(:light_blue)
            room._id = existing_door['room_id']
            exists   = true
          end
        end

        room.save!
        if not exists
          @room.doors << {'room_id'=>room._id, 'room_name'=>room.name}
          @room.save!
        end
      },
      'desc' => lambda { |new_description|
        @room.desc = new_description
        @room.save!
      },
      'touch' => lambda { |item_name, item_desc='an item'|
        @room.items << {'name'=>item_name, 'desc'=>item_desc}
        @room.save!
        puts "Created item: ".colorize(:light_green) +  item_name
      },
      'cat' => lambda { |item_name|
        @room.items.each do |item_data|
          if item_data['name'] == item_name
           puts item_data['desc']
          end
        end
      },
      'vi' => lambda { |item_name|
        w = ":w".colorize(:light_green)
        q = ":q".colorize(:light_red)
        msg  = "Type '".colorize(:light_black) + w +"' to ".colorize(:light_black) + "write".colorize(:light_green)
        msg << " and '".colorize(:light_black) + q +"' to ".colorize(:light_black) + "quit".colorize(:light_red)
        puts msg
        exists  = false
        lines   = []
        editing = true
        while editing
          print "> ".colorize(:light_black)
          line = $stdin.gets.chomp
          if line =~ /^\:w/
            editing = false
            desc    = colorize_markdown(lines.join("\n"))
            @room.items.each do |item_data|
              if item_data['name'] == item_name
                item_data['desc'] = desc
                @room.save!
                puts "Changed item: ".colorize(:light_green) + item_name
                exists = true
                break
              end
            end
            @cmd['touch'].call(item_name, desc) if not exists
          elsif line =~ /^\:q/
            editing = false
            puts "canceled without saving".colorize(:light_red)
          else
            lines << line
          end
        end
      },
      'rm_item' => lambda { |item_name|
        count = @room.items.count
        @room.items.delete_if { |i| i['name'] == item_name }
        if @room.items.count < count
          @room.save!
          puts "Deleted item: ".colorize(:light_yellow) + item_name
        else
          puts "Couldn't find item to delete: ".colorize(:light_red) + item_name
        end
      },
      'remember' => lambda {
        @user.remembered = {'room_name' => @room.name, 'room_id' => @room._id}
        @user.save!
        puts "Remembered room: ".light_green + @room.name.light_blue
      },
      'remembered' => lambda {
        if @user.remembered.nil?
          puts "You don't remember anything".light_cyan
        else
          puts "You remember a room: ".light_cyan + @user.remembered['room_name'].light_blue
        end
      }
    }

    @cmd['quit'] = @cmd['exit']
    @cmd['help'] = lambda {
      puts "Commands: #{@cmd.keys.sort.join(', ')}"
    }
  end

  ##########################################
  ## saving
  ##########################################

  def save (saved_name)
    @saved = Model.new(@db, 'saves', find_save_id(saved_name))
    @saved.rooms = []
    @saved.users = []
    @db.all!('rooms').each { |room| @saved.rooms << room }
    @db.all!('users').each { |user| @saved.users << user }
    @saved.user_id  = @user._id
    @saved.home_id  = @home._id
    @saved.name     = saved_name
    @saved.saved_at = Time.now
    @saved.save!
    puts "Saved as: ".colorize(:light_yellow) + saved_name
  end

  def ls_saves
    puts @db.all!('saves').map{|d| d['name']}.join(', ')
  end

  def find_save_id(name)
    found = []
    @db.all!('saves').each do |data|
      found << data if data['name'] == name
    end
    return found.count==1 ? found[0]['_id'] : nil
  end

  def rm_save(name)
    _id = find_save_id(name)
    if _id.nil?
      puts "couldn't find save: ".colorize(:light_red) + name
    else
      @db.destroy!('saves', _id)
      puts "Deleted save: ".colorize(:light_red) + name
    end
  end

  def load_save(name)
    _id = find_save_id(name)
    if _id.nil?
      puts "couldn't load save: ".colorize(:light_red) + name
    else
      saved = Model.new(@db, 'saves', _id)
      @db.destroy_collection!('rooms')
      @db.destroy_collection!('users')
      saved.rooms.each do |room_data|
        @db.save!('rooms', room_data)
      end
      saved.users.each do |user_data|
        @db.save!('users', user_data)
      end
      @home = Model.new(@db, 'rooms', saved.home_id)
      @user = Model.new(@db, 'users', saved.user_id)
      @room = Model.new(@db, 'rooms', @user.room_id)
      puts "Loaded save: ".colorize(:light_yellow) + name
      @cmd['ls'].call
    end
  end

  ##########################################
  ## other:
  ##########################################

  def commands
    @cmd
  end

  def update_room!
    @room = Model.new(@db, 'rooms', @user.room_id)
  end

  def prompt
    s = ""
    s << @user.name.colorize(:light_magenta)
    s << "@".colorize(:light_black)
    s << @room.name.colorize(:light_blue)
    s << "> ".colorize(:light_black)
  end

  def run
    @is_running = true
    begin
      while @is_running do
        update_room!
        $stdout.print prompt
        line = $stdin.gets.strip
        cmd, *args = Shellwords.shellsplit(line)
        next if cmd.nil?
        if @cmd[cmd]
          begin
            @cmd[cmd].call(*args)
          rescue Exception => e
            puts "command failed: ".colorize(:light_red) + line
            puts "  #{e.to_s}"
            e.backtrace.each { |bt| puts "  #{bt}".light_black }
          end
        else
          puts "unknown command: ".colorize(:light_red) + line
        end
      end
    ensure
      @db.destroy_collection!('users')
      @db.destroy_collection!('rooms')
    end
  end

  def colorize_markdown(text)
    text.gsub(/\[(.*?)\](.*?)\[\/.*?\]/) do
      methods = Regexp.last_match[1]
      string  = Regexp.last_match[2]
      methods.split('.').each do |method| 
        if method.length > 0
          begin
            string = string.send(method).to_s
          rescue Exception => e
            puts "markdown method failed: ".light_red + method
          end
        end
      end
      string
    end
  end

end




