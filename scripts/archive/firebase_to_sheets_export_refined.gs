// ====
// 1. Service Account Kimlik Bilgileri (JSON'dan Özel Veriler)
// ===========================================================
const PROJECT_ID = "performax-e4b1c";
const CLIENT_EMAIL = "firebase-viewer-account-3@performax-e4b1c.iam.gserviceaccount.com";
const PRIVATE_KEY = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDOUmBI+p8TWhbF\n3yV60OCSz+/niUAbTbO5H58BfNUjLIrV3tXWxffOFzEPzUdLAtw6MNMtnQ13GDa7\nc18WOceE5Z9w5a401W1SPN+NU6RXICBOF1JnqvEgBR+oBQ/t1BO+Gcf7twrK9LcC\nYcL6X5NRRSNPal5+9XKu9PPZNjTIIUpFIgra4TRxggmb3cHUbj6/ZT5/007EMg10\nxtqmtCrKmqNxlokQaAub5EpW4+kahrm82ejV3ymvVhEwL61OUoLVQDa+sIRIXjyS\nXM3DAkTQpZQvgyOREKaLStnXlynxKmZRi14Y90S5t+S1Tr8QLPvUsi7E5HKib7hG\nFr29vEMrAgMBAAECggEAUtezui7L8b7CFxhW2b4F9h0E9IBhG7Vy3Pmr5DKF+BYZ\n9u7/CLo7mmYofnJL1nwjBkB1gsKIVFUEgPa9rtRrXtq+TtwCO1eZCITEFGCJw9qH\nsCNgJJz4LYWxJMtHjpSRisqaSGFCNaTV2OB9I//9TGwI1gndQHf4YPSc9tHzlolB\n9AEVMhMO0jWUI6d8QvKsoLPchpfHEQYCvG9upcvz5a+11OMpugprJZOLs+enar1k\noRXTd/2yW6C0qRcLQX4u+ovk5QvuMoVfm8IOyAQ+spaWPj4bxNmwY5tiT76Nvj9e\ndM+Zd0jk3c/1mAeMBmk5ToiXjJLPJe0E16jWwgC/rQKBgQD9Vhy8W7HB7fanlHw9\nofRWk162jgUt0QwUndwUSgCYaQOmqBP8+BSKAFqQxrSgjLeiiQivwEWX+UjD8sXG\nVK2y/dbW7oHbdf5s6/W2obXEAQIENB0ISNCEqfpKncvsY5pBedmkRU2kiC8xLng\nmJaYZ9jGFI3PzTB2fROydx5DJQKBgQDQfbfqywGx/9EI06TlinxI6IUMMuBgZEjv\nA6gekCjE100pgT30nGYJhi/ddPh+jsic3La7WHjJls+Tm6MlwwYbTZHwDtNcNeLb\neUQMSXZtC1mWJ5YeFZ5HNcAkFcy9pZjDML2fiCHvRQQTsyUS3XirrlKotJiUEVfX\n1KP5KvbEDwKBgQCmwlHVsf2Fix8qG2DUKMBUJD7Zpw3dpJZxE5+Dc1qE98rBbi0J\n/DI4xNbYKRNIApf1UoH3PXYRnLK62Bg6fg5/nPpHK2Mqk7ZO990axsKgK5aDiFHN\nnvuo4WZNQtPUS3arBknNIXgM6kmEeH9fB8G5gDyru5ySZPZTCyX2noSS4SQKBgQC\n//nn70JrRpayqAIXzgAzV7b9/JJOv2IOqcaH0dHCAKgnn94FVSnXZQfDtkxdw/p6jwS\niH3fBTrGyxr0NSkMpYsYTxxiAo5bAyAFzpgvntmc8cCeVLYR4pa+JnX59JtgdzJH\nvKWcWheufcV4gcACbdI6IRfR/WL7PFF7ivJG0ilKGwKBgHE0Cq0muQD2mXz7nscz\nxllqSw8l+W6Zux/+RpIkHfjvdt0uyYxnchvqxNkZAY6VKYBeQikSAUpohNFXJ3jJ\nyq5ELYjglJrRLyPKZESTH8XoSLjsxLY/uvqoflTaBPZKMKWP76KwixzKPdoB4e1L\n3T5+uhfBQomcsJSGgdQVr0mp\n-----END PRIVATE KEY-----\n";
// ===========================================================

/**
 * Firebase REST API formatından temiz değeri çıkarır.
 * Tüm Firebase değer türlerini işler ve temiz değerleri döndürür.
 */
