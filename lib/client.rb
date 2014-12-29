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
      },
      'items' => lambda {
        items = @player.room['items']
        puts "items: #{items.join(', ')}" if items.count > 0
      },
      'mobs' => lambda {
        mobs  = @player.room['mobs']
        puts "mobs: #{mobs.join(', ')}" if mobs.count > 0
      },
      'addroom' => lambda { |*args|
        puts "adding room with args: #{args}"
      }
    }
    @cmd['quit'] = @cmd['exit']
    @cmd['ls']   = @cmd['look']
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
