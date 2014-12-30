#!/usr/bin/env ruby

require 'shellwords'
require_relative 'db'
require_relative 'player'

class Client

  def initialize
    @db     = Database.new
    @player = Player.new(@db.starting_room)
    @cmd    = {
      'exit' => lambda { exit 0 },
      'look' => lambda { 
        puts
        puts "You are in #{@player.room['desc']}"
        @cmd['mobs'].call
        @cmd['items'].call
        @cmd['doors'].call
      },
      'cd' => lambda { |room_name|
        room = @db.find_room(room_name)
        @player.room = room if room
      },
      'doors' => lambda {
        puts "doors: #{@db.list_doors_in_room(@player.room['name'])}"
      },
      'items' => lambda {
        puts "items: #{@db.list_items_in_room(@player.room['name'])}"
      },
      'mobs' => lambda {
        puts "mobs: #{@db.list_mobs_in_room(@player.room['name'])}"
      },
      'create_room' => lambda { |name,desc|
        @db.create_room(name, desc)
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
    "#{@player.name}@#{@player.room['name']}> "
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
