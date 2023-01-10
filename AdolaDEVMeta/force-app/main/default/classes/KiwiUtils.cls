/**
 * Created by bartubazna on 4.11.2022.
 */

public with sharing class KiwiUtils {

    @InvocableMethod(Label='Checks if flow is running in test' Description='runs Test.isRunningTest() method to check if the flow is running in test. Returns boolean.')
    public static List<Boolean> isTestRunning() {
        return new List<Boolean>{Test.isRunningTest()};
    }

    public static Map<String,Object> prepareResponseWithString(String message, Boolean isError) {
        Map<String,Object> response = new Map<String,Object>();
        if (isError) {
            response.put('success', false);
        } else {
            response.put('success', true);
        }
        response.put('message', message);
        return response;
    }

    public static Map<String,Object> prepareResponseWithMap(Map<String,Object> message, Boolean isError) {
        Map<String,Object> response = new Map<String,Object>();
        if (isError) {
            response.put('success', false);
        } else {
            response.put('success', true);
        }
        response.put('message', message);
        return response;
    }

    /**
     * Replaces the given string with empty string if the value is null.
     * Returns original value of string isn't null
     * @param input String
     *
     * @return String
     */
    public static String replaceNullVal(String input) {
        return input == null ? '' : input;
    }
}