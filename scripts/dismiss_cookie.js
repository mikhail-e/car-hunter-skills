async (page) => {
  try {
    // Попытка 1: кнопка прямо на странице (основной вариант mobile.de)
    const btn = await page.waitForSelector('button:has-text("Einverstanden")', { timeout: 5000 });
    if (btn) await btn.click();
  } catch(e1) {
    try {
      // Попытка 2: внутри iframe (запасной вариант)
      const frame = await page.waitForSelector('iframe[id*="sp_message_iframe"]', { timeout: 3000 });
      if (frame) {
        const f = await frame.contentFrame();
        const btn2 = await f.waitForSelector('button:has-text("Einverstanden")', { timeout: 3000 });
        if (btn2) await btn2.click();
      }
    } catch(e2) { /* баннер не найден — ОК */ }
  }
  await page.waitForTimeout(1000);
}
