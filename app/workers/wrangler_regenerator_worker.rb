require 'wrangler'

class WranglerRegeneratorWorker
  include Sidekiq::Worker
  include Wrangler

  sidekiq_options queue: :wrangler

  def perform(vm_id)
    eraser = WranglerEraserWorker.new
    registrar = WranglerRegistrarWorker.new
    eraser.perform(vm_id)
    registrar.perform(vm_id)
  end

end