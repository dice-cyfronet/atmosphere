require 'rails_helper'

describe Atmosphere::Admin::ApplianceSetsController do
  routes { Atmosphere::Engine.routes }

  describe 'routing' do

    it 'routes to #index' do
      expect(get: '/admin/appliance_sets')
        .to route_to('atmosphere/admin/appliance_sets#index')
    end

    it 'routes to #show' do
      expect(get: '/admin/appliance_sets/1')
        .to route_to('atmosphere/admin/appliance_sets#show', :id => '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/appliance_sets/1/edit')
        .to route_to('atmosphere/admin/appliance_sets#edit', :id => '1')
    end

    it 'routes to #update' do
      expect(put: '/admin/appliance_sets/1')
        .to route_to('atmosphere/admin/appliance_sets#update', :id => '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/appliance_sets/1')
        .to route_to('atmosphere/admin/appliance_sets#destroy', :id => '1')
    end
  end
end