function extractFirebaseValue(fieldValue) {
  if (fieldValue === null || fieldValue === undefined) {
    return '';
  }

  // Zaten doğrudan bir değerse (sarmalanmamışsa) geri döndür
  if (typeof fieldValue !== 'object' || fieldValue instanceof Date) {
    return fieldValue;
  }

  // Firebase REST API formatını işle
  if (fieldValue.stringValue !== undefined) {
    return fieldValue.stringValue;
  }
  if (fieldValue.timestampValue !== undefined) {
    return new Date(fieldValue.timestampValue);
  }
  if (fieldValue.integerValue !== undefined) {
    return parseInt(fieldValue.integerValue, 10);
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
  if (fieldValue.arrayValue !== undefined && fieldValue.arrayValue.values !== undefined) {
    return fieldValue.arrayValue.values.map(extractFirebaseValue);
  }
  if (fieldValue.mapValue !== undefined && fieldValue.mapValue.fields !== undefined) {
    const cleanedMap = {};
    for (const key in fieldValue.mapValue.fields) {
      cleanedMap[key] = extractFirebaseValue(fieldValue.mapValue.fields[key]);
    }
    return cleanedMap;
  }
  if (fieldValue.bytesValue !== undefined) {
    return fieldValue.bytesValue;
  }
  if (fieldValue.referenceValue !== undefined) {
    return fieldValue.referenceValue;
  }

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
 * Firebase structure: { streak: { current: <number>, lastLoginDate: <timestamp>, updatedAt: <timestamp> } }
 * Returns: The integer streak count (e.g., 7) or 0 if not found/invalid.
 */
function extractStreakValue(fieldValue) {
  if (!fieldValue) return 0;
  
  const cleanedValue = extractFirebaseValue(fieldValue);
  
  // Eğer direkt sayı ise (shouldn't happen with current structure, but handle for safety)
  if (typeof cleanedValue === 'number') {
    return cleanedValue;
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
      const currentValue = cleanedValue.current;
      
      // Handle number type (most common case)
      if (typeof currentValue === 'number') {
        return currentValue;
      }
      
      // Handle string type (convert to number)
      if (typeof currentValue === 'string') {
        const num = parseInt(currentValue, 10);
        return isNaN(num) ? 0 : num;
      }
      
      // Handle Firebase REST API format if nested (e.g., {integerValue: "7"})
      if (currentValue !== null && typeof currentValue === 'object') {
        if (currentValue.integerValue !== undefined) {
          return parseInt(currentValue.integerValue, 10) || 0;
        }
        if (currentValue.doubleValue !== undefined) {
          return parseInt(currentValue.doubleValue, 10) || 0;
        }
      }
      
      // If current exists but is null, return 0
      if (currentValue === null) {
        return 0;
      }
    }
    
    // Fallback: Check for legacy field names (for backward compatibility)
    if (cleanedValue.currentStreak !== undefined) {
      const legacyValue = cleanedValue.currentStreak;
      return typeof legacyValue === 'number' ? legacyValue : parseInt(legacyValue, 10) || 0;
    }
    if (cleanedValue.count !== undefined) {
      const legacyValue = cleanedValue.count;
      return typeof legacyValue === 'number' ? legacyValue : parseInt(legacyValue, 10) || 0;
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
  
  // Phone Number - extract as string (already in E.164 format)
  if (lowerFieldName === 'phonenumber' || lowerFieldName === 'phone_number' || lowerFieldName === 'phone') {
    const cleanedValue = extractFirebaseValue(fieldValue);
    return cleanedValue || '';
  }
  
  // Phone Verification Status
  if (lowerFieldName === 'isphoneverified' || lowerFieldName === 'is_phone_verified') {
    const cleanedValue = extractFirebaseValue(fieldValue);
    return cleanedValue === true ? 'Doğrulandı' : 'Doğrulanmadı';
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
  
  const headers = ['id', ...Array.from(allHeaders)];

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
        cleanedValue = extractFirebaseValue(fieldValue);
        
        // Date nesnelerini formatla
        if (cleanedValue instanceof Date) {
          cleanedValue = Utilities.formatDate(
            cleanedValue, 
            spreadsheet.getSpreadsheetTimeZone(), 
            "yyyy-MM-dd HH:mm:ss"
          );
        }
        // Diziler ve nesneler için JSON string'e dönüştür
        else if (Array.isArray(cleanedValue)) {
          cleanedValue = JSON.stringify(cleanedValue);
        }
        else if (typeof cleanedValue === 'object' && cleanedValue !== null) {
          cleanedValue = JSON.stringify(cleanedValue);
        }
      }

      row.push(cleanedValue);
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
