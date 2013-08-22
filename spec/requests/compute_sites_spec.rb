require 'spec_helper'

describe "ComputeSites" do
  describe "GET /compute_sites" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get compute_sites_path
      expect(response.status).to be(200)
    end
  end
end
