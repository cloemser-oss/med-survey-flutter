/**
 * Firebase カスタムクレーム設定関数
 * 
 * 医療スタッフや患者に適切なロールとアクセス権限を付与します。
 * Firebase Admin SDK を使用してカスタムクレームを設定します。
 */

const admin = require('firebase-admin');

// Firebase Admin SDK 初期化
admin.initializeApp();

/**
 * 医療スタッフにロールを付与
 * 
 * @param {string} uid - ユーザーID
 * @param {string} facilityId - 施設ID
 * @param {string} role - ロール ('admin' | 'medical_staff')
 */
async function setMedicalStaffClaims(uid, facilityId, role = 'medical_staff') {
  try {
    await admin.auth().setCustomUserClaims(uid, {
      role: role,
      facilityId: facilityId,
      type: 'staff'
    });
    
    console.log(`✅ カスタムクレーム設定成功: UID=${uid}, Role=${role}, FacilityID=${facilityId}`);
    
    // データベースにも記録
    await admin.firestore().collection('users').doc(uid).set({
      role: role,
      facilityId: facilityId,
      type: 'staff',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    return { success: true, message: 'Claims set successfully' };
  } catch (error) {
    console.error('❌ カスタムクレーム設定エラー:', error);
    throw error;
  }
}

/**
 * 患者にロールを付与
 * 
 * @param {string} uid - ユーザーID
 * @param {string} facilityId - 施設ID
 * @param {string} patientId - 患者ID
 * @param {string} dateOfBirth - 生年月日 (ISO8601形式)
 */
async function setPatientClaims(uid, facilityId, patientId, dateOfBirth) {
  try {
    await admin.auth().setCustomUserClaims(uid, {
      role: 'patient',
      facilityId: facilityId,
      patientId: patientId,
      dateOfBirth: dateOfBirth,
      type: 'patient'
    });
    
    console.log(`✅ 患者クレーム設定成功: UID=${uid}, PatientID=${patientId}`);
    
    // データベースにも記録
    await admin.firestore().collection('users').doc(uid).set({
      role: 'patient',
      facilityId: facilityId,
      patientId: patientId,
      dateOfBirth: dateOfBirth,
      type: 'patient',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    return { success: true, message: 'Patient claims set successfully' };
  } catch (error) {
    console.error('❌ 患者クレーム設定エラー:', error);
    throw error;
  }
}

/**
 * カスタムクレームを削除
 * 
 * @param {string} uid - ユーザーID
 */
async function removeCustomClaims(uid) {
  try {
    await admin.auth().setCustomUserClaims(uid, null);
    console.log(`✅ カスタムクレーム削除成功: UID=${uid}`);
    return { success: true, message: 'Claims removed successfully' };
  } catch (error) {
    console.error('❌ カスタムクレーム削除エラー:', error);
    throw error;
  }
}

/**
 * ユーザーのカスタムクレームを取得
 * 
 * @param {string} uid - ユーザーID
 * @returns {Object} カスタムクレーム
 */
async function getUserClaims(uid) {
  try {
    const user = await admin.auth().getUser(uid);
    return user.customClaims || {};
  } catch (error) {
    console.error('❌ カスタムクレーム取得エラー:', error);
    throw error;
  }
}

// エクスポート
module.exports = {
  setMedicalStaffClaims,
  setPatientClaims,
  removeCustomClaims,
  getUserClaims
};

// =====================================
// 使用例
// =====================================

/*
// 1. 医療スタッフのクレーム設定
await setMedicalStaffClaims(
  'staff_uid_12345',
  'facility_001',
  'medical_staff'
);

// 2. 管理者のクレーム設定
await setMedicalStaffClaims(
  'admin_uid_67890',
  'facility_001',
  'admin'
);

// 3. 患者のクレーム設定
await setPatientClaims(
  'patient_uid_11111',
  'facility_001',
  'P00123',
  '1990-01-15T00:00:00.000Z'
);

// 4. クレームの確認
const claims = await getUserClaims('staff_uid_12345');
console.log('User claims:', claims);
// 出力: { role: 'medical_staff', facilityId: 'facility_001', type: 'staff' }

// 5. クレームの削除
await removeCustomClaims('patient_uid_11111');
*/
