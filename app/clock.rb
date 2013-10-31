# require 'config/boot'
# require 'config/environment'

require_relative "../config/boot"
require_relative "../config/environment"

module Clockwork
  every(5.seconds, 'proxyconf.regenerate') do
    ProxyConfWorker.regenerate_proxy_confs
  end
end