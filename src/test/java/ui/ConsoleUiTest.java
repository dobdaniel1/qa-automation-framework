package ui;

import static com.microsoft.playwright.assertions.PlaywrightAssertions.assertThat;

import com.microsoft.playwright.APIRequestContext;
import com.microsoft.playwright.Browser;
import com.microsoft.playwright.BrowserContext;
import com.microsoft.playwright.Page;
import com.microsoft.playwright.Playwright;
import com.microsoft.playwright.options.RequestOptions;
import java.util.regex.Pattern;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

@Tag("ui")
class ConsoleUiTest {

    private static final String BASE_URL = System.getProperty("baseUrl", "http://localhost:8000");

    private static Playwright playwright;
    private static Browser browser;
    private BrowserContext context;
    private ConsolePage console;

    @BeforeAll
    static void launch() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch();
    }

    @AfterAll
    static void close() {
        playwright.close();
    }

    @BeforeEach
    void setUp() {
        APIRequestContext api = playwright.request().newContext();
        api.post(BASE_URL + "/v1/admin/reset", RequestOptions.create());
        api.dispose();
        context = browser.newContext();
        Page page = context.newPage();
        console = new ConsolePage(page).open(BASE_URL);
    }

    @AfterEach
    void tearDown() {
        context.close();
    }

    @Test
    void approvedPurchaseAppearsInTable() {
        console.send("4111111111111111", 10000);
        assertThat(console.result()).containsText("APPROVED 00 Approved");
        assertThat(console.rows()).hasCount(1);
        assertThat(console.rows().first()).containsText("411111******1111");
        assertThat(console.rows().first()).containsText("host-a");
    }

    @Test
    void declineShowsResponseCode() {
        console.send("4111111111111111", 10051);
        assertThat(console.result()).containsText("DECLINED 51 Insufficient funds");
    }

    @Test
    void failoverVisibleWhenPrimaryIsDown() {
        console.setHost("host-a", "down").send("4111111111111111", 10000);
        assertThat(console.result()).containsText("APPROVED");
        assertThat(console.rows().first()).containsText("host-c");
    }

    @Test
    void reverseThenSettle() {
        console.send("4111111111111111", 10000);
        assertThat(console.result()).containsText("APPROVED");
        console.send("5555555555554444", 2500);
        assertThat(console.rows()).hasCount(2);

        console.rows().filter(new com.microsoft.playwright.Locator.FilterOptions().setHasText("100.00"))
            .getByTestId("reverse").click();
        assertThat(console.rows().filter(new com.microsoft.playwright.Locator.FilterOptions()
            .setHasText("REVERSED"))).hasCount(1);

        console.closeBatch();
        assertThat(console.batchResult()).hasText(Pattern.compile("Batch closed: 1 transactions, 566: net 25\\.00"));
    }
}
