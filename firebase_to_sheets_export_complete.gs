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
 *
 * Firebase REST API verileri iç içe geçmiş formatta döndürür:
 * - {"stringValue": "değer"} -> "değer"
 * - {"timestampValue": "2024-01-01T00:00:00Z"} -> Date nesnesi
 * - {"integerValue": "123"} -> 123
 * - {"doubleValue": "123.45"} -> 123.45
 * - {"booleanValue": true} -> true
 * - {"arrayValue": {"values": [...]}} -> [...]
 * - {"mapValue": {"fields": {...}}} -> {...}
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
    return new Date(fieldValue.timestampValue); // Date nesnesine dönüştür
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
    // Dizi elemanlarından değerleri özyinelemeli olarak çıkar
    return fieldValue.arrayValue.values.map(extractFirebaseValue);
  }
  if (fieldValue.mapValue !== undefined && fieldValue.mapValue.fields !== undefined) {
    // Harita alanlarından değerleri özyinelemeli olarak çıkar
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

  // Yukarıdakilerden hiçbiri değilse, olduğu gibi geri döndür
  return fieldValue;
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
    return; // Fonksiyondan çık
  }

  // 2. Sheet Bilgilerini Tanımlama
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const sheetName = 'Firestore Users Data';
  let sheet = spreadsheet.getSheetByName(sheetName);

  if (!sheet) {
    sheet = spreadsheet.insertSheet(sheetName);
  }

  // 3. Veritabanından Veri Çekme
  const collectionName = 'users'; // ÇEKİLMEK İSTENEN KOLEKSİYON ADI
  let snapshot;
  try {
    snapshot = firestore.getDocuments(collectionName);
  } catch (e) {
    Logger.log('HATA: Firestore verileri çekilemedi. Hata: ' + e.toString());
    return;
  }

  const documents = snapshot.documents;

  if (documents.length === 0) {
    Logger.log('Koleksiyonda hiç belge bulunamadı: ' + collectionName);
    sheet.clear(); // Mevcut verileri temizle
    sheet.appendRow(['Koleksiyonda belge bulunamadı: ' + collectionName]);
    return;
  }

  // 4. Verileri İşleme ve Biçimlendirme
  // Tüm belgelerden benzersiz başlıkları dinamik olarak al
  const allHeaders = new Set();
  documents.forEach(doc => {
    Object.keys(doc.fields).forEach(field => allHeaders.add(field));
  });
  const headers = ['id', ...Array.from(allHeaders)]; // 'id'yi ilk başlık olarak ekle

  // Sayfayı temizle ve başlıkları yaz
  sheet.clear();
  sheet.appendRow(headers);

  // Veri satırlarını hazırla
  const outputData = [];

  documents.forEach(doc => {
    const row = [];
    row.push(doc.name.split('/').pop()); // Belge ID'sini tam yoldan çıkar

    headers.slice(1).forEach(header => { // 'id'yi atlayarak başlıklarda dolaş
      const fieldValue = doc.fields[header];
      
      // Firebase formatından temiz değeri çıkar
      let cleanedValue = extractFirebaseValue(fieldValue);

      // Date nesnelerini formatla
      if (cleanedValue instanceof Date) {
        cleanedValue = Utilities.formatDate(
          cleanedValue, 
          spreadsheet.getSpreadsheetTimeZone(), 
          "yyyy-MM-dd HH:mm:ss"
        );
      }
      // Diziler ve nesneler için JSON string'e dönüştür (tek hücrede görüntülemek için)
      else if (Array.isArray(cleanedValue)) {
        cleanedValue = JSON.stringify(cleanedValue);
      }
      else if (typeof cleanedValue === 'object' && cleanedValue !== null) {
        cleanedValue = JSON.stringify(cleanedValue);
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

// Menü oluşturmak için kurulum fonksiyonu (Bu, e-tabloyu açtığınızda çalışır)
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('Performax Veri Yönetimi')
    .addItem('Firestore Kullanıcı Verilerini Çek', 'getFirestoreDataToSheet')
    .addToUi();
}
