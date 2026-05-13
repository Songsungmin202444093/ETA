const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1200, height: 1200 });
  await page.goto('file:///C:/Users/sungmin/Desktop/BusETA/docs/api_data_flow.html');
  await page.waitForTimeout(800);
  const svg = await page.$('svg');
  await svg.screenshot({ path: 'C:/Users/sungmin/Desktop/BusETA/docs/api_data_flow_svg.png' });
  await browser.close();
  console.log('done');
})();
