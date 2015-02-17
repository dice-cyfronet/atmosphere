require 'rails/generators/base'

module Atmosphere
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)

      desc 'Creates an Atmosphere initializer and copy locale files to'\
           ' your application.'

      def copy_initializer
        template 'atmosphere.rb', 'config/initializers/atmosphere.rb'
      end

      def set_up_clockwork
        template 'clock.rb', 'app/clock.rb'
      end

      def add_routes
        route 'mount Atmosphere::Engine => "/"'
      end

      def copy_migrations
        rake 'atmosphere:install:migrations'
      end

      def show_readme
        readme 'README' if behavior == :invoke
      end
    end
  end
end
