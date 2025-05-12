# frozen_string_literal: true

require "pathname"
require "rake/tasklib"

module RbsActivesupport
  class RakeTask < Rake::TaskLib
    attr_accessor :name #: Symbol
    attr_accessor :signature_root_dir #: Pathname
    attr_accessor :target_directories #: Array[Pathname]

    # @rbs @rbs_builder: RBS::DefinitionBuilder

    # @rbs name: Symbol
    # @rbs &block: ?(self) -> void
    def initialize(name = :'rbs:activesupport', &block) #: void
      super()

      @name = name
      @signature_root_dir = Pathname(Rails.root / "sig/activesupport")
      @target_directories = [Rails.root / "app"]

      block&.call(self)

      define_clean_task
      define_generate_task
      define_setup_task
    end

    def define_setup_task #: void
      desc "Run all tasks of rbs_activesupport"

      deps = [:"#{name}:clean", :"#{name}:generate"]
      task("#{name}:setup" => deps)
    end

    def define_generate_task #: void
      desc "Generate RBS files for activesupport gem"
      task("#{name}:generate": :environment) do
        require "rbs_activesupport" # load RbsActivesupport lazily

        Rails.application.eager_load!

        signature_root_dir.mkpath

        target_directories.each do |dir|
          dir.glob("**/*.rb").each do |file|
            rbs = Generator.generate(file, rbs_builder)
            next unless rbs

            rbs_path = signature_root_dir / file.sub_ext(".rbs").relative_path_from(Rails.root)
            rbs_path.dirname.mkpath
            rbs_path.write(rbs)
          end
        end
      end
    end

    def define_clean_task #: void
      desc "Clean RBS files for config gem"
      task "#{name}:clean" do
        signature_root_dir.rmtree if signature_root_dir.exist?
      end
    end

    private

    def rbs_builder #: RBS::DefinitionBuilder
      @rbs_builder ||= begin
        loader = RBS::CLI::LibraryOptions.new.loader
        loader.add(path: Pathname("sig"))
        env = RBS::Environment.from_loader(loader).resolve_type_names
        RBS::DefinitionBuilder.new(env:)
      end
    end
  end
end
