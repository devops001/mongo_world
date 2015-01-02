#!/usr/bin/env ruby

require_relative 'lib/client'

$log_file = 'mongo_world.log'
File.delete($log_file) if File.exist?($log_file)

def log(msg, type=nil)
  stamp = Time.now.strftime("%H:%M:%S")
  msg   = "[#{type}] #{msg}" if type
  File.open($log_file, 'a') { |f| f.puts "#{stamp} #{msg}" }
end

Client.new.run

