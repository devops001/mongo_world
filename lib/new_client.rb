#!/usr/bin/env ruby

require 'shellwords'
require 'colorize'
require_relative 'player'
require_relative 'room'

class Client

  def initialize
    Room.init
    @rooms  = [Room.new('home', 'a small white room')]
    @player = Player.create('player', @rooms[0])
    @cmd    = {
      'exit'  => lambda { exit 0 },
      'clear' => lambda { puts `clear` },
      'look'  => lambda { 
        room  = @player.room
        desc  = @player.room
        mobs  = @player
        items = @db.list_items_in_room(room_name)
        doors = @db.list_doors_in_room(room_name)

        puts
        puts "You are in ".colorize(:light_black) + desc.colorize(:white)
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
          puts "exits: [".colorize(:light_black) + doors.colorize(:light_blue) +"]".colorize(:light_black)
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
    s << @player.room['name'].colorize(:light_blue)
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
