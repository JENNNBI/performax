// ====
// 1. Service Account Kimlik Bilgileri (JSON'dan Özel Veriler)
// ===========================================================
const PROJECT_ID = "performax-e4b1c";
const CLIENT_EMAIL = "firebase-viewer-account-3@performax-e4b1c.iam.gserviceaccount.com";
const PRIVATE_KEY = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDOUmBl+p8TWhbF\n3yV60OCSz+/niUAbTbO5H58BfNUjLIrV3tXWxffOFzEPzUdLAtw6MNMtnQ13GDa7\nc18WOceE5Z9w5a401W1SPN+NU6RXlCBOF1JnqvEgBR+oBQ/t1BO+Gcf7twrK9LcC\nYcL6X5NRRSNPal5+9XKu9PPZNjTIIUpFlgra4TRxggmb3cHUbj6/ZT5/0O7EMg10\nxtqmtCrKmqNxlokQaAub5EpW4+kahrm82ejV3ymvVhEwL61OUoLVQDa+sIRIXjyS\nXM3DAkTQpZQvgyOREKaLStnXlynxKmZRi14Y90S5t+S1Tr8QLPvUsi7E5HKib7hG\nFr29vEMrAgMBAAECggEAUtezui7L8b7CFxhW2b4F9h0E9IBhG7Vy3Pmr5DKF+BYZ\n9u7/CLo7mmYofnJL1nwjBkB1gsKlVfUEgPa9rtRrXtq+TtwCO1eZCiTEFGCJw9qH\nsCNgJJz4LYWxJMtHjpSRisqaSGFCNaTV2OB9I//9TGwI1gndQHf4YPSc9tHzlolB\n9AEVMhMO0jWUl6d8QvKsoLPchpfHEQYCvG9upcvz5a+I1OMpugprJZOLs+enar1k\noRXTd/2yW6C0qRcLQX4u+ovk5QvuMoVfm8IOyAQ+spaWPj4bxNmwY5tiT76Nvj9e\ndM+ZdOjk3c/1mAeMBmk5ToiXjJLPJe0E16jWwgC/rQKBgQD9Vhy8W7HB7fanlHw9\nofRWk162jgUt0QwUndwUSgCYaQOmqBP8+BSKAFqQxrSgjLeiiQivwEWX+UjD8sXG\nVK2y/dbW7oHbdf5s6/W2obXEAQliENB0ISNCEqfpKncvsY5pBedmkRU2kiC8xLng\nmJaYZ9jGFI3PzTB2fROydx5DJQKBgQDQfbfqywGx/9El06TlinxI6IUMMuBgZEjv\nA6gekCjE1O0pgT30nGYJhi/ddPh+jsic3La7WHjJIs+Tm6MIwwYbTZHwDtNcNeLb\neUQMSXZtC1mWJ5YeFZ5HNcAkFcy9pZjDML2fiCHvRQQTsyUS3XirrlKotJiUEVfX\n1KP5KvbEDwKBgQCmwIHVsf2Fix8qG2DUKMBuJD7Zpw3dpJZxE5+Dc1qE98rBbi0J\n/Dl4xNbYKRNIApf1UoH3PXYRnLK62Bg6fg5/nPpHK2Mqk7ZO99oaxsKgK5aDiFHN\nvuo4WZNQtPUS3arBknNIXgM6kmEeH9fB8G5gDyru5ySZPZTCyX2noSS4SQKBgQC/\nn70JrRpayqAlXzgAzV7b9/JJOv2lOqcaH0dHCAKgnn94FVSnXZQfDtkxdw/p6jwS\niH3fBTrGyxr0NSkMpYsYTxxiAo5bAyAFzpgvntmc8cCeVLYR4pa+JnX59JtgdzJH\nvKWcWheufcV4gcACbdI6IRfR/WL7PFF7ivJG0ilKGwKBgHE0Cq0muQD2mXz7nscz\nxllqSw8I+W6Zux/+RpIkHfjvdt0uyYxnchvqxNkZAY6VKYBeQikSAUpohNFXJ3jJ\nyq5ELYjgIJrRLyPKZESTH8XoSLjsxLY/uvqoflTaBPZKMKWP76KwixzKPdoB4e1L\n3T5+uhfBQomcsJSGgdQVr0mp\n-----END PRIVATE KEY-----\n";
// ===========================================================

