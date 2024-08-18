# frozen_string_literal: true

require "rails"

module RbsActivesupportDelegate
  class InstallGenerator < Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_activesupport_delegate.rake", <<~RUBY
        begin
          # frozen_string_literal: true

          require 'rbs_activesupport_delegate/rake_task'

          RbsActivesupportDelegate::RakeTask.new do |task|
          end
        rescue LoadError
          # failed to load rbs_activesupport_delegate. Skip to load rbs_activesupport_delegate tasks.
        end
      RUBY
    end
  end
end
