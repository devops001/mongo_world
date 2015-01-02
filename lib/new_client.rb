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
          puts "doors: [".colorize(:light_black) + doors.colorize(:light_blue) +"]".colorize(:light_black)
        end
      },
      'cd' => lambda { |room_name|
        room = @db.find_room(room_name)
        @player.room = room if room
      },
      'doors' => lambda {
        puts @db.list_doors_in_room(@player.room['name'])
      },
      'items' => lambda {
        puts @db.list_items_in_room(@player.room['name'])
      },
      'mobs' => lambda {
        puts @db.list_mobs_in_room(@player.room['name'])
      },
      'create_room' => lambda { |name,desc|
        @db.create_room(name, desc, @player.room['name'])
      },
      'create_mob' => lambda { |name,desc|
        @db.create_mob(name, desc)
      },
      'create_item' => lambda { |name,desc|
        @db.create_item(name, desc)  
      },
      'add_mob' => lambda { |mob_name|
        @db.add_mob(@player.room['name'], mob_name)
      },
      'add_item' => lambda { |item_name|
        @db.add_item(@player.room['name'], item_name)
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
