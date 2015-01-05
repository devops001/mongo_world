#!/usr/bin/env ruby

require 'shellwords'
require_relative 'db'

class Client

  def initialize
    setup_data
    setup_commands
  end

  def setup_data
    @db = Db.new

    @home = Model.new(@db, 'rooms')
    @home.name  = 'home'
    @home.desc  = 'a home'
    @home.doors = [];
    @home.save!
    
    @player = Model.new(@db, 'players')
    @player.name    = 'player'
    @player.desc    = 'a player' 
    @player.room_id = @home._id
    @player.save!

    update_room!
  end

  def setup_commands
    @cmd = {
      'exit'  => lambda { exit 0 },
      'clear' => lambda { puts `clear` },
      'room'  => lambda { puts @room },
      'debug' => lambda { 
        print "debug is ".colorize(:light_black)
        puts @db.toggle_debug ? "on".colorize(:light_green) : "off".colorize(:light_red)
      },
      'ls'    => lambda { 
        doors = @room.doors.map { |door| door['room_name'] }.join(', ').colorize(:light_blue)
        puts @room.name.colorize(:light_blue) +": ".colorize(:light_black) + @room.desc.colorize(:white)
        puts "doors: [".colorize(:light_black) + doors +"]".colorize(:light_black)
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
          @player.room_id = next_room_id
        else
          puts "there is no door for \"#{room_name}\""
        end
      },
      'mkdir' => lambda { |name, desc='a room'|
        room = Model.new(@db, 'rooms')
        room.name  = name
        room.desc  = desc
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
      }
    }
    @cmd['quit'] = @cmd['exit']
    @cmd['help'] = lambda {
      puts "Commands: #{@cmd.keys.sort.join(', ')}"
    }
  end

  def commands
    @cmd
  end

  def update_room!
    @room = Model.new(@db, 'rooms', @player.room_id)
  end

  def prompt
    s = ""
    s << @player.name.colorize(:light_magenta)
    s << "@".colorize(:light_black)
    s << @room.name.colorize(:light_blue)
    s << "> ".colorize(:light_black)
  end

  def run
    loop do
      $stdout.print prompt
      line = $stdin.gets.strip
      cmd, *args = Shellwords.shellsplit(line)
      next if cmd.nil?
      if @cmd[cmd]
        @cmd[cmd].call(*args)
        update_room!
      else
        puts "unknown command: #{line}"
      end
    end
  end

end
