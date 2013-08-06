require "spec_helper"

describe Admin::WorkflowsController do
  describe "routing" do

    it "routes to #index" do
      get("/admin/workflows").should route_to("admin/workflows#index")
    end

    it "routes to #show" do
      get("/admin/workflows/1").should route_to("admin/workflows#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin/workflows/1/edit").should route_to("admin/workflows#edit", :id => "1")
    end

    it "routes to #update" do
      put("/admin/workflows/1").should route_to("admin/workflows#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin/workflows/1").should route_to("admin/workflows#destroy", :id => "1")
    end

  end
end
