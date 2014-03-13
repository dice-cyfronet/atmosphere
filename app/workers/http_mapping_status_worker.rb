class HttpMappingStatusWorker

  include Sidekiq::Worker

  @@spec = {}
  @@data = {}

  @@count = 0

  def perform(id, spec = nil)
    update_only = controll(id, spec)
    unless (disabled(id) || update_only)
      execute(id)
      HttpMappingStatusWorker.perform_in(interval(id), id)
    end
  end

  private

  def execute(id)
    @@data[id][:counter] ||= 0
    @@data[id][:counter] = @@data[id][:counter] +1
    puts "checking #{@@spec[id][:url]} #{@@data[id][:counter]} time"
  end

  def controll(id, spec)
    unless spec.nil?
      if spec.is_a? Hash
        update_only = true unless @@spec[id].nil?
        unless update_only
          puts "starting #{id}"
        else
          puts "updating #{id}"
        end
        @@spec[id] = spec
        @@spec[id][:url] = spec["url"]
        @@spec[id][:interval] = spec["interval"] || 2.seconds
        @@data[id] = {} unless update_only
      elsif spec == false
        puts "stopping #{id}"
        @@spec[id] = nil
        @@data[id] = nil
      end
    end
    update_only
  end

  def disabled(id)
    @@spec[id].nil?
  end

  def interval(id)
    @@spec[id][:interval]
  end

#  def do sth
#
    #puts "checking #{url}"
    #
    #begin
    #  response = Faraday.get do |req|
    #    req.url url
    #    req.options.timeout = 10
    #    req.options.open_timeout = 10
    #  end
    #  puts "status #{response.status}"
    #rescue
    #  puts "status check error"
    #end
#  end



end