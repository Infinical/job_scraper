const puppeteer = require("puppeteer-extra");
const StealthPlugin = require("puppeteer-extra-plugin-stealth");
puppeteer.use(StealthPlugin());

async function scrapeLinkedIn(keyword, location) {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });
  const page = await browser.newPage();
  const jobs = [];

  try {
    // Set user agent
    await page.setUserAgent(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    );

    // First get all job IDs
    const jobIds = await scrapeJobIds(page, keyword, location);
    console.log(`Found ${jobIds.length} job IDs`);

    // Then get details for each job
    for (const jobId of jobIds) {
      const jobDetails = await scrapeJobDetails(page, jobId);
      if (jobDetails) {
        jobs.push(jobDetails);
      }
    }
  } catch (error) {
    console.error("LinkedIn scraping error:", error);
  } finally {
    await browser.close();
  }

  return jobs;
}

async function scrapeJobIds(page, keyword, location) {
  const jobIds = [];
  const encodedKeyword = encodeURIComponent(keyword);
  const encodedLocation = encodeURIComponent(location);
  const baseUrl = `https://www.linkedin.com/jobs-guest/jobs/api/seeMoreJobPostings/search?keywords=${encodedKeyword}&location=${encodedLocation}&start=`;

  try {
    let currentPage = 0;
    let hasMoreJobs = true;

    while (hasMoreJobs) {
      const url = baseUrl + currentPage * 25;
      await page.goto(url, { waitUntil: "networkidle0" });

      // Extract job IDs from the page
      const newJobIds = await page.evaluate(() => {
        const jobCards = document.querySelectorAll("li .base-card");
        return Array.from(jobCards)
          .map((card) => {
            const entityUrn = card.getAttribute("data-entity-urn");
            return entityUrn ? entityUrn.split(":")[3] : null;
          })
          .filter((id) => id);
      });

      if (newJobIds.length === 0) {
        hasMoreJobs = false;
      } else {
        jobIds.push(...newJobIds);
        currentPage++;
      }

      // Break if we've collected a reasonable number of jobs
      if (currentPage >= 5) {
        // Limit to 125 jobs (5 pages * 25 jobs)
        break;
      }
    }
  } catch (error) {
    console.error("Error scraping job IDs:", error);
  }

  return jobIds;
}

async function scrapeJobDetails(page, jobId) {
  try {
    const url = `https://www.linkedin.com/jobs-guest/jobs/api/jobPosting/${jobId}`;
    await page.goto(url, { waitUntil: "networkidle0" });

    const jobDetails = await page.evaluate(() => {
      function getCleanText(selector) {
        const element = document.querySelector(selector);
        return element ? element.textContent.trim() : null;
      }

      // Get company name
      let company = null;
      const companyImg = document.querySelector(".top-card-layout__card a img");
      if (companyImg) {
        company = companyImg.getAttribute("alt");
      }

      // Get job title
      const title = getCleanText(".top-card-layout__entity-info a");

      // Get seniority level
      let level = null;
      const criteriaList = document.querySelector(
        ".description__job-criteria-list li"
      );
      if (criteriaList) {
        level = criteriaList.textContent.replace("Seniority level", "").trim();
      }

      // Get location
      const location = getCleanText(".top-card-layout__subtitle");

      // Get description
      const description = getCleanText(".description__text");

      // Get job URL
      const url = window.location.href;

      return {
        title,
        company,
        location,
        description,
        url,
        source_platform: "LinkedIn",
      };
    });

    return jobDetails;
  } catch (error) {
    console.error(`Error scraping job details for ID ${jobId}:`, error);
    return null;
  }
}

async function scrapeIndeed(keyword, location) {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  const jobs = [];

  try {
    // Set headers to mimic real browser
    await page.setUserAgent(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
    );
    await page.setExtraHTTPHeaders({
      "Accept-Language": "en-US,en;q=0.9,lt;q=0.8,et;q=0.7,de;q=0.6",
      Accept:
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
      Connection: "keep-alive",
    });

    // Construct the URL
    const encodedKeyword = encodeURIComponent(keyword);
    const encodedLocation = encodeURIComponent(location);
    const url = `https://www.indeed.com/jobs?q=${encodedKeyword}&l=${encodedLocation}`;

    // Navigate to page and wait for job cards to load
    await page.goto(url, { waitUntil: "networkidle0" });
    await page.waitForSelector("div.mosaic-provider-jobcards", {
      timeout: 10000,
    });

    // Extract job data
    const jobListings = await page.evaluate(() => {
      const jobCards = document.querySelectorAll("li.eu4oa1w0");

      return Array.from(jobCards)
        .map((card) => {
          const getElementText = (selector, attribute = null) => {
            const element = card.querySelector(selector);
            if (!element) return null;
            return attribute
              ? element.getAttribute(attribute)
              : element.textContent.trim();
          };

          // Get job title
          const title = getElementText("a span");

          // Get company name
          const company = getElementText('span[data-testid="company-name"]');

          // Get location
          const location = getElementText('div[data-testid="text-location"]');

          // Get job details
          const details = getElementText("div.jobMetaDataGroup");

          // Get job URL
          const jobLink = card.querySelector("a");
          const url = jobLink
            ? "https://www.indeed.com" + jobLink.getAttribute("href")
            : null;

          return {
            title,
            company,
            location,
            description: details, // We'll get full description when we visit the job page
            url,
            source_platform: "Indeed",
          };
        })
        .filter((job) => job.title && job.company); // Filter out incomplete listings
    });

    // Get detailed description for each job
    for (const job of jobListings) {
      if (job.url) {
        await page.goto(job.url, { waitUntil: "networkidle0" });
        await page
          .waitForSelector("#jobDescriptionText", { timeout: 5000 })
          .catch(() => null);

        const fullDescription = await page.evaluate(() => {
          const descElement = document.querySelector("#jobDescriptionText");
          return descElement ? descElement.textContent.trim() : null;
        });

        if (fullDescription) {
          job.description = fullDescription;
          jobs.push(job);
        }
      }
    }
  } catch (error) {
    console.error("Indeed scraping error:", error);
  } finally {
    await browser.close();
  }

  return jobs;
}

module.exports = { scrapeLinkedIn, scrapeIndeed };