/**
 * Firebase REST API formatından temiz değeri çıkarır.
 * Tüm Firebase değer türlerini işler ve temiz değerleri döndürür.
 * CRITICAL: Fully unwraps ALL nested Firebase REST API structures recursively.
 */
function extractFirebaseValue(fieldValue) {
  if (fieldValue === null || fieldValue === undefined) {
    return '';
  }

  // Zaten doğrudan bir değerse (sarmalanmamışsa) geri döndür
  if (typeof fieldValue !== 'object' || fieldValue instanceof Date) {
    return fieldValue;
  }

  // Firebase REST API formatını işle - öncelik sırasına göre kontrol et
  
  // String değerleri çıkar
  if (fieldValue.stringValue !== undefined) {
    return fieldValue.stringValue;
  }
  
  // Timestamp değerleri çıkar ve Date nesnesine dönüştür
  if (fieldValue.timestampValue !== undefined) {
    return new Date(fieldValue.timestampValue);
  }
  
  // Integer değerleri çıkar
  if (fieldValue.integerValue !== undefined) {
    return parseInt(fieldValue.integerValue, 10);
  }
  
  // Double/Float değerleri çıkar
  if (fieldValue.doubleValue !== undefined) {
    return parseFloat(fieldValue.doubleValue);
  }
  
  // Boolean değerleri çıkar
  if (fieldValue.booleanValue !== undefined) {
    return fieldValue.booleanValue;
  }
  
  // Null değerleri işle
  if (fieldValue.nullValue !== undefined) {
    return '';
  }
  
  // Array değerleri - özyinelemeli olarak temizle
  if (fieldValue.arrayValue !== undefined && fieldValue.arrayValue.values !== undefined) {
    return fieldValue.arrayValue.values.map(extractFirebaseValue);
  }
  
  // Map/Object değerleri - özyinelemeli olarak temizle
  if (fieldValue.mapValue !== undefined && fieldValue.mapValue.fields !== undefined) {
    const cleanedMap = {};
    for (const key in fieldValue.mapValue.fields) {
      // CRITICAL: Recursively unwrap nested Firebase structures
      cleanedMap[key] = extractFirebaseValue(fieldValue.mapValue.fields[key]);
    }
    return cleanedMap;
  }
  
  // Bytes değerleri
  if (fieldValue.bytesValue !== undefined) {
    return fieldValue.bytesValue;
  }
  
  // Reference değerleri
  if (fieldValue.referenceValue !== undefined) {
    return fieldValue.referenceValue;
  }

  // Eğer hala bir nesne ise ve Firebase wrapper'ları yoksa, 
  // içindeki tüm alanları özyinelemeli olarak temizle
  if (typeof fieldValue === 'object' && fieldValue !== null) {
    const cleanedObject = {};
    let hasFirebaseWrappers = false;
    
    // Önce Firebase wrapper'larını kontrol et
    const firebaseWrapperKeys = ['stringValue', 'integerValue', 'doubleValue', 
                                 'booleanValue', 'timestampValue', 'nullValue', 
                                 'arrayValue', 'mapValue', 'bytesValue', 'referenceValue'];
    
    for (const key of firebaseWrapperKeys) {
      if (fieldValue[key] !== undefined) {
        hasFirebaseWrappers = true;
        break;
      }
    }
    
    // Eğer Firebase wrapper'ı yoksa, normal bir nesne olarak işle
    if (!hasFirebaseWrappers) {
      for (const key in fieldValue) {
        cleanedObject[key] = extractFirebaseValue(fieldValue[key]);
      }
      return cleanedObject;
    }
  }

  // Son çare: olduğu gibi geri döndür
  return fieldValue;
}

