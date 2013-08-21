require 'fog'

aws=Fog::Compute.new(:provider => 'AWS', :aws_access_key_id => 'AKIAIGV5YG57GDWD2OAQ', :aws_secret_access_key =>'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', :region => 'eu-west-1')
server = aws.servers.create(:image_id => 'ami-ce7b6fba', :name => 'fog-test', :flavour_id => 1, :key_name => 'vph_masterkey', :user_data => 'tomek 123')
server.destroy