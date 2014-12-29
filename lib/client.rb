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
      'look' => lambda { puts "you see #{@player.room['desc']}" }
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
