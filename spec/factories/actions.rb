FactoryGirl.define do
  factory :action, class: 'Atmosphere::Action' do

    appliance

    action_logs { [create(:action_log)] }

  end

end
