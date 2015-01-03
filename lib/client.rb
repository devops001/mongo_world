#!/usr/bin/env ruby

require 'shellwords'
require 'colorize'
require_relative 'model'
require_relative 'player'
require_relative 'room'

class Client
  attr_reader :home, :player

  def initialize(debug=false)
    Model.debug = debug
    Room.init!
    Player.init!
    Room.destroy_all!
    Player.destroy_all!

    @home   = Room.create!('home', 'a small white room')
    @player = Player.create!('player', @home)

    @cmd = {
      'exit'  => lambda { exit 0 },
      'clear' => lambda { puts `clear` },
      'look'  => lambda { |name=nil|
        room = @player.get_room!
        if name.nil?
          puts "You are in ".colorize(:light_black) + room.desc.colorize(:white)
          puts "doors: [".colorize(:light_black) + room.list_doors.colorize(:light_blue) +"]".colorize(:light_black)
        else
          desc = nil
          room.doors.each do |door|
            if door['room_name'] == name
              found_room = Room.find!(door['room_id'])
              if found_room
                desc = "you see a ".colorize(:light_black) + found_room.desc.colorize(:white)
              end
            end
          end
          if desc.nil?
            puts "you don't see anything like that".colorize(:light_red)
          else
            puts desc
          end
        end
      },
      'cd' => lambda { |room_name=nil|
        if room_name.nil?
          next_room_id = @home._id
        else
          this_room = @player.get_room!
          next_room_id = nil
          this_room.doors.each do |door|
            next_room_id = door['room_id'] if door['room_name'] == room_name
          end
        end
        if next_room_id
          next_room = Room.find!(next_room_id)
          if next_room
            @player.set_room!(next_room) 
          end
        else
          puts "there is no door for \"#{room_name}\""
        end
      },
      'create_room' => lambda { |name, desc='a room'|
        room = Room.create!(name, desc)
        if room
          room.connect!(@player.get_room!)
        else
          puts "couldn't create room: ".colorize(:red) + room.inspect
        end
      },
      'debug' => lambda {
        if Model.debug
          Model.debug = false
          puts "debug is now disabled"
        else
          Model.debug = true
          puts "debug is now enabled"
        end
      },
      'desc' => lambda { |new_description|
        room = @player.get_room!
        room.set('desc', new_description)
        room.save!
        puts room.name.colorize(:light_blue) + " has been updated.".colorize(:light_yellow)
      }
    }
    @cmd['quit']  = @cmd['exit']
    @cmd['ls']    = @cmd['look']
    @cmd['mkdir'] = @cmd['create_room']
    @cmd['help'] = lambda {
      puts "Commands: #{@cmd.keys.sort.join(', ')}"
    }
  end

  def prompt
    room = @player.get_room!
    s = ""
    s << @player.name.colorize(:light_magenta)
    s << "@".colorize(:light_black)
    s << room.name.colorize(:light_blue)
    s << "> ".colorize(:light_black)
  end

  def commands
    @cmd.keys.sort
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
