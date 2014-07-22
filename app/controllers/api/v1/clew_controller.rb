module Api
  module V1
    class ClewController < Api::ApplicationController

      load_resource :appliance_set, :class => "ApplianceSet"

      skip_authorization_check
      respond_to :json

      def appliances
        object = Hash.new
        object[:appliances] = "abc"
        ApplianceSet.all.each { |x| puts "#{x.user}" }
        puts "#{@appliance_sets.first}"
        puts "#{@appliance_sets.count}"
        render json: object, serializer: ClewSerializer
      end

    end
  end
end
