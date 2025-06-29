require 'tempfile'
require 'fileutils'
require 'hiera/backend/eyaml/logginghelper'

class Hiera
  module Backend
    module Eyaml
      class Utils
        def self.camelcase(string)
          return string if string !~ /_/ && string =~ /[A-Z]+.*/

          string.split('_').map { |e| e.capitalize }.join
        end

        def self.snakecase(string)
          return string unless /[A-Z]/.match?(string)

          string.split(/(?=[A-Z])/).collect { |x| x.downcase }.join('_')
        end

        def self.find_closest_class(args)
          parent_class = args[:parent_class]
          class_name = args[:class_name]
          constants = parent_class.constants
          candidates = []
          constants.each do |candidate|
            candidates << candidate.to_s if candidate.to_s.downcase == class_name.downcase
          end
          return unless candidates.count > 0

          parent_class.const_get candidates.first
        end

        def self.require_dir(classdir)
          num_class_hierarchy_levels = to_s.split('::').count - 1
          root_folder = File.dirname(__FILE__) + '/' + Array.new(num_class_hierarchy_levels).fill('..').join('/')
          class_folder = root_folder + '/' + classdir
          Dir[File.expand_path("#{class_folder}/*.rb")].uniq.each do |file|
            LoggingHelper.trace "Requiring file: #{file}"
            require file
          end
        end

        def self.find_all_subclasses_of(args)
          parent_class = args[:parent_class]
          constants = parent_class.constants
          candidates = []
          constants.each do |candidate|
            candidates << candidate.to_s.split('::').last if parent_class.const_get(candidate).instance_of?(::Class)
          end
          candidates
        end

        def self.hiera?
          'hiera'.eql? Eyaml::Options[:source]
        end

        def self.convert_to_utf_8(string)
          orig_encoding = string.encoding
          return string if orig_encoding == Encoding::UTF_8

          string.dup.force_encoding(Encoding::UTF_8)
        rescue EncodingError
          warn "Unable to encode to \"Encoding::UTF_8\" using the original \"#{orig_encoding}\""
          string
        end
      end
    end
  end
end
