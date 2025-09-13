# การตั้งค่า Config.js

## ปัญหา
ไฟล์ `config.js` ถูก ignore ใน Git เพื่อป้องกันการเปิดเผยข้อมูลสำคัญ (Supabase credentials)

## วิธีแก้ไข

### 1. สำหรับการพัฒนาในเครื่อง (Local Development)

```bash
# คัดลอกไฟล์ตัวอย่าง
cp config.example.js config.js
```

หรือคัดลอกด้วยมือ:
1. เปิดไฟล์ `config.example.js`
2. คัดลอกเนื้อหาทั้งหมด
3. สร้างไฟล์ใหม่ชื่อ `config.js`
4. วางเนื้อหาและแก้ไขค่าต่อไปนี้:

```javascript
const SUPABASE_CONFIG = {
    url: 'https://your-project-id.supabase.co',
    anonKey: 'your-anon-key-here'
};
```

### 2. หาค่า Supabase Credentials

1. ไปที่ [Supabase Dashboard](https://supabase.com/dashboard)
2. เลือกโปรเจคของคุณ
3. ไปที่ **Settings** > **API**
4. คัดลอก:
   - **Project URL** (ใส่ในช่อง `url`)
   - **anon/public key** (ใส่ในช่อง `anonKey`)

### 3. สำหรับ GitHub Pages Deployment

เมื่อ deploy ไป GitHub Pages:
- ไฟล์ `config.js` จะไม่ถูก push ไป GitHub (เพราะถูก ignore)
- ต้องสร้างไฟล์ `config.js` ใหม่ใน GitHub repository หรือ
- ใช้ GitHub Secrets และ GitHub Actions สำหรับการ deploy

### 4. ตรวจสอบการตั้งค่า

เปิดแอปในเบราว์เซอร์และตรวจสอบ Console:
- ถ้าเห็นข้อความ "กรุณาตั้งค่า supabase ก่อนใช้งาน" = ยังไม่ได้ตั้งค่า
- ถ้าไม่มีข้อผิดพลาด = ตั้งค่าเรียบร้อยแล้ว

## หมายเหตุความปลอดภัย

- **ห้าม** commit ไฟล์ `config.js` ที่มีค่าจริงไป Git
- ใช้ไฟล์ `config.example.js` เป็นตัวอย่างเท่านั้น
- สำหรับ production ควรใช้ environment variables หรือ CI/CD pipeline

## การแก้ไขปัญหาเฉพาะหน้า

ถ้าต้องการให้ทีมงานอื่นใช้งานได้:
1. แชร์ค่า Supabase credentials แยกต่างหาก (ไม่ใส่ใน Git)
2. ให้แต่ละคนสร้างไฟล์ `config.js` เองตามขั้นตอนข้างต้น
3. หรือใช้ระบบ environment variables ใน deployment platform