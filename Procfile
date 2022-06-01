###############################
#         DEVELOPMENT         #
###############################

# Procfile for development using the new threaded worker (scheduler, twitter stream and delayed job)
web: bundle exec rails server -p 3000 -b 0.0.0.0
jobs: bundle exec rails runner bin/threaded.rb


