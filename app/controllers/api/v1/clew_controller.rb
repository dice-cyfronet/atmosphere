module Api
  module V1
    class ClewController < Api::ApplicationController

      load_and_authorize_resource :appliance_set, :class => "ApplianceSet", :parent => false

      #skip_authorization_check
      respond_to :json

      def appliances
        #ApplianceSet.all.each { |x| puts "#{x.user}" }
        puts "First: #{@appliance_sets.first}"
        puts "Count #{@appliance_sets.count}"
        render json: {appliance_sets: @appliance_sets}, serializer: ClewSerializer
      end

    end
  end
end
