require 'optimist'
require 'hiera/backend/eyaml'
require 'hiera/backend/eyaml/logginghelper'
require 'hiera/backend/eyaml/utils'
require 'hiera/backend/eyaml/plugins'
require 'hiera/backend/eyaml/options'
require 'hiera/backend/eyaml/subcommand'

class Hiera
  module Backend
    module Eyaml
      class CLI
        def self.parse
          Utils.require_dir 'hiera/backend/eyaml/subcommands'
          Eyaml.subcommands = Utils.find_all_subclasses_of({ parent_class: Hiera::Backend::Eyaml::Subcommands }).collect do |classname|
            Utils.snakecase classname
          end

          Eyaml.subcommand = ARGV.shift
          subcommand = case Eyaml.subcommand
                       when nil
                         ARGV.delete_if { true }
                         'unknown_command'
                       when /^-/
                         ARGV.delete_if { true }
                         'help'
                       else
                         Eyaml.subcommand
                       end

          command_class = Subcommand.find subcommand

          options = command_class.parse
          options[:executor] = command_class

          options = command_class.validate options
          Eyaml::Options.set options
          Eyaml::Options.trace
        end

        def self.execute
          executor = Eyaml::Options[:executor]

          result = executor.execute
          executor.print_out(result) unless result.nil?
        end
      end
    end
  end
end
