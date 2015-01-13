
require_relative '../lib/client'

class Output
  attr_accessor :out, :err
  def initialize(out, err)
    @out = out
    @err = err
  end
end

class ClientTest < Minitest::Test

  def setup
    @client = Client.new('testdb')
    @client.instance_variable_set(:@use_stdout, false)
    @cmd   = @client.instance_variable_get(:@cmd)
    @world = @client.instance_variable_get(:@world)
    @db    = @world.instance_variable_get(:@db)
  end

  def teardown
    @client.instance_variable_set(:@user_stdout, false)
    @world.destroy_database!
  end

  def test_colorize_markdown input1 = '[blue]one[/blue]'
    input2 = '[blue]one[/]'
    expect = "\e[0;34;49mone\e[0m"
    assert_equal(expect, @client.colorize_markdown(input1))
    assert_equal(expect, @client.colorize_markdown(input2))

    input  = '[light_red]title[/light_red]\nline one\n[blue]line two[/blue]'
    expect = "\e[0;91;49mtitle\e[0m\\nline one\\n\e[0;34;49mline two\e[0m"
    assert_equal(expect, @client.colorize_markdown(input))

    input  = '[blue.on_red]one[/] and [red.on_blue]two[/] and [light_black.on_black]three[/]'
    expect = "\e[0;34;41mone\e[0m and \e[0;31;44mtwo\e[0m and \e[0;90;40mthree\e[0m"
    assert_equal(expect, @client.colorize_markdown(input))
  end

  def test_new
    assert_equal(World, @world.class)
    assert_equal(Hash,  @cmd.class)
  end

  def test_echo
    out, err = capture_io do
      @client.echo("something")
    end
    assert_equal("", out)
    assert_equal("", err)

    @client.instance_variable_set(:@use_stdout, true)
    out, err = capture_io do
      @client.echo("something")
    end
    assert_equal("something\n", out)
    assert_equal("", err)

    @client.instance_variable_set(:@use_stdout, false)
  end

  def test_prompt
    expect = "\e[0;95;49muser\e[0m\e[0;90;49m@\e[0m\e[0;94;49mhome\e[0m\e[0;90;49m> \e[0m"
    assert_equal(expect, @client.prompt)

    @cmd['mkdir'].call('room', 'a room')
    @cmd['cd'].call('room')

    expect = "\e[0;95;49muser\e[0m\e[0;90;49m@\e[0m\e[0;94;49mroom\e[0m\e[0;90;49m> \e[0m"
    assert_equal(expect, @client.prompt)

    @cmd['touch'].call('book', 'a book')
    @cmd['make'].call('dog', 'a dog')
    @cmd['mkdir'].call('pond', 'a pond')

    expect = "\e[0;95;49muser\e[0m\e[0;90;49m@\e[0m\e[0;94;49mroom\e[0m\e[0;90;49m> \e[0m"
    assert_equal(expect, @client.prompt)
  end

  def test_update_current_room!
    assert_equal('home', current_room.name)
    assert_equal(0, current_room.doors.count)
    assert_equal(0, current_room.items.count)
    assert_equal(0, current_room.mobs.count)

    r = Model.new(@db, 'rooms', current_room._id)
    r.items << @world.create_item_data('book', 'a book')
    r.mobs  << @world.create_mob_data('dog', 'a dog')
    r.save!

    assert_equal('home', current_room.name)
    assert_equal(0, current_room.doors.count)
    assert_equal(0, current_room.items.count)
    assert_equal(0, current_room.mobs.count)

    @client.update_current_room!

    assert_equal('home', current_room.name)
    assert_equal(0, current_room.doors.count)
    assert_equal(1, current_room.items.count)
    assert_equal(1, current_room.mobs.count)
  end

  def test_cmd_exit
    assert_equal(false, @client.instance_variable_get(:@is_running))
    @client.instance_variable_set(:@is_running, true)
    assert_equal(true, @client.instance_variable_get(:@is_running))
    @cmd['exit'].call
    assert_equal(false, @client.instance_variable_get(:@is_running))
  end

  def test_cmd_clear
    assert_equal("\e[H\e[2J\n", get_cmd_output('clear').out)
  end

  def test_cmd_room
    hash = eval(get_cmd_output('room').out)
    assert_equal("home", hash['name'])
    assert_equal([], hash['items'])
    assert_equal([], hash['doors'])
    assert_equal([], hash['mobs'])
  end

  def test_cmd_save
    assert_equal(0, @db.all!('saves').count)
    5.times.each { @cmd['save'].call }
    assert_equal(1, @db.all!('saves').count)
    5.times.each { @cmd['save'].call('myworld') }
    assert_equal(2, @db.all!('saves').count)
  end

  def test_cmd_ls_saves
    assert_equal("\n", get_cmd_output('ls_saves').out)

    @cmd['save'].call
    assert_equal("default\n", get_cmd_output('ls_saves').out)

    @cmd['save'].call('world32')
    assert_equal("default, world32\n", get_cmd_output('ls_saves').out)

    @cmd['save'].call('aardvark_heaven')
    assert_equal("aardvark_heaven, default, world32\n", get_cmd_output('ls_saves').out)
  end

  def test_cmd_load_save
    @cmd['save'].call
    @cmd['mkdir'].call('room2','a room')
    assert_equal(1, current_room.doors.count)
    @cmd['load_save'].call
    assert_equal(0, current_room.doors.count)
  end

  def test_cmd_rm_save
    @cmd['save'].call
    assert_equal("default\n", get_cmd_output('ls_saves').out)
    @cmd['rm_save'].call('default')
    assert_equal("\n", get_cmd_output('ls_saves').out)
  end

  def test_cmd_debug
    assert_equal(false, @db.debug?)
    @cmd['debug'].call
    assert_equal(true, @db.debug?)
    @cmd['debug'].call
    assert_equal(false, @db.debug?)
  end

  def test_cmd_ls
    expect = "\e[0;94;49mhome\e[0m\e[0;90;49m: \e[0m\e[0;37;49mhome\e[0m\n"
    doors  = "\e[0;90;49mdoors: [\e[0m\e[0;94;49mroom1\e[0m\e[0;90;49m]\e[0m\n"
    mobs   = "\e[0;90;49mmobs: [\e[0m\e[0;91;49mdog\e[0m\e[0;90;49m]\e[0m\n"
    items  = "\e[0;90;49mitems: [\e[0m\e[0;93;49mbook\e[0m\e[0;90;49m]\e[0m\n"

    assert_equal(expect, get_cmd_output('ls').out)

    @cmd['mkdir'].call('room1', 'a room')
    expect = "#{expect}#{doors}"
    assert_equal(expect, get_cmd_output('ls').out)

    @cmd['touch'].call('book', 'a book')
    expect = "#{expect}#{items}"
    assert_equal(expect, get_cmd_output('ls').out)

    @cmd['make'].call('dog', 'a dog')
    expect = "#{expect}#{mobs}"
    assert_equal(expect, get_cmd_output('ls').out)
  end

  def test_cmd_cd
    @cmd['mkdir'].call('room1', 'a room')
    hash = eval(get_cmd_output('room').out)
    assert_equal('home',  hash['name'])
    assert_equal('room1', hash['doors'][0]['room_name'])

    @cmd['cd'].call('room1')
    hash = eval(get_cmd_output('room').out)
    assert_equal('room1', hash['name'])
    assert_equal('home',  hash['doors'][0]['room_name'])

    @cmd['cd'].call
    hash = eval(get_cmd_output('room').out)
    assert_equal('home',  hash['name'])
    assert_equal('room1', hash['doors'][0]['room_name'])
  end

  def test_cmd_mkdir
    10.times.each { |i| @cmd['mkdir'].call("room_#{i}", "a room") }
    rooms = @world.all_rooms!
    assert_equal(11, rooms.count)

    names = rooms.map { |r| r.name }
    10.times.each { |i| assert(names.include?("room_#{i}")) }
  end

  def test_cmd_rmdir
    10.times.each { |i| @cmd['mkdir'].call("room_#{i}", "a room") }
    names = current_room.doors.map { |r| r['room_name'] }
    10.times.each { |i| assert(names.include?("room_#{i}")) }

    @cmd['rmdir'].call('room_9')
    names = current_room.doors.map { |r| r['room_name'] }
    assert_equal(false, names.include?('room_9'))

    @cmd['rmdir'].call('room_3')
    names = current_room.doors.map { |r| r['room_name'] }
    assert_equal(false, names.include?('room_3'))

    @cmd['rmdir'].call('room_1')
    names = current_room.doors.map { |r| r['room_name'] }
    assert_equal(false, names.include?('room_1'))
  end

  def test_cmd_desc
  end

  def test_cmd_touch
  end

  def test_cmd_cat
  end

  def test_cmd_vi
  end

  def test_cmd_rm_item
  end

  def test_cmd_remember
  end

  def test_cmd_remembered
  end

  def test_cmd_make
  end

  def test_cmd_link
  end

  def test_cmd_rm_mob
  end

  def test_cmd_help
  end

  private

    def get_cmd_output(cmd, *args)
      @client.instance_variable_set(:@use_stdout, true)
      out,err = capture_io do
        @cmd[cmd].call(*args)
      end
      @client.instance_variable_set(:@use_stdout, false)
      Output.new(out,err)
    end

    def current_room
      @client.instance_variable_get(:@room)
    end

end
