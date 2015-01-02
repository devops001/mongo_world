
class Door
  attr_accessor :room_name, :room_id

  def initialize(room_name, room_id)
    @room_name = room_name
    @room_id   = room_id
  end

  def to_h
    { 'room_name' => @room_name, 'room_id' => @room_id }
  end

  def to_s
    @room_name
  end

end

