
require 'colorize'
require_relative 'model'

class Mob < Model

  def initialize(db, name, desc='a mob')
    super(db, 'mobs')
    self.name = name
    self.desc = desc
  end

  def take_turn
    puts "#{@name} looks around".light_black
  end

end