/**
 * Favori kitaplar (favoriteBooks) dizisinden kitap isimlerini çıkarır.
 * Her favori kitap için testSeriesKey değerini döndürür.
 * Örnek: "ens_problemler_soru_bankası"
 */
function extractFavoriteBooks(fieldValue) {
  if (!fieldValue) return '';
  
  const cleanedArray = extractFirebaseValue(fieldValue);
  if (!Array.isArray(cleanedArray)) return '';
  
  const bookNames = cleanedArray.map(book => {
    if (typeof book === 'object' && book !== null) {
      // testSeriesKey alanını bul
      return book.testSeriesKey || book.testSeriesTitle || '';
    }
    return '';
  }).filter(name => name !== '');
  
  return bookNames.join(', '); // Virgülle ayrılmış liste
}

/**
 * Favori sorular (favoriteQuestions) dizisinden tam soru yollarını çıkarır.
 * Format: "testSeriesKey_testName_soru_questionNumber"
 * Örnek: "ens_problemler_soru_bankası_test_1_soru_5"
 */
function extractFavoriteQuestions(fieldValue) {
  if (!fieldValue) return '';
  
  const cleanedArray = extractFirebaseValue(fieldValue);
  if (!Array.isArray(cleanedArray)) return '';
  
  const questionPaths = cleanedArray.map(question => {
    if (typeof question === 'object' && question !== null) {
      const testName = question.testName || '';
      const questionNumber = question.questionNumber || '';
      
      if (testName && questionNumber) {
        // Test adından test series key'i çıkar (örn: "ens_problemler_soru_bankası_test_1" -> "ens_problemler_soru_bankası")
        const testSeriesKey = testName.replace(/_test_\d+$/, '');
        return testSeriesKey + '_test_' + testName.split('_test_')[1] + '_soru_' + questionNumber;
      }
      
      // Alternatif: Eğer testName direkt formatlanmışsa
      if (testName) {
        return testName + '_soru_' + questionNumber;
      }
    }
    return '';
  }).filter(path => path !== '');
  
  return questionPaths.join(', '); // Virgülle ayrılmış liste
}

/**
 * Favori playlistler (favoritePlaylists) dizisinden playlist isimlerini çıkarır.
 * Her favori playlist için playlistName değerini döndürür.
 * Örnek: "problemler_kampı"
 */
function extractFavoritePlaylists(fieldValue) {
  if (!fieldValue) return '';
  
  const cleanedArray = extractFirebaseValue(fieldValue);
  if (!Array.isArray(cleanedArray)) return '';
  
  const playlistNames = cleanedArray.map(playlist => {
    if (typeof playlist === 'object' && playlist !== null) {
      // playlistName veya playlistId alanını bul
      return playlist.playlistName || playlist.playlistId || '';
    }
    return '';
  }).filter(name => name !== '');
  
  return playlistNames.join(', '); // Virgülle ayrılmış liste
}

/**
 * Okuduğu okul (school) bilgisini temiz bir string olarak çıkarır.
 * institution.mapValue.fields.name veya school alanından okul adını alır.
 */
function extractSchoolName(fieldValue) {
  if (!fieldValue) return '';
  
  const cleanedValue = extractFirebaseValue(fieldValue);
  
  // Eğer direkt string ise
  if (typeof cleanedValue === 'string') {
    return cleanedValue;
  }
  
  // Eğer nesne ise (institution mapValue olabilir)
  if (typeof cleanedValue === 'object' && cleanedValue !== null) {
    // institution.name veya name alanını ara
    if (cleanedValue.name) {
      return cleanedValue.name;
    }
    if (cleanedValue.institution && cleanedValue.institution.name) {
      return cleanedValue.institution.name;
    }
    // Eğer direkt school alanı varsa
    if (cleanedValue.school) {
      return cleanedValue.school;
    }
  }
  
  return '';
}

