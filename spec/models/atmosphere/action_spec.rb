require 'rails_helper'

describe Atmosphere::Action do
  let(:appl) { create(:appliance) }
  subject { Atmosphere::Action.create(appliance: appl) }

  it 'creates info log' do
    message = 'log message'
    subject.log(message)

    expect(Atmosphere::ActionLog.count).to eq 1
    first_log = Atmosphere::ActionLog.first
    expect(first_log.message).to eq message
    expect(first_log.action).to eq subject
    expect(first_log.log_level).to eq 'info'
  end

  it 'creates error log' do
    message = 'error message'

    subject.error(message)
    first_log = Atmosphere::ActionLog.first

    expect(first_log.message).to eq message
    expect(first_log.log_level).to eq 'error'
  end

  it 'creates warn log' do
    message = 'warn message'

    subject.warn(message)
    first_log = Atmosphere::ActionLog.first

    expect(first_log.message).to eq message
    expect(first_log.log_level).to eq 'warn'
  end
end
