
require_relative '../lib/client'

class ClientTest < Minitest::Test

  def setup
    @client = Client.new
  end

  def test_colorize_markdown
    input  = '[light_red]title[/light_red]\nline one\n[blue]line two[/blue]'
    expect = "\e[0;91;49mtitle\e[0m\\nline one\\n\e[0;34;49mline two\e[0m"
    assert_equal(expect, @client.colorize_markdown(input))
  end

end

