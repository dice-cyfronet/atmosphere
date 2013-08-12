module API
  class ApplianceSets < Grape::API
    before { authenticate! }

    resource :appliance_sets do
      get do
        {msg: 'TODO: implemt this action'}
      end
    end
  end
end