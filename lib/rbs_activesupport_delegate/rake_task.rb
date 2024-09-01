# frozen_string_literal: true

require "pathname"
require "rake/tasklib"

module RbsActivesupportDelegate
  class RakeTask < Rake::TaskLib
    attr_accessor :name, :signature_root_dir

    def initialize(name = :'rbs:activesupport_delegate', &block)
      super()

      @name = name
      @signature_root_dir = Pathname(Rails.root / "sig/activesupport/delegate")

      block&.call(self)

      define_clean_task
      define_generate_task
      define_setup_task
    end

    def define_setup_task
      desc "Run all tasks of rbs_activesupport_delegate"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task
      desc "Generate RBS files for activesupport gem (delegate)"
      task("#{name}:generate": :environment) do
        require "rbs_activesupport_delegate" # load RbsActivesupportDelegate lazily

        Rails.application.eager_load!

        signature_root_dir.mkpath

        (Rails.root / "app").glob("**/*.rb").each do |file|
          rbs = Generator.new(file, rbs_builder).generate
          next unless rbs

          rbs_path = signature_root_dir / file.sub_ext(".rbs").relative_path_from(Rails.root)
          rbs_path.dirname.mkpath
          rbs_path.write(rbs)
        end
      end
    end

    def define_clean_task
      desc "Clean RBS files for config gem"
      task "#{name}:clean" do
        signature_root_dir.rmtree if signature_root_dir.exist?
      end
    end

    private

    def rbs_builder
      @rbs_builder ||= begin
        loader = RBS::CLI::LibraryOptions.new.loader
        loader.add(path: Pathname("sig"))
        env = RBS::Environment.from_loader(loader).resolve_type_names
        RBS::DefinitionBuilder.new(env: env)
      end
    end
  end
end
