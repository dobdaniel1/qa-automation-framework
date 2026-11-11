package switchapi;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

@Tag("api")
class SwitchApiTest {

    @Test
    void karateSuite() {
        // Single thread: scenarios reset and reconfigure the shared switch.
        Results results = Runner.path("classpath:switchapi")
            .tags("~@ignore")
            .outputJunitXml(true)
            .parallel(1);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