/**
 * Streak değerini numerik olarak çıkarır.
 * CRITICAL: Extracts ONLY the integer value from the 'current' field of the streak object.
 * Fully unwraps ALL nested Firebase REST API structures to ensure clean numerical extraction.
 * Firebase structure: { streak: { current: <number>, lastLoginDate: <timestamp>, updatedAt: <timestamp> } }
 * Returns: The integer streak count (e.g., 7) or 0 if not found/invalid.
 */
function extractStreakValue(fieldValue) {
  if (!fieldValue) return 0;
  
  // CRITICAL: First, fully unwrap all Firebase REST API structures recursively
  const cleanedValue = extractFirebaseValue(fieldValue);
  
  // Eğer direkt sayı ise (shouldn't happen with current structure, but handle for safety)
  if (typeof cleanedValue === 'number') {
    return Math.floor(cleanedValue); // Ensure integer
  }
  
  // Eğer string ise sayıya çevir (shouldn't happen, but handle for safety)
  if (typeof cleanedValue === 'string') {
    const num = parseInt(cleanedValue, 10);
    return isNaN(num) ? 0 : num;
  }
  
  // Eğer nesne ise (streak objesi - this is the expected structure)
  if (typeof cleanedValue === 'object' && cleanedValue !== null) {
    // CRITICAL: Check 'current' field first (this is what the Dart code stores)
    // Note: We check !== undefined explicitly to handle 0 as a valid streak value
    if (cleanedValue.current !== undefined) {
      let currentValue = cleanedValue.current;
      
      // CRITICAL: If currentValue is still wrapped in Firebase REST API format, unwrap it
      if (currentValue !== null && typeof currentValue === 'object') {
        // Check for nested Firebase REST API wrappers
        if (currentValue.integerValue !== undefined) {
          return parseInt(currentValue.integerValue, 10) || 0;
        }
        if (currentValue.doubleValue !== undefined) {
          return Math.floor(parseFloat(currentValue.doubleValue)) || 0;
        }
        if (currentValue.stringValue !== undefined) {
          const num = parseInt(currentValue.stringValue, 10);
          return isNaN(num) ? 0 : num;
        }
        // Handle nested mapValue structure (deeply nested Firebase format)
        if (currentValue.mapValue !== undefined && currentValue.mapValue.fields !== undefined) {
          const nestedCurrent = currentValue.mapValue.fields.current;
          if (nestedCurrent !== undefined) {
            // Recursively extract the nested value
            return extractStreakValue(nestedCurrent);
          }
        }
        // If still an object, try to recursively unwrap
        currentValue = extractFirebaseValue(currentValue);
      }
      
      // Handle number type (most common case after unwrapping)
      if (typeof currentValue === 'number') {
        return Math.floor(currentValue); // Ensure integer
      }
      
      // Handle string type (convert to number)
      if (typeof currentValue === 'string') {
        const num = parseInt(currentValue, 10);
        return isNaN(num) ? 0 : num;
      }
      
      // If current exists but is null, return 0
      if (currentValue === null) {
        return 0;
      }
    }
    
    // Fallback: Check for legacy field names (for backward compatibility)
    if (cleanedValue.currentStreak !== undefined) {
      const legacyValue = cleanedValue.currentStreak;
      // Ensure legacy value is also unwrapped
      const unwrappedLegacy = extractFirebaseValue(legacyValue);
      if (typeof unwrappedLegacy === 'number') {
        return Math.floor(unwrappedLegacy);
      }
      const num = parseInt(unwrappedLegacy, 10);
      return isNaN(num) ? 0 : num;
    }
    if (cleanedValue.count !== undefined) {
      const legacyValue = cleanedValue.count;
      // Ensure legacy value is also unwrapped
      const unwrappedLegacy = extractFirebaseValue(legacyValue);
      if (typeof unwrappedLegacy === 'number') {
        return Math.floor(unwrappedLegacy);
      }
      const num = parseInt(unwrappedLegacy, 10);
      return isNaN(num) ? 0 : num;
    }
  }
  
  // Default: return 0 if no valid streak value found
  return 0;
}

