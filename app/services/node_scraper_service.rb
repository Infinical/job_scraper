class NodeScraperService
  def scrape_linkedin(keyword, location)
    execute_scraper("linkedin", keyword, location)
  end

  def scrape_indeed(keyword, location)
    execute_scraper("indeed", keyword, location)
  end

  private

  def execute_scraper(source, keyword, location)
    script_path = Rails.root.join("lib", "services", "scraper", "scraper.js")

    # Create a temporary JS file to handle the async execution
    temp_script = Rails.root.join("tmp", "temp_scraper.js")
    File.write(temp_script, <<~JAVASCRIPT)
      const scraper = require('#{script_path}');

      async function runScraper() {
        try {
          const results = await scraper.scrape#{source.capitalize}('#{keyword}', '#{location}');
          console.log(JSON.stringify(results));
        } catch (error) {
          console.error(error);
          process.exit(1);
        }
      }

      runScraper();
    JAVASCRIPT

    # Execute the temporary script
    result = `node #{temp_script}`

    # Clean up
    File.delete(temp_script) if File.exist?(temp_script)

    JSON.parse(result)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse scraper results: #{e.message}")
    []
  rescue StandardError => e
    Rails.logger.error("Scraper execution failed: #{e.message}")
    []
  end
end
