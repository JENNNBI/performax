/**
 * Firebase to Google Sheets Export - Clean Value Extraction
 * 
 * This script extracts clean values from Firebase REST API format
 * and writes them to Google Sheets in a readable format.
 * 
 * Firebase REST API returns data in nested format:
 * - {"stringValue": "value"} -> "value"
 * - {"timestampValue": "2024-01-01T00:00:00Z"} -> "2024-01-01T00:00:00Z"
 * - {"integerValue": "123"} -> 123
 * - {"doubleValue": "123.45"} -> 123.45
 * - {"booleanValue": true} -> true
 */

// Configuration
const SPREADSHEET_ID = 'YOUR_SPREADSHEET_ID_HERE'; // Replace with your Google Sheet ID
const SHEET_NAME = 'User Data'; // Name of the sheet tab

/**
 * Extract clean value from Firebase REST API format
 * Handles all Firebase value types and returns clean values
 */
function extractFirebaseValue(fieldValue) {
  if (fieldValue === null || fieldValue === undefined) {
    return '';
  }
  
  // If it's already a direct value (not wrapped), return it
  if (typeof fieldValue !== 'object') {
    return fieldValue;
  }
  
  // Handle Firebase REST API format
  if (fieldValue.stringValue !== undefined) {
    return fieldValue.stringValue;
  }
  
  if (fieldValue.timestampValue !== undefined) {
    // Return timestamp as ISO string, or format as needed
    return fieldValue.timestampValue;
  }
  
  if (fieldValue.integerValue !== undefined) {
    return parseInt(fieldValue.integerValue);
  }
  
  if (fieldValue.doubleValue !== undefined) {
    return parseFloat(fieldValue.doubleValue);
  }
  
  if (fieldValue.booleanValue !== undefined) {
    return fieldValue.booleanValue;
  }
  
  if (fieldValue.nullValue !== undefined) {
    return '';
  }
  
  // Handle array values
  if (fieldValue.arrayValue !== undefined) {
    if (fieldValue.arrayValue.values) {
      return fieldValue.arrayValue.values.map(extractFirebaseValue);
    }
    return [];
  }
  
  // Handle map values (nested objects)
  if (fieldValue.mapValue !== undefined) {
    if (fieldValue.mapValue.fields) {
      const result = {};
      for (const key in fieldValue.mapValue.fields) {
        result[key] = extractFirebaseValue(fieldValue.mapValue.fields[key]);
      }
      return result;
    }
    return {};
  }
  
  // Handle bytes (convert to base64 string)
  if (fieldValue.bytesValue !== undefined) {
    return fieldValue.bytesValue;
  }
  
  // Handle reference (document path)
  if (fieldValue.referenceValue !== undefined) {
    return fieldValue.referenceValue;
  }
  
  // If it's a plain object but not Firebase format, return as is
  if (typeof fieldValue === 'object') {
    return JSON.stringify(fieldValue);
  }
  
  return '';
}

/**
 * Extract clean values from a Firebase document
 * Processes all fields in a document and returns clean values
 */
function extractDocumentFields(document) {
  if (!document || !document.fields) {
    return {};
  }
  
  const cleanFields = {};
  for (const key in document.fields) {
    cleanFields[key] = extractFirebaseValue(document.fields[key]);
  }
  
  return cleanFields;
}

/**
 * Format timestamp for display
 * Converts ISO timestamp to readable date format
 */
function formatTimestamp(timestamp) {
  if (!timestamp) return '';
  
  try {
    const date = new Date(timestamp);
    return Utilities.formatDate(date, Session.getScriptTimeZone(), 'yyyy-MM-dd HH:mm:ss');
  } catch (e) {
    return timestamp; // Return as-is if parsing fails
  }
}

/**
 * Handle POST requests from the Flutter app
 */
