
require_relative '../lib/client'

class ClientTest < Minitest::Test

  def setup
    @client = Client.new('testdb')
    @client.instance_variable_set(:@use_stdout, false)
    @db     = @client.instance_variable_get(:@db)
    @home   = @client.instance_variable_get(:@home)
    @room   = @client.instance_variable_get(:@room)
    @cmd    = @client.instance_variable_get(:@cmd)
  end

  def teardown
    @db.destroy_all!
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
    assert_equal(Model, @home.class)
    assert_equal(Model, @room.class)
    assert_equal(Db,    @db.class)
    assert_equal(Hash,  @cmd.class)
  end

  def test_save
    assert_equal(0, @db.all!('saves').count)

    save1, save2, save3 = nil, nil, nil

    3.times do 
      save1 = @client.save('world1')
      save2 = @client.save('world2')
      save3 = @client.save
    end

    saves = @db.all!('saves')

    assert_equal(3, saves.count)
    assert_equal(1, save1.rooms.count)
    assert_equal(1, save2.users.count)
    assert_equal(0, save3.mobs.count)

    found = Hash.new(false)
    saves.each { |s| found[s['name']] = true }

    assert(found['world1'])
    assert(found['world2'])
    assert(found['default'])
  end

  def test_ls_saves
    assert_equal("", @client.ls_saves())
    3.times.each { |i| @client.save("world#{i}") }
    assert_equal("world0, world1, world2", @client.ls_saves())
  end

  def test_find_save_id
    assert_nil(@client.find_save_id('world1'))

    saved = @client.save('world1')
    id    = @client.find_save_id('world1')
    assert(id)

    found = @db.find!('saves', id)

    assert_equal(saved.rooms,    found['rooms'])
    assert_equal(saved.users,    found['users'])
    assert_equal(saved.mobs,     found['mobs'])
    assert_equal(saved.user_id,  found['user_id'])
    assert_equal(saved.home_id,  found['home_id'])
    assert_equal(saved.name,     found['name'])
    assert_equal(Time.at(saved.saved_at.to_i), Time.at(found['saved_at'].to_i))
  end

  def test_rm_save
    @client.save('place1')
    @client.save('place2')
    assert_equal(2, @db.all!('saves').count)

    @client.rm_save('fake')
    assert_equal(2, @db.all!('saves').count)

    @client.rm_save('place1')
    assert_equal(1, @db.all!('saves').count)

    @client.rm_save('place1')
    assert_equal(1, @db.all!('saves').count)

    @client.rm_save('place2')
    assert_equal(0, @db.all!('saves').count)

    @client.rm_save('place2')
    assert_equal(0, @db.all!('saves').count)
  end

  def test_load_save
  end

  def test_commands
  end

  def test_update_room!
  end

  def test_prompt
  end

  def test_run
  end

end
