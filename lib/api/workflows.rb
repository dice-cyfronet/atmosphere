module API
  class Workflows < Grape::API
    before { authenticate! }

    resource :workflows do
      get do
        {msg: 'TODO: implemt this action'}
      end
    end
  end
end