require 'rake/testtask'
require 'bundler/setup'

Rake::TestTask.new('test') do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = false
end

task 'default' => 'test'