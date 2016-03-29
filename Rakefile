# frozen_string_literal: true
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

Dir.glob('tasks/*.rake').each { |r| import r }

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Run style checker"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

desc "Run continuous integration tests"
task ci: [:rubocop, :spec]

task default: :ci