/**
 * Özel alanlar için özelleştirilmiş değer çıkarma fonksiyonu
 */
function extractCustomFieldValue(fieldName, fieldValue) {
  // Türkçe ve İngilizce alan adlarını kontrol et
  const lowerFieldName = fieldName.toLowerCase();
  
  // Favori kitaplar
  if (lowerFieldName === 'favoritebooks' || lowerFieldName === 'favori_kitaplar' || lowerFieldName === 'favorikitaplar') {
    return extractFavoriteBooks(fieldValue);
  }
  
  // Favori sorular
  if (lowerFieldName === 'favoritequestions' || lowerFieldName === 'favori_sorular' || lowerFieldName === 'favorisorular') {
    return extractFavoriteQuestions(fieldValue);
  }
  
  // Favori playlistler
  if (lowerFieldName === 'favoriteplaylists' || lowerFieldName === 'favori_playlistler' || lowerFieldName === 'favoriplaylistler') {
    return extractFavoritePlaylists(fieldValue);
  }
  
  // Okuduğu okul
  if (lowerFieldName === 'school' || lowerFieldName === 'okuduğu_okul' || lowerFieldName === 'okuduguokul' || lowerFieldName === 'institution') {
    return extractSchoolName(fieldValue);
  }
  
  // Streak
  if (lowerFieldName === 'streak') {
    return extractStreakValue(fieldValue);
  }
  
  // Phone Number - extract as string (already in E.164 format, e.g., +905551234567)
  // CRITICAL: Handles all Firebase formats (stringValue, direct string, nested objects)
  if (lowerFieldName === 'phonenumber' || lowerFieldName === 'phone_number' || lowerFieldName === 'phone') {
    if (!fieldValue) return '';
    
    const cleanedValue = extractFirebaseValue(fieldValue);
    
    // If it's already a string (most common case)
    if (typeof cleanedValue === 'string') {
      return cleanedValue.trim();
    }
    
    // If it's a number (shouldn't happen, but handle for safety)
    if (typeof cleanedValue === 'number') {
      return String(cleanedValue);
    }
    
    // If it's still an object, try to extract stringValue directly
    if (fieldValue && typeof fieldValue === 'object' && fieldValue.stringValue !== undefined) {
      return fieldValue.stringValue.trim();
    }
    
    // Default: return empty string if we can't extract
    return '';
  }
  
  // Phone Verification Status - extract boolean and convert to readable text
  if (lowerFieldName === 'isphoneverified' || lowerFieldName === 'is_phone_verified') {
    if (!fieldValue) return 'Doğrulanmadı';
    
    const cleanedValue = extractFirebaseValue(fieldValue);
    
    // Handle boolean directly
    if (typeof cleanedValue === 'boolean') {
      return cleanedValue ? 'Doğrulandı' : 'Doğrulanmadı';
    }
    
    // Handle Firebase booleanValue format
    if (fieldValue && typeof fieldValue === 'object' && fieldValue.booleanValue !== undefined) {
      return fieldValue.booleanValue === true ? 'Doğrulandı' : 'Doğrulanmadı';
    }
    
    // Handle string representations
    if (typeof cleanedValue === 'string') {
      const lowerStr = cleanedValue.toLowerCase().trim();
      return (lowerStr === 'true' || lowerStr === '1' || lowerStr === 'yes' || lowerStr === 'evet') 
        ? 'Doğrulandı' 
        : 'Doğrulanmadı';
    }
    
    return 'Doğrulanmadı';
  }
  
  // Diğer alanlar için normal çıkarma
  return null;
}

