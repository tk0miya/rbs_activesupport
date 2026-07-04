# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)

task default: :ci

task ci: %i[rubocop spec steep rbs:validate]

namespace :rbs do
  desc "Install RBS signatures"
  task :install do
    sh "bundle exec rbs collection install --frozen"
  end

  desc "Generate RBS files"
  task :generate do
    sh "rbs-inline", "--opt-out", "--output=sig", "lib"
  end

  desc "Validate RBS files"
  task validate: "rbs:install" do
    sh "bundle exec rbs -Isig validate"
  end
end

desc "Run steep type check"
task steep: "rbs:install" do
  sh "bundle exec steep check"
end
