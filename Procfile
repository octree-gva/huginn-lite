###############################
#         DEVELOPMENT         #
###############################

# Procfile for development using the new threaded worker (scheduler, twitter stream and delayed job)
web: bundle exec rails server -p ${PORT-3000} -b ${IP-0.0.0.0}
jobs: bundle exec rails runner bin/threaded.rb
dj2: bundle exec script/delayed_job -i 2 run