/**
 * Firestore'daki 'users' koleksiyonundan verileri çeker ve aktif e-tabloya yazar.
 * Verileri Firebase'in verbose formatından temiz, okunabilir değerlere dönüştürür.
 */
function getFirestoreDataToSheet() {
  // 1. Firestore Bağlantısını Kurma
  let firestore;
  try {
    firestore = FirestoreApp.getFirestore(CLIENT_EMAIL, PRIVATE_KEY, PROJECT_ID);
  } catch (e) {
    Logger.log('HATA: Firestore bağlantısı kurulamadı. Hata: ' + e.toString());
    return;
  }

  // 2. Sheet Bilgilerini Tanımlama
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const sheetName = 'Firestore Users Data';
  let sheet = spreadsheet.getSheetByName(sheetName);

  if (!sheet) {
    sheet = spreadsheet.insertSheet(sheetName);
  }

  // 3. Veritabanından Veri Çekme
  const collectionName = 'users';
  let snapshot;
  try {
    snapshot = firestore.getDocuments(collectionName);
  } catch (e) {
    Logger.log('HATA: Firestore verileri çekilemedi. Hata: ' + e.toString());
    sheet.clear();
    sheet.appendRow(['HATA: Firestore verileri çekilemedi. ' + e.toString()]);
    return;
  }

  // Snapshot yapısını kontrol et
  if (!snapshot) {
    Logger.log('HATA: Snapshot boş döndü.');
    sheet.clear();
    sheet.appendRow(['HATA: Snapshot boş döndü.']);
    return;
  }

  // Farklı olası yapıları kontrol et
  let documents = null;
  
  if (snapshot.documents && Array.isArray(snapshot.documents)) {
    documents = snapshot.documents;
    Logger.log('Belgeler snapshot.documents içinde bulundu: ' + documents.length + ' adet');
  }
  else if (Array.isArray(snapshot)) {
    documents = snapshot;
    Logger.log('Snapshot doğrudan bir dizi: ' + documents.length + ' adet');
  }
  else if (typeof snapshot === 'object') {
    for (const key in snapshot) {
      if (Array.isArray(snapshot[key])) {
        documents = snapshot[key];
        Logger.log('Belgeler ' + key + ' içinde bulundu: ' + documents.length + ' adet');
        break;
      }
    }
  }

  if (!documents || !Array.isArray(documents)) {
    Logger.log('HATA: Belgeler bulunamadı.');
    sheet.clear();
    sheet.appendRow(['HATA: Belgeler bulunamadı.']);
    return;
  }

  if (documents.length === 0) {
    Logger.log('Koleksiyonda hiç belge bulunamadı: ' + collectionName);
    sheet.clear();
    sheet.appendRow(['Koleksiyonda belge bulunamadı: ' + collectionName]);
    return;
  }

  // 4. Verileri İşleme ve Biçimlendirme
  const allHeaders = new Set();
  documents.forEach(doc => {
    if (doc && doc.fields && typeof doc.fields === 'object') {
      Object.keys(doc.fields).forEach(field => allHeaders.add(field));
    }
  });
  
  // CRITICAL: Ensure phoneNumber and isPhoneVerified are included in headers
  // Even if they don't exist in all documents, add them to maintain consistent column structure
  allHeaders.add('phoneNumber');
  allHeaders.add('isPhoneVerified');
  
  // Define preferred column order for better readability
  const preferredOrder = [
    'id',
    'email',
    'fullName',
    'phoneNumber',
    'isPhoneVerified',
    'class',
    'gender',
    'birthDate',
    'school',
    'institution',
    'streak',
    'avatarId',
    'createdAt',
    'updatedAt'
  ];
  
  // Build headers array with preferred order first, then remaining fields
  const orderedHeaders = [];
  const remainingHeaders = new Set(allHeaders);
  
  // Add preferred headers in order (if they exist)
  preferredOrder.forEach(header => {
    if (allHeaders.has(header)) {
      orderedHeaders.push(header);
      remainingHeaders.delete(header);
    }
  });
  
  // Add remaining headers alphabetically
  const sortedRemaining = Array.from(remainingHeaders).sort();
  const headers = [...orderedHeaders, ...sortedRemaining];

  // Sayfayı temizle ve başlıkları yaz
  sheet.clear();
  sheet.appendRow(headers);

  // Veri satırlarını hazırla
  const outputData = [];

  documents.forEach(doc => {
    if (!doc || !doc.fields) {
      Logger.log('UYARI: Geçersiz belge atlandı.');
      return;
    }

    const row = [];
    const docId = doc.name ? doc.name.split('/').pop() : 'N/A';
    row.push(docId);

    headers.slice(1).forEach(header => {
      const fieldValue = doc.fields[header];
      
      // Özel alanlar için özelleştirilmiş çıkarma
      let cleanedValue = extractCustomFieldValue(header, fieldValue);
      
      // Eğer özel çıkarma yoksa, normal çıkarma yap
      if (cleanedValue === null) {
        // CRITICAL: Fully unwrap all Firebase REST API structures
        cleanedValue = extractFirebaseValue(fieldValue);
        
        // Date nesnelerini formatla (handles both Date objects and timestamp strings)
        if (cleanedValue instanceof Date) {
          cleanedValue = Utilities.formatDate(
            cleanedValue, 
            spreadsheet.getSpreadsheetTimeZone(), 
            "yyyy-MM-dd HH:mm:ss"
          );
        }
        // Handle date strings that might be wrapped (e.g., "selectedDate": "...")
        else if (typeof cleanedValue === 'string' && cleanedValue.match(/^\d{4}-\d{2}-\d{2}/)) {
          // Already a formatted date string, use as-is
          // No additional processing needed
        }
        // Handle objects that might contain date fields (e.g., {selectedDate: "..."})
        else if (typeof cleanedValue === 'object' && cleanedValue !== null && !Array.isArray(cleanedValue)) {
          // Check if this is a date-related object with selectedDate or similar fields
          if (cleanedValue.selectedDate !== undefined) {
            // Extract the date value and format it
            const dateValue = extractFirebaseValue(cleanedValue.selectedDate);
            if (dateValue instanceof Date) {
              cleanedValue = Utilities.formatDate(
                dateValue,
                spreadsheet.getSpreadsheetTimeZone(),
                "yyyy-MM-dd HH:mm:ss"
              );
            } else if (typeof dateValue === 'string') {
              cleanedValue = dateValue;
            } else {
              // If we can't extract a clean date, convert to JSON
              cleanedValue = JSON.stringify(cleanedValue);
            }
          } else {
            // Not a date object, convert to JSON string
            cleanedValue = JSON.stringify(cleanedValue);
          }
        }
        // Diziler için JSON string'e dönüştür
        else if (Array.isArray(cleanedValue)) {
          cleanedValue = JSON.stringify(cleanedValue);
        }
      }

      // CRITICAL: Ensure we always push a valid value (empty string if null/undefined)
      // This prevents errors when phoneNumber or other fields are missing
      row.push(cleanedValue === null || cleanedValue === undefined ? '' : cleanedValue);
    });
    
    outputData.push(row);
  });

  // 5. E-tabloya Yazma
  if (outputData.length > 0) {
    sheet.getRange(2, 1, outputData.length, outputData[0].length).setValues(outputData);
    Logger.log(outputData.length + ' adet kullanıcı verisi başarıyla e-tabloya aktarıldı.');
  } else {
    Logger.log('Koleksiyonda (' + collectionName + ') hiç veri bulunamadı.');
    sheet.getRange('A1').setValue('Koleksiyonda hiç veri bulunamadı.');
  }
}

// Menü oluşturmak için kurulum fonksiyonu
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('Performax Veri Yönetimi')
    .addItem('Firestore Kullanıcı Verilerini Çek', 'getFirestoreDataToSheet')
    .addToUi();
}
