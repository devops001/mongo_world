
require_relative '../lib/client'

class ClientTest < Minitest::Test

  def setup
    @client = Client.new('testdb')
    @client.instance_variable_set(:@use_stdout, false)
    @cmd   = @client.instance_variable_get(:@cmd)
    @world = @client.instance_variable_get(:@world)
    @db    = @world.instance_variable_get(:@db)
  end

  def teardown
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
    room = @client.instance_variable_get(:@room)

    assert_equal('home', room.name)
    assert_equal(0, room.doors.count)
    assert_equal(0, room.items.count)
    assert_equal(0, room.mobs.count)

    r = Model.new(@db, 'rooms', room._id)
    r.items << @world.create_item_data('book', 'a book')
    r.mobs  << @world.create_mob_data('dog', 'a dog')
    r.save!

    room = @client.instance_variable_get(:@room)
    assert_equal('home', room.name)
    assert_equal(0, room.doors.count)
    assert_equal(0, room.items.count)
    assert_equal(0, room.mobs.count)

    @client.update_current_room!

    room = @client.instance_variable_get(:@room)
    assert_equal('home', room.name)
    assert_equal(0, room.doors.count)
    assert_equal(1, room.items.count)
    assert_equal(1, room.mobs.count)
  end

end
