#!/usr/bin/env ruby

require 'shellwords'
require 'colorize'
require_relative 'model'
require_relative 'player'
require_relative 'room'

class Client

  def setup_db
    Model.debug = true
    Room.init!
    Player.init!
    Room.destroy_all!
    Player.destroy_all!
  end

  def initialize
    setup_db

    @player = Player.create!('player', Room.home)

    @cmd = {
      'exit'  => lambda { exit 0 },
      'clear' => lambda { puts `clear` },
      'look'  => lambda { 
        @player.room.refresh!
        puts
        puts "You are in ".colorize(:light_black) + @player.room.desc.colorize(:white)
        puts "doors: [".colorize(:light_black) + @player.room.list_doors.colorize(:light_blue) +"]".colorize(:light_black)
      },
      'cd' => lambda { |room_name|
        room_id = nil
        @player.room.doors.each do |door|
          room_id = door['room_id'] if door['room_name'] == room_name
        end
        if room_id
          room = Room.find!(room_id)
          @player.room = room if room
        end
      },
      'create_room' => lambda { |name,desc|
        room = Room.new
        room.set('name', name)
        room.set('desc', desc)
        room.connect!(@player.room)
      },
      'debug' => lambda {
        if Model.debug
          Model.debug = false
          puts "debug is now disabled"
        else
          Model.debug = true
          puts "debug is now enabled"
        end
      }
    }
    @cmd['quit'] = @cmd['exit']
    @cmd['ls']   = @cmd['look']
    @cmd['help'] = lambda {
      puts "Commands: #{@cmd.keys.sort.join(', ')}"
    }
  end

  def prompt
    s = ""
    s << @player.name.colorize(:light_magenta)
    s << "@".colorize(:light_black)
    s << @player.room.name.colorize(:light_blue)
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
      else
        puts "unknown command: #{line}"
      end
    end
  end

end
