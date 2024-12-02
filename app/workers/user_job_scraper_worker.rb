class UserJobScraperWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, queue: "scrapers"

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Get all unique keywords and locations from user's preferences
    keywords = user.job_preferences.pluck(:keywords).flatten.uniq
    locations = user.job_preferences.pluck(:locations).flatten.uniq

    result = JobScraperService.new(
      user: user,
      keywords: keywords,
      locations: locations
    ).execute

    # Log the results
    logger.info("Job scraping completed for user #{user.id}: #{result}")
  end
end
