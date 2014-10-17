module TimeHelper
  def time_travel(interval)
    allow(Time).to receive(:now).and_return(Time.now + interval)
  end
end