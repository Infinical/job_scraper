class JobScraperService
  class ScrapingError < StandardError; end

  def initialize(user:, keywords: [], locations: [])
    @user = user
    @keywords = keywords
    @locations = locations
    @successful_jobs = 0
    @failed_jobs = 0
    @new_jobs_count = 0
  end

  def execute
    scrape_linkedin
    scrape_indeed

    # Notify user about new job postings if any
    # notify_user if @new_jobs_count > 0

    {
      status: "completed",
      user_id: @user.id,
      successful_jobs: @successful_jobs,
      failed_jobs: @failed_jobs,
      new_jobs_count: @new_jobs_count
    }
  rescue => e
    Rails.logger.error("Job scraping failed for user #{@user.id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    {
      status: "failed",
      user_id: @user.id,
      error: e.message,
      successful_jobs: @successful_jobs,
      failed_jobs: @failed_jobs,
      new_jobs_count: @new_jobs_count
    }
  end

  private

  def scrape_linkedin
    @keywords.each do |keyword|
      @locations.each do |location|
        scrape_linkedin_jobs(keyword, location)
      end
    end
  end

  def scrape_indeed
    @keywords.each do |keyword|
      @locations.each do |location|
        scrape_indeed_jobs(keyword, location)
      end
    end
  end

  def scrape_linkedin_jobs(keyword, location)
    result = NodeScraperService.new.scrape_linkedin(keyword, location)
    process_scraped_jobs(result, "LinkedIn")
  end

  def scrape_indeed_jobs(keyword, location)
    result = NodeScraperService.new.scrape_indeed(keyword, location)
    process_scraped_jobs(result, "Indeed")
  end

  def process_scraped_jobs(jobs, source)
    jobs.each do |job_data|
      begin
        # Try to find existing job posting first
        job_posting = JobPosting.find_by(source_url: job_data["url"])

        if job_posting.nil?
          JobPosting.create!(
            title: job_data["title"],
            company: job_data["company"],
            location: job_data["location"],
            description: job_data["description"],
            source_url: job_data["url"],
            source_platform: job_data["source"]
          )
          @new_jobs_count += 1
        end

        @successful_jobs += 1
      rescue ActiveRecord::RecordInvalid => e
        @failed_jobs += 1
        Rails.logger.error("Failed to create job posting from #{source} for user #{@user.id}: #{e.message}")
      end
    end
  end

  # def notify_user
  #   # Create a notification for the user
  #   UserNotifier.new_jobs_notification(
  #     user: @user,
  #     new_jobs_count: @new_jobs_count
  #   ).deliver_later
  # end
end
