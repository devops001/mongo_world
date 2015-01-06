
require 'colorize'

class ColorizeTest < Minitest::Test

  def setup
    @input1 = '[light_red]title[/light_red]\nline one\n[blue]line two[/blue]'
    @regex  = %r{\[(.*?)\](.*?)\[\/.*?\]}
  end

  def test_regex
    result1 = @input1.gsub(@regex) { 
      text  = Regexp.last_match[2]
      color = Regexp.last_match[1]
      text.colorize(color.to_sym)
    }

    expect = "\e[0;91;49mtitle\e[0m\\nline one\\n\e[0;34;49mline two\e[0m"
    assert_equal(expect, result1)
  end

end
