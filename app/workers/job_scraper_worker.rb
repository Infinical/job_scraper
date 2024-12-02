class JobScraperWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, queue: "scrapers"

  def perform
    User.find_each do |user|
      # Skip users without job preferences
      next if user.job_preferences.empty?

      # Create individual scraping job for each user
      UserJobScraperWorker.perform_async(user.id)
    end
  end
end
