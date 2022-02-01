/*********************************************************************************
 FILE         : phone-standardisation.sql
 NAME         : Phone Standardisation on BigQuery
 DESCRIPTION  : Sample of how standardise phone number using external JS 
                library "libphonenumber" on BigQuery and UDF JavaScript
 AUTHOR       : Rubens Mussi Cury
 DATE         : 01-02-2022
=================================================================================*/

DECLARE PHONE_NUMS ARRAY<STRING>;

# All phones were found in a public websites.
# Used in this simulation string ":" to add the country code - when needed.
SET PHONE_NUMS = ["+61261960196", 
                  "+1 202-501-4444", 
                  "+12020121234:US", 
                   "+55 61 3311 6197",
                   "1199321-1251:BR",
                   "+44 191 203 7010",
                   "4407958013984:GB",
                   "+330484826377",
                   "00010101010"];
                  
CREATE TEMP FUNCTION STD_PHONE(phoneString STRING)
  RETURNS STRING
  LANGUAGE js
  # Download the compiled JS and upload to your GCS
  # https://catamphetamine.gitlab.io/libphonenumber-js/libphonenumber-max.js
  # Original - [https://github.com/google/libphonenumber]
  # Rewrite  - [https://catamphetamine.gitlab.io/libphonenumber-js]
  OPTIONS (library=["gs://rubens-playground/libphonenumber-max.js"])
AS
r"""

const phoneArray = phoneString.split(":");
let phone = phoneArray[0];
let country = phoneArray[1];

try {
    number = libphonenumber.parsePhoneNumber(phone, country)
    result = {
        'Return': 'OK',
        'Country': number.country || '—',
        'National': number.formatNational(),
        'Overseas': number.formatInternational(),
        'Type': number.getType() || '—',
        'Valid': number.isValid()
    }
} catch (error) {
    result = {
        'Return': 'FORMAT_ERROR'
    }
}

return JSON.stringify(result)
""";

SELECT
  SPLIT(PHONE, ":")[OFFSET(0)] AS TYPED_PHONE,
  JSON_EXTRACT_SCALAR(STD_PHONE(PHONE), "$.Return") AS RETURN,
  JSON_EXTRACT_SCALAR(STD_PHONE(PHONE), "$.Country") AS COUNTRY,
  JSON_EXTRACT_SCALAR(STD_PHONE(PHONE), "$.National") AS NATIONAL,
  JSON_EXTRACT_SCALAR(STD_PHONE(PHONE), "$.Overseas") AS OVERSEAS,
  JSON_EXTRACT_SCALAR(STD_PHONE(PHONE), "$.Type") AS TYPE,
  JSON_EXTRACT_SCALAR(STD_PHONE(PHONE), "$.Valid") AS VALID
FROM 
  UNNEST(PHONE_NUMS) AS PHONE
