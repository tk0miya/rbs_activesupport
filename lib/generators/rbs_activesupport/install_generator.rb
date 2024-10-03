# frozen_string_literal: true

require "rails"

module RbsActivesupport
  class InstallGenerator < Rails::Generators::Base
    def create_raketask
      create_file "lib/tasks/rbs_activesupport.rake", <<~RUBY
        # frozen_string_literal: true

        begin
          require 'rbs_activesupport/rake_task'

          RbsActivesupport::RakeTask.new do |task|
            # The target directories
            # task.target_directories = [Rails.root / "app"]
          end
        rescue LoadError
          # failed to load rbs_activesupport. Skip to load rbs_activesupport tasks.
        end
      RUBY
    end
  end
end
