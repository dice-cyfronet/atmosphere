require 'spec_helper'

describe WranglerRegeneratorWorker do

  it 'creates and calls eraser and registrar workers' do

    vm = create(:virtual_machine, ip: '10.100.4.6')
    registrar = double('registrar')
    eraser = double('eraser')
    WranglerRegistrarWorker.stub(:new).and_return(registrar)
    WranglerEraserWorker.stub(:new).and_return(eraser)
    expect(registrar).to receive(:perform).with(vm.id)
    expect(eraser).to receive(:perform).with(vm.id)
    subject.perform(vm.id)

  end

end