
require 'rake/testtask'
 
######################
## test
######################

Rake::TestTask.new do |t|
  t.libs.push 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end
 
task :default => :test
 
######################
## coverage
######################

desc 'Generates a coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end

######################
## setup
######################

desc 'Setup the test helper and an example test script'
task :setup do

  puts "Adding to .gitignore..."
  File.open('.gitignore','a') do |f| 
    f.puts 'coverage/*'
    f.puts 'test/example_test.rb'
  end

  if not Dir.exist?("test")
    puts "Creating the 'test' directory..."
    sh "mkdir test" 
  end

  puts "Creating the 'test/test_helper.rb' file..."
  File.open("test/test_helper.rb",'w') do |f|
    f.puts "if ENV['COVERAGE']"
    f.puts "  require 'simplecov'"
    f.puts "  SimpleCov.start do"
    f.puts "    add_filter 'test'"
    f.puts "    command_name 'Minitest'"
    f.puts "  end"
    f.puts "end"
    f.puts ""
    f.puts "require 'minitest/autorun'"
  end

  puts "Creating the 'test/example_test.rb' file..."
  File.open("test/example_test.rb",'w') do |f|
    f.puts "require_relative 'test_helper'"
    f.puts ""
    f.puts "class ExampleTest < Minitest::Test"
    f.puts "  def setup"
    f.puts "    @var = 'something'"
    f.puts "  end"
    f.puts ""
    f.puts "  def test_something"
    f.puts "    assert_equal('something', @var)"
    f.puts "  end"
    f.puts "end"
  end

  puts "Testing the tests..."
  Rake::Task["test"].execute
end


