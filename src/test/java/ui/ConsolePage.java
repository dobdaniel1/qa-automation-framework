package ui;

import com.microsoft.playwright.Locator;
import com.microsoft.playwright.Page;

/** Page object for the switch console. */
class ConsolePage {

    private final Page page;

    ConsolePage(Page page) {
        this.page = page;
    }

    ConsolePage open(String baseUrl) {
        page.navigate(baseUrl + "/");
        page.getByTestId("host-host-a").waitFor();
        return this;
    }

    ConsolePage send(String pan, long amount) {
        page.getByTestId("pan").fill(pan);
        page.getByTestId("amount").fill(String.valueOf(amount));
        page.getByTestId("send").click();
        return this;
    }

    ConsolePage setHost(String hostId, String status) {
        page.waitForResponse(r -> r.url().endsWith("/v1/hosts/" + hostId) && r.request().method().equals("PATCH"),
            () -> page.getByTestId("host-status-" + hostId).selectOption(status));
        return this;
    }

    Locator result() {
        return page.getByTestId("result");
    }

    Locator rows() {
        return page.getByTestId("transactions").locator("tr");
    }

    Locator batchResult() {
        return page.getByTestId("batch-result");
    }

    void closeBatch() {
        page.getByTestId("close-batch").click();
    }
}
