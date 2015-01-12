
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
    @world.destroy_collections!
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

end
