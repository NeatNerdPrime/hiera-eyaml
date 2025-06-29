require 'base64'
require 'yaml'
# require 'hiera/backend/eyaml/subcommands/unknown_command'

class Hiera
  module Backend
    module Eyaml
      class Subcommand
        class << self
          attr_accessor :global_options, :options, :helptext
        end

        @@global_options = [
          { name: :encrypt_method,
            description: 'Override default encryption and decryption method (default is PKCS7)',
            short: 'n',
            default: 'pkcs7', },
          { name: :version,
            description: 'Show version information', },
          { name: :verbose,
            description: 'Be more verbose',
            short: 'v', },
          { name: :trace,
            description: 'Enable trace debug',
            short: 't', },
          { name: :quiet,
            description: 'Be less verbose',
            short: 'q', },
          { name: :help,
            description: 'Information on how to use this command',
            short: 'h', },
        ]

        def self.load_config_file
          config = { options: {}, sources: [] }

          config_paths = []
          # Global
          config_paths += ['/etc/eyaml/config.yaml']
          # Home directory
          env_home = ENV.fetch('HOME', nil)
          config_paths += ["#{env_home}/.eyaml/config.yaml"] if env_home
          # Relative to current directory
          config_paths += ['.eyaml/config.yaml']
          # Explicit ENV variable.
          env_eyaml_config = ENV.fetch('EYAML_CONFIG', nil)
          config_paths += [env_eyaml_config] if env_eyaml_config

          # Load each path and stack configs.
          config_paths.each do |config_file|
            next unless config_file and File.file? config_file

            begin
              yaml_contents = YAML.load_file(config_file)
              config[:options].merge! yaml_contents
              config[:sources].push(config_file)
            rescue StandardError
              raise StandardError, "Could not open config file \"#{config_file}\" for reading"
            end
          end
          config
        end

        def self.all_options
          options = @@global_options.dup
          options += self.options if self.options
          options += Plugins.options
          # merge in defaults from configuration files
          config_file = load_config_file
          options.map!  do |opt|
            key_name = "#{opt[:name]}"
            if config_file[:options].has_key? key_name
              opt[:default] = config_file[:options][key_name]
              opt
            else
              opt
            end
          end
          { options: options, sources: config_file[:sources] || [] }
        end

        def self.attach_option(opt)
          self.suboptions += opt
        end

        def self.find(commandname = 'unknown_command')
          begin
            require "hiera/backend/eyaml/subcommands/#{commandname.downcase}"
          rescue Exception
            require 'hiera/backend/eyaml/subcommands/unknown_command'
            return Hiera::Backend::Eyaml::Subcommands::UnknownCommand
          end
          command_module = Module.const_get(:Hiera).const_get(:Backend).const_get(:Eyaml).const_get(:Subcommands)
          command_class = Utils.find_closest_class parent_class: command_module, class_name: commandname
          command_class || Hiera::Backend::Eyaml::Subcommands::UnknownCommand
        end

        def self.parse
          me = self
          all = all_options

          options = Optimist.options do
            version 'Hiera-eyaml version ' + Hiera::Backend::Eyaml::VERSION.to_s
            banner ["eyaml #{me.prettyname}: #{me.description}", me.helptext, 'Options:'].compact.join("\n\n")

            all[:options].each do |available_option|
              skeleton = { description: '',
                           short: :none, }

              skeleton.merge! available_option
              opt skeleton[:name],
                  skeleton[:desc] || skeleton[:description], # legacy plugins
                  short: skeleton[:short],
                  default: skeleton[:default],
                  type: skeleton[:type]
            end

            stop_on Eyaml.subcommands
          end

          Hiera::Backend::Eyaml.verbosity_level += 1 if options[:verbose]

          Hiera::Backend::Eyaml.verbosity_level += 2 if options[:trace]

          Hiera::Backend::Eyaml.verbosity_level = 0 if options[:quiet]

          Hiera::Backend::Eyaml.default_encryption_scheme = options[:encrypt_method] if options[:encrypt_method]

          if all[:sources]
            all[:sources].each do |source|
              LoggingHelper.debug "Loaded config from #{source}"
            end
          end

          options
        end

        def self.print_out(string)
          print string
        end

        def self.validate(args)
          args
        end

        def self.description
          'no description'
        end

        def self.helptext
          "Usage: eyaml #{prettyname} [options]"
        end

        def self.execute
          raise StandardError, "This command is not implemented yet (#{to_s.split('::').last})"
        end

        def self.prettyname
          Utils.snakecase to_s.split('::').last
        end

        def self.hidden?
          false
        end
      end
    end
  end
end
