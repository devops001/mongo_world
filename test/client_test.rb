
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

  def test_colorize_markdown
    input1 = '[blue]one[/blue]'
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

    @client.save('world1')
    @client.save('world2')

    saves = @db.all!('saves')
    assert_equal(2, saves.count)

    found = Hash.new(false)
    saves.each { |s| found[s['name']] = true }

    assert(found['world1'])
    assert(found['world2'])
  end

  def test_ls_saves
  end

  def test_find_save_id
  end

  def test_rm_save
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
