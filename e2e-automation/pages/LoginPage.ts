import { Page, Locator, expect } from '@playwright/test';

/**
 * Page Object Model (POM) untuk Halaman Login SIMKODES
 */
export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly headingTitle: Locator;
  readonly alertError: Locator;
  readonly directLoginBtn: Locator;

  constructor(page: Page) {
    this.page = page;
    // Enkapsulasi Selector
    this.emailInput = page.locator('input[name="email"]');
    this.passwordInput = page.locator('input[name="password"]');
    this.submitButton = page.locator('button[type="submit"]');
    this.headingTitle = page.locator('h4:has-text("Masuk ke SIMKODES")');
    this.alertError = page.locator('.alert-danger');
    this.directLoginBtn = page.locator('a:has-text("Masuk Otomatis")');
  }

  /**
   * Buka URL halaman login
   */
  async goto() {
    await this.page.goto('/login');
    await expect(this.headingTitle).toBeVisible();
  }

  /**
   * Jalankan aksi login manual via form
   */
  async login(email: string, pass: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(pass);
    await this.submitButton.click();
  }

  /**
   * Jalankan bypass login instan
   */
  async quickLogin() {
    await this.page.goto('/direct-login');
  }

  /**
   * Assertion jika login gagal
   */
  async expectLoginError() {
    await expect(this.alertError).toBeVisible();
  }
}
