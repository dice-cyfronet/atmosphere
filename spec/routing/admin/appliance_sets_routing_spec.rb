require "spec_helper"

describe Admin::ApplianceSetsController do
  describe "routing" do

    it "routes to #index" do
      get("/admin/appliance_sets").should route_to("admin/appliance_sets#index")
    end

    it "routes to #show" do
      get("/admin/appliance_sets/1").should route_to("admin/appliance_sets#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin/appliance_sets/1/edit").should route_to("admin/appliance_sets#edit", :id => "1")
    end

    it "routes to #update" do
      put("/admin/appliance_sets/1").should route_to("admin/appliance_sets#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin/appliance_sets/1").should route_to("admin/appliance_sets#destroy", :id => "1")
    end

  end
end
