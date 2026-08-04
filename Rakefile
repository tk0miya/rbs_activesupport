# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new(:spec)

task default: :ci

task ci: %i[rubocop spec steep rbs:validate]

namespace :rbs do
  # sig/gems holds hand-written types for external gems, so it is never regenerated
  kept = ->(path) { path == "sig/gems" || path.start_with?("sig/gems/") }

  desc "Install RBS collection"
  task :install do
    sh "bundle exec rbs collection install --frozen"
  end

  desc "Regenerate all RBS files under sig/ from scratch (run manually after editing lib/)"
  task :regenerate do
    Dir.glob("sig/**/*.rbs").reject(&kept).each { rm _1 }

    sh "bundle exec rbs-inline --opt-out --output=sig lib"

    # Drop the directories the deletion above left empty, deepest first
    dirs = Dir.glob("sig/**/*").select { File.directory?(_1) }
    dirs.reject(&kept).sort.reverse_each { rmdir _1 if Dir.empty?(_1) }
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
