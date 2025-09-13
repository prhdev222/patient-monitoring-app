# การตั้งค่า Supabase สำหรับระบบติดตามสุขภาผู้ป่วย

## ขั้นตอนการตั้งค่า Supabase

### 1. สร้างโปรเจค Supabase
1. ไปที่ [https://supabase.com](https://supabase.com)
2. สร้างบัญชีหรือเข้าสู่ระบบ
3. คลิก "New Project"
4. เลือก Organization และกรอกข้อมูลโปรเจค:
   - Name: `patient-monitoring-app`
   - Database Password: สร้างรหัสผ่านที่แข็งแรง
   - Region: เลือกที่ใกล้ที่สุด

### 2. ตั้งค่าฐานข้อมูล
1. ไปที่แท็บ "SQL Editor"
2. รันคำสั่ง SQL จากไฟล์ `database.sql`

### 3. ตั้งค่า Authentication
1. ไปที่ "Authentication" > "Settings"
2. เปิดใช้งาน "Enable email confirmations" (ถ้าต้องการ)
3. ตั้งค่า "Site URL" เป็น URL ของเว็บไซต์

### 4. ตั้งค่า API Keys
1. ไปที่ "Settings" > "API"
2. คัดลอก:
   - Project URL
   - anon/public key

### 5. อัปเดตไฟล์ config.js
```javascript
const SUPABASE_CONFIG = {
    url: 'https://your-project-id.supabase.co', // แทนที่ด้วย Project URL
    anonKey: 'your-anon-key-here' // แทนที่ด้วย anon key
};
```

### 6. ตั้งค่า Row Level Security (RLS)
1. ไปที่ "Authentication" > "Policies"
2. เปิดใช้งาน RLS สำหรับตาราง `patient_records`
3. สร้าง Policy สำหรับการอ่านและเขียนข้อมูล

## โครงสร้างฐานข้อมูล

### ตาราง patient_records
- `id`: UUID (Primary Key)
- `hn`: TEXT (Hospital Number)
- `record_type`: TEXT ('blood_pressure' หรือ 'dtx')
- `measurement_time`: TEXT ('morning', 'afternoon', 'evening', 'bedtime')
- `systolic`: INTEGER (ความดันซิสโตลิก)
- `diastolic`: INTEGER (ความดันไดแอสโตลิก)
- `dtx_value`: INTEGER (ค่า DTX)
- `recorded_at`: TIMESTAMP
- `created_at`: TIMESTAMP

## การใช้งาน

1. อัปเดตไฟล์ `config.js` ด้วยข้อมูล Supabase ของคุณ
2. เปิดไฟล์ `index.html` ในเบราว์เซอร์
3. ระบบจะเชื่อมต่อกับ Supabase โดยอัตโนมัติ

## การแก้ไขปัญหา

- ตรวจสอบ Console ในเบราว์เซอร์สำหรับข้อผิดพลาด
- ตรวจสอบว่า API Keys ถูกต้อง
- ตรวจสอบว่า RLS Policies ตั้งค่าถูกต้อง
- ตรวจสอบว่าโครงสร้างฐานข้อมูลถูกต้อง