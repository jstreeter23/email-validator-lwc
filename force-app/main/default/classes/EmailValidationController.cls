public with sharing class EmailValidationController {
    private static final String API_ENDPOINT = 'https://rapid-email-verifier.fly.dev/api/validate';
    private static final String REMOTE_SITE_NAME = 'RapidEmailVerifier';
    private static final Integer HTTP_TIMEOUT_MS = 30000;
    private static final Integer HTTP_SUCCESS_CODE = 200;

    @AuraEnabled(cacheable=false)
    public static EmailValidationResult validateEmail(String email) {
        validateEmailInput(email);
        HttpResponse response = executeHttpCallout(email);
        validateHttpResponse(response);
        return parseResponse(response, email);
    }

    private static void validateEmailInput(String email) {
        if (String.isBlank(email)) {
            throw new AuraHandledException('Email address is required');
        }
    }

    private static HttpRequest createHttpRequest(String email) {
        HttpRequest req = new HttpRequest();
        String encodedEmail = EncodingUtil.urlEncode(email, 'UTF-8');
        req.setEndpoint(API_ENDPOINT + '?email=' + encodedEmail);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(HTTP_TIMEOUT_MS);
        return req;
    }

    private static HttpResponse executeHttpCallout(String email) {
        HttpRequest req = createHttpRequest(email);
        Http http = new Http();
        
        try {
            return http.send(req);
        } catch (CalloutException e) {
            String errorMsg = 'Callout failed. Please ensure Remote Site Setting "' + 
                            REMOTE_SITE_NAME + '" is configured for ' + API_ENDPOINT + '. Error: ' + e.getMessage();
            throw new AuraHandledException(errorMsg);
        } catch (Exception e) {
            throw new AuraHandledException('HTTP request failed: ' + e.getMessage());
        }
    }

    private static void validateHttpResponse(HttpResponse response) {
        if (response.getStatusCode() != HTTP_SUCCESS_CODE) {
            String errorMsg = 'Validation failed: ' + response.getStatusCode() + ' - ' + 
                            response.getStatus() + '. Response: ' + response.getBody();
            throw new AuraHandledException(errorMsg);
        }
    }

    private static EmailValidationResult parseResponse(HttpResponse response, String email) {
        try {
            String responseBody = response.getBody();
            System.debug('Raw API Response Body: ' + responseBody);
            Map<String, Object> responseMap = deserializeResponse(responseBody);
            System.debug('Deserialized Response Map: ' + JSON.serialize(responseMap));
            return buildValidationResult(responseMap, email);
        } catch (Exception e) {
            System.debug('Error parsing response: ' + e.getMessage() + '. Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error parsing response: ' + e.getMessage() + '. Response: ' + response.getBody());
        }
    }

    private static Map<String, Object> deserializeResponse(String responseBody) {
        return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    }

    private static EmailValidationResult buildValidationResult(Map<String, Object> responseMap, String email) {
        EmailValidationResult result = new EmailValidationResult();
        result.email = email;
        
        // The API returns a nested structure with validations inside a "validations" object
        Map<String, Object> validations = new Map<String, Object>();
        if (responseMap.containsKey('validations')) {
            validations = (Map<String, Object>) responseMap.get('validations');
        }
        
        // Extract score (0-100) and status from root level
        result.score = extractIntegerValue(responseMap, 'score');
        result.status = extractStringValue(responseMap, 'status');
        
        // Use status to determine overall validity - only "VALID" means truly valid
        // Status can be: VALID, INVALID_FORMAT, INVALID_DOMAIN, etc.
        result.isValid = 'VALID'.equals(result.status);
        
        // Extract from nested validations object
        result.syntaxValid = extractBooleanValue(validations, 'syntax', 'syntax');
        result.domainExists = extractBooleanValue(validations, 'domain_exists', 'domainExists');
        result.hasMxRecord = extractBooleanValue(validations, 'mx_records', 'mxRecords');
        result.mailboxExists = extractBooleanValue(validations, 'mailbox_exists', 'mailboxExists');
        result.isDisposable = extractBooleanValue(validations, 'is_disposable', 'isDisposable');
        result.isRoleBased = extractBooleanValue(validations, 'is_role_based', 'isRoleBased');
        
        result.suggestion = extractStringValue(responseMap, 'suggestion');
        
        // Debug logging to help troubleshoot
        System.debug('Response Map: ' + JSON.serialize(responseMap));
        System.debug('Validations Map: ' + JSON.serialize(validations));
        System.debug('Parsed Result - isValid: ' + result.isValid + ', score: ' + result.score + ', status: ' + result.status);
        
        return result;
    }

    private static Boolean extractBooleanValue(Map<String, Object> responseMap, String snakeCaseKey, String camelCaseKey) {
        Object value = getValueWithFallback(responseMap, snakeCaseKey, camelCaseKey);
        if (value == null) {
            return false;
        }
        
        // Handle different types that might represent boolean values
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        
        // Handle string representations of boolean
        if (value instanceof String) {
            String strValue = ((String) value).toLowerCase().trim();
            return 'true'.equals(strValue) || '1'.equals(strValue);
        }
        
        // Handle numeric representations (0 = false, non-zero = true)
        if (value instanceof Decimal || value instanceof Integer) {
            Decimal numValue = value instanceof Decimal ? (Decimal) value : (Decimal) ((Integer) value);
            return numValue != 0;
        }
        
        // Default to false for unknown types
        return false;
    }

    private static String extractStringValue(Map<String, Object> responseMap, String key) {
        Object value = responseMap.get(key);
        if (value == null) {
            return null;
        }
        return String.valueOf(value);
    }

    private static Object getValueWithFallback(Map<String, Object> responseMap, String primaryKey, String fallbackKey) {
        Object value = responseMap.get(primaryKey);
        return value != null ? value : responseMap.get(fallbackKey);
    }

    private static Integer extractIntegerValue(Map<String, Object> responseMap, String key) {
        Object value = responseMap.get(key);
        if (value == null) {
            return 0;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        return 0;
    }

    public class EmailValidationResult {
        @AuraEnabled public String email;
        @AuraEnabled public Boolean isValid;          // Overall validity based on status
        @AuraEnabled public Integer score;            // 0-100 score
        @AuraEnabled public String status;            // VALID, INVALID_FORMAT, INVALID_DOMAIN, etc.
        @AuraEnabled public Boolean syntaxValid;      // Email format is correct
        @AuraEnabled public Boolean domainExists;     // Domain actually exists
        @AuraEnabled public Boolean hasMxRecord;      // Domain can receive email (has mail server)
        @AuraEnabled public Boolean mailboxExists;    // Specific mailbox exists
        @AuraEnabled public Boolean isDisposable;     // Temporary/throwaway email service
        @AuraEnabled public Boolean isRoleBased;      // Generic email like info@, support@, etc.
        @AuraEnabled public String suggestion;        // Did you mean suggestion
    }
}
