require 'rails/generators/base'

module Atmosphere
  module Generators
    class ExtensionsGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../app', __FILE__)

      desc 'Copy extensions (rails concerns) which allow to extends/customize'\
           'Atmosphere behaviour.'

      def copy_ext_files
        ext_files.each { |src| template src, dest_file(src) }
      end

      private

      def ext_files
        Dir["#{app_root}/**/*_ext.rb"]
      end

      def dest_file(src_file)
        include_dirs = %r{
          (app/controllers/concerns/atmosphere/.*)|
          (app/models/concerns/atmosphere/.*)|
          (app/serializers/atmosphere/.*)
        }x

        match = include_dirs.match(src_file)
        match[0] if match
      end

      def app_root
        File.expand_path('../../../../app', __FILE__)
      end
    end
  end
end
