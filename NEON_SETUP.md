# การตั้งค่า Neon Database สำหรับระบบติดตามสุขภาผู้ป่วย

## ขั้นตอนการตั้งค่า Neon Database

### 1. สร้างบัญชี Neon
1. ไปที่ [https://neon.tech](https://neon.tech)
2. สร้างบัญชีใหม่หรือเข้าสู่ระบบ
3. คลิก "Create Project"
4. กรอกข้อมูลโปรเจค:
   - Name: `patient-monitoring-app`
   - Database Name: `neondb` (หรือชื่อที่ต้องการ)
   - Region: เลือกที่ใกล้ที่สุด

### 2. ตั้งค่าฐานข้อมูล
1. ไปที่แท็บ "SQL Editor" ใน Neon Dashboard
2. รันคำสั่ง SQL จากไฟล์ `database.sql` (ใช้โครงสร้างเดียวกันกับ Supabase)

### 3. ตั้งค่า Connection String
1. ไปที่หน้า "Dashboard" ของโปรเจค
2. คัดลอก Connection String
3. อัปเดตไฟล์ `config-neon.js`:
```javascript
const NEON_CONFIG = {
    connectionString: 'postgresql://username:password@ep-xxx-xxx.us-east-1.aws.neon.tech/neondb?sslmode=require'
};
```

### 4. ติดตั้ง Dependencies
```bash
# เปลี่ยนชื่อไฟล์ package
mv package-neon.json package.json

# ติดตั้ง dependencies
npm install
```

### 5. ตั้งค่า Environment Variables
สร้างไฟล์ `.env`:
```env
DATABASE_URL=postgresql://username:password@ep-xxx-xxx.us-east-1.aws.neon.tech/neondb?sslmode=require
PORT=3000
```

### 6. เปลี่ยนการใช้งาน
1. เปลี่ยนชื่อไฟล์ `config-neon.js` เป็น `config.js`
2. เปลี่ยนชื่อไฟล์ `script-neon.js` เป็น `script.js`
3. เปลี่ยนชื่อไฟล์ `server-neon.js` เป็น `server.js`

### 7. รันแอปพลิเคชัน
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## ข้อดีของ Neon Database

### ✅ ข้อดี
- **Serverless PostgreSQL**: ไม่ต้องจัดการเซิร์ฟเวอร์
- **Auto-scaling**: ปรับขนาดอัตโนมัติตามการใช้งาน
- **Branching**: สามารถสร้าง branch ของฐานข้อมูลได้
- **Free Tier**: มี free tier ที่ให้ใช้งานได้
- **PostgreSQL Compatible**: ใช้ PostgreSQL มาตรฐาน
- **Connection Pooling**: มี connection pooling ในตัว

### ❌ ข้อเสีย
- **ต้องมี Backend**: ต้องสร้าง API server (ไม่สามารถใช้จาก frontend โดยตรง)
- **Learning Curve**: ต้องเรียนรู้ Express.js และ PostgreSQL
- **More Complex**: ซับซ้อนกว่า Supabase

## การ Deploy

### 1. Deploy บน Vercel
```bash
# ติดตั้ง Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### 2. Deploy บน Railway
```bash
# ติดตั้ง Railway CLI
npm i -g @railway/cli

# Deploy
railway login
railway init
railway up
```

### 3. Deploy บน Heroku
```bash
# ติดตั้ง Heroku CLI
# สร้าง Procfile
echo "web: node server.js" > Procfile

# Deploy
git add .
git commit -m "Deploy to Heroku"
git push heroku main
```

## การแก้ไขปัญหา

### ปัญหาการเชื่อมต่อ
- ตรวจสอบ Connection String
- ตรวจสอบ SSL settings
- ตรวจสอบ Firewall settings

### ปัญหา CORS
- ตรวจสอบการตั้งค่า CORS ใน server
- ตรวจสอบ domain ที่อนุญาต

### ปัญหา Database
- ตรวจสอบ SQL syntax
- ตรวจสอบ table structure
- ตรวจสอบ permissions

## เปรียบเทียบ Supabase vs Neon

| Feature | Supabase | Neon |
|---------|----------|------|
| **Frontend Integration** | ✅ ง่าย (Direct) | ❌ ต้องมี Backend |
| **Real-time** | ✅ Built-in | ❌ ต้องใช้ WebSocket |
| **Authentication** | ✅ Built-in | ❌ ต้องทำเอง |
| **API Generation** | ✅ Auto | ❌ ต้องเขียนเอง |
| **Database Type** | PostgreSQL | PostgreSQL |
| **Pricing** | Free tier + Paid | Free tier + Paid |
| **Learning Curve** | ง่าย | ปานกลาง |
| **Flexibility** | จำกัด | สูงมาก |

## คำแนะนำ

### ใช้ Supabase เมื่อ:
- ต้องการความง่ายในการพัฒนา
- ไม่ต้องการจัดการ backend
- ต้องการ real-time features
- ต้องการ authentication built-in

### ใช้ Neon เมื่อ:
- ต้องการความยืดหยุ่นสูง
- มีทีมที่รู้จัก PostgreSQL
- ต้องการควบคุม backend เอง
- ต้องการใช้ PostgreSQL features เต็มรูปแบบ
