#!/usr/bin/env ruby

require 'shellwords'
require_relative 'model'
require_relative 'mob'

class Client

  ##########################################
  ## initializing:
  ##########################################

  def initialize(dbname='mongo_world')
    initialize_data(dbname)
    initialize_commands
    @is_running = false
    @use_stdout = true
  end

  def initialize_data(dbname)
    @db = Db.new(dbname)
    @db.destroy_collection!('rooms')
    @db.destroy_collection!('users')
    @db.destroy_collection!('items')

    @home = Model.new(@db, 'rooms')
    @home.name  = 'home'
    @home.desc  = 'a home'
    @home.doors = [];
    @home.items = [];
    @home.mobs  = []
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
      'clear' => lambda { echo `clear` },
      'room'  => lambda { echo @room },
      'save'  => lambda { |name='default'| save(name) },
      'ls_saves'  => lambda { ls_saves },
      'load_save'   => lambda { |name='default'| load_save(name) },
      'rm_save'     => lambda { |name| rm_save(name) },
      'debug' => lambda {
        print "debug is ".light_black
        echo @db.toggle_debug ? "on".light_green : "off".light_red
      },
      'ls'    => lambda {
        doors = @room.doors.map { |door| door['room_name'] }.join(', ').light_blue
        items = @room.items.map { |item| item['name']      }.join(', ').light_yellow
        mobs  = @room.mobs.map  { |mob|  mob['mob_name']   }.join(', ').light_red
        echo @room.name.light_blue << ": ".light_black << @room.desc.white
        echo "doors: [".light_black + doors +"]".light_black if doors.length>0
        echo "items: [".light_black + items +"]".light_black if items.length>0
        echo "mobs: [".light_black  + mobs  +"]".light_black if mobs.length>0
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
          echo "there is no door for \"#{room_name}\""
        end
      },
      'mkdir' => lambda { |name, desc='a room'|
        room = Model.new(@db, 'rooms')
        room.name  = name
        room.desc  = desc
        room.items = []
        room.mobs  = []
        room.doors = [ {'room_name'=>@room.name, 'room_id'=>@room._id} ]

        exists = false
        @room.doors.each do |existing_door|
          if existing_door['room_name'] == room.name
            echo "INFO: ".light_black + " saving over existing room ".light_cyan + room.name.light_blue
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
        echo "Created item: ".light_green +  item_name
      },
      'cat' => lambda { |item_name|
        @room.items.each do |item_data|
          if item_data['name'] == item_name
           echo item_data['desc']
          end
        end
      },
      'vi' => lambda { |item_name|
        w = ":w".light_green
        q = ":q".light_red
        msg  = "Type '".light_black + w +"' to ".light_black + "write".light_green
        msg << " and '".light_black + q +"' to ".light_black + "quit".light_red
        echo msg
        exists  = false
        lines   = []
        editing = true
        while editing
          print "> ".light_black
          line = $stdin.gets.chomp
          if line =~ /^\:w/
            editing = false
            desc    = colorize_markdown(lines.join("\n"))
            @room.items.each do |item_data|
              if item_data['name'] == item_name
                item_data['desc'] = desc
                @room.save!
                echo "Changed item: ".light_green + item_name
                exists = true
                break
              end
            end
            @cmd['touch'].call(item_name, desc) if not exists
          elsif line =~ /^\:q/
            editing = false
            echo "canceled without saving".light_red
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
          echo "Deleted item: ".light_yellow + item_name
        else
          echo "Couldn't find item to delete: ".light_red + item_name
        end
      },
      'remember' => lambda {
        @user.remembered = {'room_name' => @room.name, 'room_id' => @room._id}
        @user.save!
        echo "You look around and will remember this room: ".light_green + @room.name.light_blue
      },
      'remembered' => lambda {
        if @user.remembered.nil?
          echo "You don't remember anything".light_cyan
        else
          echo "You remember a room: ".light_cyan + @user.remembered['room_name'].light_blue
        end
      },
      'make' => lambda { |name,desc='a mob'|
        #mob = Model.new(@db, 'mobs')
        mob = Mob.new(@db, name, desc)
        mob.save!
        @room.mobs << {'mob_name'=>mob.name, 'mob_id'=>mob._id}
        @room.save!
        echo "Created mob: ".light_green + name
      }
    }

    @cmd['quit'] = @cmd['exit']
    @cmd['help'] = lambda {
      echo "Commands: #{@cmd.keys.sort.join(', ')}"
    }
  end

  ##########################################
  ## saving
  ##########################################

  def save(saved_name='default')
    saved          = Model.new(@db, 'saves', find_save_id(saved_name))
    saved.rooms    = @db.all!('rooms')
    saved.users    = @db.all!('users')
    saved.mobs     = @db.all!('mobs')
    saved.user_id  = @user._id
    saved.home_id  = @home._id
    saved.name     = saved_name
    saved.saved_at = Time.now
    saved.save!
    echo "Saved as: ".light_yellow + saved_name
    saved
  end

  def ls_saves
    output = @db.all!('saves').map{|d| d['name']}.join(', ')
    echo output
    output
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
      echo "couldn't find save: ".light_red + name
    else
      @db.destroy!('saves', _id)
      echo "Deleted save: ".light_red + name
    end
  end

  def load_save(name)
    _id = find_save_id(name)
    if _id.nil?
      echo "couldn't load save: ".light_red + name
    else
      saved = Model.new(@db, 'saves', _id)
      @db.destroy_collection!('rooms')
      @db.destroy_collection!('users')
      @db.destroy_collection!('mobs')
      saved.rooms.each do |room_data|
        @db.save!('rooms', room_data)
      end
      saved.users.each do |user_data|
        @db.save!('users', user_data)
      end
      saved.mobs.each do |mob_data|
        @db.save!('mobs', mob_data)
      end
      @home = Model.new(@db, 'rooms', saved.home_id)
      @user = Model.new(@db, 'users', saved.user_id)
      @room = Model.new(@db, 'rooms', @user.room_id)
      echo "Loaded save: ".light_yellow + name
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
    s << @user.name.light_magenta
    s << "@".light_black
    s << @room.name.light_blue
    s << "> ".light_black
  end

  def run
    @is_running = true
    begin
      while @is_running do
        $stdout.print prompt
        line = $stdin.gets.strip
        begin
          cmd, *args = Shellwords.shellsplit(line)
        rescue Exception => e
          echo "command failed: ".light_red + line
          echo "  #{e.to_s}"
          e.backtrace.each { |bt| echo "  #{bt}".light_black }
          next
        end
        next if cmd.nil?
        if @cmd[cmd]
          update_room!
          begin
            @cmd[cmd].call(*args)
          rescue Exception => e
            echo "command failed: ".light_red + line
            echo "  #{e.to_s}"
            e.backtrace.each { |bt| echo "  #{bt}".light_black }
            next
          end
        else
          echo "unknown command: ".light_red + line
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
            echo "markdown method failed: ".light_red + method
          end
        end
      end
      string
    end
  end

  def echo(text)
    puts text if @use_stdout
  end

end




