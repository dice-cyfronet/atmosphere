require 'rails_helper'

describe Atmosphere::Action do
  include ApiHelpers

  let(:optimizer) { double('optimizer') }

  before do
    expect(Atmosphere::Optimizer).
        to receive(:instance).
               at_least(:once) { optimizer }

    expect(optimizer).to receive(:run).at_least(:once).with(anything)

  end

  let(:appl) { create(:appliance) }
  subject {  Atmosphere::Action.create(appliance: appl) }

  it 'checks logging' do

    message = 'log message'
    subject.log(message)

    expect(Atmosphere::ActionLog.count).to eq 1
    expect(Atmosphere::ActionLog.first.message).to eq message
    expect(Atmosphere::ActionLog.first.action).to eq subject
    expect(Atmosphere::ActionLog.first.log_level).to eq 'info'

  end

  it 'checks logging at error level' do

    message = 'error message'
    subject.error(message)

    expect(Atmosphere::ActionLog.first.message).to eq message
    expect(Atmosphere::ActionLog.first.log_level).to eq 'error'

  end

  it 'checks logging at warn level' do

    message = 'warn message'
    subject.warn(message)

    expect(Atmosphere::ActionLog.first.message).to eq message
    expect(Atmosphere::ActionLog.first.log_level).to eq 'warn'

  end


end
