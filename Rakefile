# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/*_test.rb'
end

desc 'Run RuboCop'
task :lint do
  sh 'bundle exec rubocop'
end

desc 'Run CI checks locally'
task ci: %i[lint test]

task default: :ci
