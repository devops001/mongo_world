#!/usr/bin/env ruby

require 'shellwords'
require 'colorize'
require_relative 'player'
require_relative 'room'

class Client

  def initialize
    Room.init
    Player.init
    @player = Player.create('player', Room.home)
    @cmd    = {
      'exit'  => lambda { exit 0 },
      'clear' => lambda { puts `clear` },
      'look'  => lambda { 
        @player.room.refresh!
        mobs  = @player.room.mobs
        items = @player.room.items
        doors = @player.room.doors
        puts
        puts "You are in ".colorize(:light_black) + @player.room.desc.colorize(:white)
        if mobs.length>0 or items.length>0
          print "You see ".colorize(:light_black)
          if mobs.length>0 
            print mobs.colorize(:red) 
            if items.length>0
              print ", ".colorize(:light_black) 
            end
          end
          if items.length>0  
            print items.colorize(:yellow)
          end
          puts
        end

        if doors.length>0
          #puts "doors: [".colorize(:light_black) + doors.colorize(:light_blue) +"]".colorize(:light_black)
          puts doors.inspect
        end
      },
      'cd' => lambda { |room_name|
        data = Room.collection.find_one(:name => room_name)
        room = Room.find(data[:_id])
        @player.room = room if room
      },
      'create_room' => lambda { |name,desc|
        room = Room.create(name, desc)
        room.add_door_to(@player.room)
      },
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
