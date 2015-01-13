#!/usr/bin/env ruby

require 'shellwords'
require_relative 'world'

class Client

  def initialize(dbname='mongo_world')
    @world      = World.new(dbname)
    @is_running = false
    @use_stdout = true

    @home = @world.create_room!('home', 'home')
    @user = @world.create_user!('user', 'user', @home._id)
    update_current_room!


    @cmd = {
      'exit' => lambda { 
        @is_running=false 
      },
      'clear' => lambda { 
        echo `clear` 
      },
      'room' => lambda { 
        echo @room
      },
      'save' => lambda { |name='default'| 
        @world.save!(name, @home._id, @user._id) 
      },
      'ls_saves' => lambda { 
        echo @world.get_save_names!.sort.join(', ')
      },
      'load_save' => lambda { |name='default'| 
        saved = @world.load_save!(name) 
        @user = @world.find_user!(saved.user_id)
        @home = @world.find_room!(saved.home_id)
        update_current_room!
      },
      'rm_save' => lambda { |name| 
        @world.destroy_save!(name) 
      },
      'debug' => lambda {
        msg = "debug is ".light_black 
        if @world.debug?
          @world.set_debug(false)
          msg << "off".light_red
        else
          @world.set_debug(true)
          msg << "on".light_green
        end
        echo msg
      },
      'ls' => lambda {
        doors = @room.doors.map { |door| door['room_name'] }.join(', ').light_blue
        items = @room.items.map { |item| item['name']      }.join(', ').light_yellow
        mobs  = @room.mobs.map  { |mob|  mob['name']       }.join(', ').light_red
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
          @user.room_id = next_room_id
          @user.save!
          update_current_room!
        else
          echo "there is no door for \"#{room_name}\""
        end
      },
      'mkdir' => lambda { |name, desc='a room'|
        room = @world.create_room!(name, desc)
        @world.create_doors!(room, @room)
        echo "created room: ".light_green + name
      },
      'rmdir' => lambda { |name|
        room = @world.get_room_from_door(name)
        if room
          @world.remove_doors!(room, @room)
          echo "removed door to: ".light_green + name
        else
          echo "no door found for name: ".light_red + name
        end
      },
      'desc' => lambda { |new_description|
        @room.desc = new_description
        @room.save!
        echo "updated: ".light_green + @room.name
      },
      'touch' => lambda { |item_name, item_desc='an item'|
        @world.upsert_item!(@room, @world.create_item_data(item_name, item_desc))
        echo "touched item: ".light_green + item_name
      },
      'cat' => lambda { |item_name|
        item = @world.get_item_data(@room, item_name)
        if item
          echo item['desc']
        else
          echo "no item found with name: ".light_red + item_name
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
            @world.upsert_item!(@room, @world.create_item_data(item_name, desc))
          elsif line =~ /^\:q/
            editing = false
            echo "canceled without saving".light_red
          else
            lines << line
          end
        end
      },
      'rm_item' => lambda { |item_name|
        if @world.destroy_item!(@room, item_name)
          echo "destroyed item: ".light_green + item_name
        else
          echo "no item found with name:  ".light_red + item_name
        end
      },
      'remember' => lambda {
        @user.remembered = @world.create_door_data(@room)
        @user.save!
        echo "you will remember this room: ".light_green + @room.name.light_blue
      },
      'remembered' => lambda {
        if @user.remembered.nil?
          echo "you don't remember anything".light_cyan
        else
          echo "you remember a room: ".light_cyan + @user.remembered['room_name'].light_blue
        end
      },
      'make' => lambda { |name, desc='a mob'|
        @room.mobs << @world.create_mob_data(name, desc)
        @room.save!
        echo "created mob: ".light_green + name
      },
      'link' => lambda {
        if @user.remembered.nil?
          puts "You don't remember any rooms to link to".light_red
        else
          room = @world.get_remembered_room
          @world.create_doors!(@room, @world.get_remembered_room)
          puts "created a link to: ".light_green + room.name
        end
      },
      'rm_mob' => lambda { |name|
        @world.destroy_mob!(@room, name)
      }
    }

    @cmd['quit'] = @cmd['exit']
    @cmd['help'] = lambda {
      echo "Commands: #{@cmd.keys.sort.join(', ')}"
    }
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
        next if cmd.nil? or cmd.length==0
        if @cmd[cmd]
          update_current_room!
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
      @world.destroy_collections!
    end
  end

  def update_current_room!
    @room = @world.find_room!(@user.room_id)
  end

end


