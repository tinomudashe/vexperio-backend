from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch()
        context = browser.new_context(ignore_https_errors=True)
        page = context.new_page()
        
        page.on("pageerror", lambda err: print(f"PAGE ERROR: {err}"))
        page.on("console", lambda msg: print(f"LOG [{msg.type}]: {msg.text}"))
        
        page.goto("https://localhost:3001/")
        time.sleep(2)
        
        try:
            page.locator("text=Pricing").nth(0).click()
            time.sleep(2)
            print("Clicked Pricing tab")
            print(page.content())
        except Exception as e:
            print(f"Could not click: {e}")
            
        browser.close()
run()
