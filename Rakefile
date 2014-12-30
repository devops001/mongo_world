
desc 'run tests'
task :test do
  require 'minitest/autorun'
  $LOAD_PATH.unshift('lib', 'test')
  Dir.glob('./test/**/*_test.rb') { |f| puts "require '#{f}': #{require f}" }
end

task :default => :test