function doPost(e) {
  try {
    // Parse the request
    const requestData = JSON.parse(e.postData.contents);
    const exportMode = requestData.exportMode || 'direct';
    
    let userData;
    
    if (exportMode === 'direct') {
      // Direct mode: Data is sent in the request (already clean)
      userData = requestData.userData;
    } else {
      // Signal mode: Fetch data from Firebase REST API
      const userId = requestData.userId;
      userData = fetchUserDataFromFirebase(userId);
    }
    
    // Write to Google Sheets with clean values
    const result = writeToSheet(userData);
    
    // Return success response
    return ContentService
      .createTextOutput(JSON.stringify({
        success: true,
        message: 'Data exported successfully',
        timestamp: new Date().toISOString(),
        rowNumber: result.rowNumber
      }))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    // Return error response
    return ContentService
      .createTextOutput(JSON.stringify({
        success: false,
        message: error.toString(),
        error: error.toString()
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Handle GET requests (for testing)
 */
function doGet(e) {
  return ContentService
    .createTextOutput(JSON.stringify({
      success: true,
      message: 'Apps Script is running',
      timestamp: new Date().toISOString()
    }))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Fetch user data from Firebase REST API
 * Returns clean data with extracted values
 */
function fetchUserDataFromFirebase(userId) {
  // Firebase REST API endpoint
  const projectId = 'performax-e4b1c'; // Replace with your Firebase project ID
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}`;
  
  // You'll need to add authentication here
  // Option 1: Use Firebase Admin SDK credentials (service account)
  // Option 2: Use OAuth2 token
  // Option 3: Use Firebase ID token (passed from client)
  
  // For now, returning example structure
  // In production, implement actual Firebase REST API call with proper auth
  throw new Error('Firebase REST API integration not yet implemented. Use direct mode instead.');
}

/**
 * Write user data to Google Sheets with clean values
 */
function writeToSheet(userData) {
  const sheet = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);
  
  // Create header row if sheet is empty
  if (sheet.getLastRow() === 0) {
    const headers = [
      'Timestamp',
      'User ID',
      'Full Name',
      'Email',
      'School',
      'Grade Level',
      'Class',
      'Student Number',
      'City',
      'District',
      'Gender',
      'Birth Date',
      'Rocket Currency'
    ];
    sheet.appendRow(headers);
  }
  
  // Extract clean values from userData
  // Handle both direct format and Firebase REST API format
  const cleanData = {};
  
  for (const key in userData) {
    cleanData[key] = extractFirebaseValue(userData[key]);
  }
  
  // Prepare data row with clean values
  const row = [
    new Date().toISOString(), // Export timestamp
    cleanData.userId || '',
    cleanData.fullName || '',
    cleanData.email || '',
    cleanData.school || '',
    cleanData.gradeLevel || '',
    cleanData.class || cleanData.studentClass || '',
    cleanData.studentNumber || '',
    cleanData.city || '',
    cleanData.district || '',
    cleanData.gender || '',
    formatTimestamp(cleanData.birthDate || ''),
    cleanData.rocketCurrency || 0
  ];
  
  // Append row
  const rowNumber = sheet.getLastRow() + 1;
  sheet.appendRow(row);
  
  return {
    success: true,
    rowNumber: rowNumber
  };
}

/**
 * Test function - run this to verify extraction works
 */
function testValueExtraction() {
  // Test cases
  const testCases = [
    {
      name: 'String value',
      input: {stringValue: 'omer@gmail.com'},
      expected: 'omer@gmail.com'
    },
    {
      name: 'Timestamp value',
      input: {timestampValue: '2009-10-21T21:00:00Z'},
      expected: '2009-10-21T21:00:00Z'
    },
    {
      name: 'Integer value',
      input: {integerValue: '123'},
      expected: 123
    },
    {
      name: 'Double value',
      input: {doubleValue: '123.45'},
      expected: 123.45
    },
    {
      name: 'Boolean value',
      input: {booleanValue: true},
      expected: true
    },
    {
      name: 'Null value',
      input: {nullValue: null},
      expected: ''
    },
    {
      name: 'Direct value (already clean)',
      input: 'direct value',
      expected: 'direct value'
    }
  ];
  
  console.log('Testing value extraction...\n');
  
  testCases.forEach(testCase => {
    const result = extractFirebaseValue(testCase.input);
    const passed = JSON.stringify(result) === JSON.stringify(testCase.expected);
    
    console.log(`${passed ? '✅' : '❌'} ${testCase.name}`);
    console.log(`  Input: ${JSON.stringify(testCase.input)}`);
    console.log(`  Expected: ${JSON.stringify(testCase.expected)}`);
    console.log(`  Got: ${JSON.stringify(result)}`);
    console.log('');
  });
}

/**
 * Batch export multiple users
 * Useful for migrating existing data
 */
function batchExportUsers(userIds) {
  const sheet = SpreadsheetApp.openById(SPREADSHEET_ID).getSheetByName(SHEET_NAME);
  
  // Create header row if sheet is empty
  if (sheet.getLastRow() === 0) {
    const headers = [
      'Timestamp',
      'User ID',
      'Full Name',
      'Email',
      'School',
      'Grade Level',
      'Class',
      'Student Number',
      'City',
      'District',
      'Gender',
      'Birth Date',
      'Rocket Currency'
    ];
    sheet.appendRow(headers);
  }
  
  const rows = [];
  
  userIds.forEach(userId => {
    // Fetch user data (implement Firebase REST API call)
    // For now, placeholder
    const userData = {}; // Replace with actual Firebase fetch
    
    const cleanData = {};
    for (const key in userData) {
      cleanData[key] = extractFirebaseValue(userData[key]);
    }
    
    rows.push([
      new Date().toISOString(),
      cleanData.userId || '',
      cleanData.fullName || '',
      cleanData.email || '',
      cleanData.school || '',
      cleanData.gradeLevel || '',
      cleanData.class || cleanData.studentClass || '',
      cleanData.studentNumber || '',
      cleanData.city || '',
      cleanData.district || '',
      cleanData.gender || '',
      formatTimestamp(cleanData.birthDate || ''),
      cleanData.rocketCurrency || 0
    ]);
  });
  
  // Append all rows at once (more efficient)
  if (rows.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
  }
  
  return rows.length;
}
