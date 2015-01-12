
require_relative 'db'

class Model 
  def initialize(db, collection_name, _id=nil)
    @db      = db
    @colname = collection_name
    if _id.nil?
      @data = {}
    else
      data  = @db.find!(@colname, _id)
      @data = data.nil? ? {} : data
    end
  end

  def refresh!
    @data = @db.find!(@colname, @data['_id']) if @data['_id']
  end

  def save!
    @data = @db.save!(@colname, @data) 
  end

  def method_missing(meth, *args, &block)
    if @data.include?(meth.to_s)
      @data[meth.to_s]
    elsif meth =~ /(.*)=/
      @data[$1] = args[0]
    else
      super
    end
  end

  def to_s
    @data.inspect
  end

	def data=(data)
		@data = data
	end

end
