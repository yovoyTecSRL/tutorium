import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const DIST_DIR = './dist';

// Get all HTML files in dist directory
function getHtmlFiles() {
  if (!fs.existsSync(DIST_DIR)) {
    return [];
  }
  return fs.readdirSync(DIST_DIR)
    .filter(file => file.endsWith('.html'))
    .map(file => ({ filename: file, path: `/${file}` }));
}

test.describe('HTML Structure Validation', () => {
  const htmlFiles = getHtmlFiles();

  if (htmlFiles.length === 0) {
    test('dist directory should contain HTML files', async () => {
      expect(htmlFiles.length).toBeGreaterThan(0);
    });
    return;
  }

  htmlFiles.forEach(({ filename, path: filePath }) => {
    test(`${filename} should have valid HTML structure`, async ({ page }) => {
      await page.goto(filePath);
      
      // Check for single footer
      const footerCount = await page.locator('footer').count();
      expect(footerCount).toBe(1);
      
      // Check for content after </body>
      const htmlContent = await page.evaluate(() => document.documentElement.outerHTML);
      const bodyCloseIndex = htmlContent.lastIndexOf('</body>');
      const htmlCloseIndex = htmlContent.lastIndexOf('</html>');
      
      if (bodyCloseIndex !== -1 && htmlCloseIndex !== -1) {
        const contentAfterBody = htmlContent.slice(bodyCloseIndex + 7, htmlCloseIndex).trim();
        expect(contentAfterBody).toBe('');
      }
      
      // Check page loads without errors
      await expect(page).toHaveTitle(/Tutorium/);
    });
  });
});

test.describe('Smoke Tests', () => {
  test('index.html loads correctly', async ({ page }) => {
    await page.goto('/index-with-includes.html');
    
    // Check title
    await expect(page).toHaveTitle(/Tutorium/);
    
    // Check main navigation exists
    const nav = page.locator('nav');
    await expect(nav).toBeVisible();
    
    // Check hero section
    const hero = page.locator('main section').first();
    await expect(hero).toBeVisible();
    
    // Check footer
    const footer = page.locator('footer');
    await expect(footer).toBeVisible();
    
    // No console errors
    const errors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    await page.waitForLoadState('networkidle');
    expect(errors).toEqual([]);
  });

  test('profedeingles.html loads correctly', async ({ page }) => {
    await page.goto('/profedeingles-with-includes.html');
    
    // Check title
    await expect(page).toHaveTitle(/Profe de Inglés/);
    
    // Check main content
    const heading = page.locator('h1');
    await expect(heading).toContainText('Profe de Inglés');
    
    // Check footer
    const footer = page.locator('footer');
    await expect(footer).toBeVisible();
  });
});

test.describe('Performance Tests', () => {
  test('pages load within acceptable time', async ({ page }) => {
    const startTime = Date.now();
    await page.goto('/index-with-includes.html');
    await page.waitForLoadState('networkidle');
    const loadTime = Date.now() - startTime;
    
    // Should load within 3 seconds
    expect(loadTime).toBeLessThan(3000);
  });
});
