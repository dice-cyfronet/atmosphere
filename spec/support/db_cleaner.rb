require 'database_cleaner'

RSpec.configure do |config|
  config.before do
    unless example.metadata[:no_db]
      DatabaseCleaner.start
    end
  end

  config.after do
    unless example.metadata[:no_db]
      DatabaseCleaner.clean
    end
  end
end
