namespace :billing do
  desc "Bootstraps the billing system for a fresh installation of Atmosphere"
  task bootstrap: :environment do
    puts "Bootstrapping the billing system."
    if !Atmosphere::Fund.all.blank?
      puts "Funds have already been defined in this installation. Aborting."
    else
      puts "Creating a default fund for all users and all compute sites with a resource limit of 100,000,000 units..."

      f = Atmosphere::Fund.new
      f.name = "Default fund"
      f.balance = 100000000
      f.overdraft_limit = 0
      f.save

      puts "Binding to compute sites..."
      Atmosphere::ComputeSite.all.each {|cs| cs.funds << f}

      puts "Binding to users..."
      Atmosphere::User.all.each {|u| u.funds << f}

      puts "Setting default fund for each user..."
      Atmosphere::UserFund.all.each {|uf| uf.default = true; uf.save}

      puts "All done."
    end
  end
end
