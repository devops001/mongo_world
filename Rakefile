
require 'minitest'

desc 'run tests'
task :test do
  $LOAD_PATH.unshift('lib', 'test')
  Dir.glob('./test/**/*_test.rb') { |f| puts "require '#{f}': #{require f}" }
  require 'minitest/autorun'
end

task :default => :test
