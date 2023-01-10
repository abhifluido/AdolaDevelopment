/**
 * Created by bartubazna on 5.12.2022.
 */

@IsTest
private class TestKiwiUtils {
    @IsTest
    static void testReplaceNullVal() {
        String nullString = null;
        String res = KiwiUtils.replaceNullVal(nullString);
        System.assertEquals('', res);
    }

    @IsTest
    static void testPrepareResponseWithString() {
        String testSuccess = 'Test success';
        String testFail = 'Test fail';
        Map<String, Object> resSuccess = KiwiUtils.prepareResponseWithString(testSuccess, false);
        Map<String, Object> resFail = KiwiUtils.prepareResponseWithString(testFail, true);
        System.assertEquals(true, resSuccess.get('success'));
        System.assertEquals(testSuccess, resSuccess.get('message'));
        System.assertEquals(false, resFail.get('success'));
        System.assertEquals(testFail, resFail.get('message'));
    }

    @IsTest
    static void testPrepareResponseWithMap() {
        Map<String, Object> testSuccess = new Map<String, Object>{'test' => 'success'};
        Map<String, Object> testFail = new Map<String, Object>{'test' => 'fail'};
        Map<String, Object> resSuccess = KiwiUtils.prepareResponseWithMap(testSuccess, false);
        Map<String, Object> resFail = KiwiUtils.prepareResponseWithMap(testFail, true);
        System.assertEquals(true, resSuccess.get('success'));
        System.assertEquals(testSuccess, resSuccess.get('message'));
        System.assertEquals(false, resFail.get('success'));
        System.assertEquals(testFail, resFail.get('message'));
    }

    @IsTest
    static void testIsTestRunning() {
        List<Boolean> res = KiwiUtils.isTestRunning();
        System.assertEquals(true, res[0]);
    }
}