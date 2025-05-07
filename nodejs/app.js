import puppeteer from "puppeteer";


const connect = async () => {
    try {
        const browser = await puppeteer.launch({ headless: "new" });

        const page = await browser.newPage();

        await page.goto("https://login.kku.ac.th");

        await page.setViewport({width: 720, height: 1280});

        await page.type("#username", "Student-ID");

        await page.type("#password", "password");

        await page.$eval("button.btn.btn-info", (form) => form.click());
        await page.waitForNavigation();

        console.log("✅ Logged In.");

        await browser.close();
    } catch (e) {
       console.log("🛑 You already logged in.")
    }
}

connect()