class NodeScraperService
  def scrape_linkedin(keyword, location)
    execute_scraper('linkedin', keyword, location)
  end

  def scrape_indeed(keyword, location)
    execute_scraper('indeed', keyword, location)
  end

  private

  def execute_scraper(source, keyword, location)
    script_path = Rails.root.join('lib', 'services', 'scraper', 'scraper.js')
    result = `node -e "
      const scraper = require('#{script_path}');
      scraper.scrape#{source.capitalize}('#{keyword}', '#{location}')
        .then(results => console.log(JSON.stringify(results)))
        .catch(error => console.error(error));
    "`
    
    JSON.parse(result)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse scraper results: #{e.message}")
    []
  end
end