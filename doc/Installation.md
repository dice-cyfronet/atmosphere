## After update run the following:
* `run: bundle install`
* `RAILS_ENV=development bundle exec rake db:drop db:create db:migrate`
* `bundle exec rake db:seed`
* `bundle exec rake db:migrate`