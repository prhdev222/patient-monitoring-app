# การตั้งค่า GitHub Actions สำหรับ Auto Deploy

## ขั้นตอนที่ 1: ตั้งค่า GitHub Secrets

### 1.1 ไปที่ GitHub Repository
1. เปิด repository ของคุณใน GitHub
2. ไปที่ **Settings** > **Secrets and variables** > **Actions**
3. คลิก **New repository secret**

### 1.2 เพิ่ม Secrets ต่อไปนี้:

#### Secret 1: SUPABASE_URL
- **Name:** `SUPABASE_URL`
- **Value:** `https://aasojf2zf6eqaaocsau.supabase.co`

#### Secret 2: SUPABASE_ANON_KEY
- **Name:** `SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhc29qdHR6YmZlcWVhc29va3V1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3MjgwOTIsImV4cCI6MjA3MzMwNDA5Mn0.SYJzM13bDtckQLL135rGp5R3jPjQhVzy4yUFyLhtWcA`

## ขั้นตอนที่ 2: เปิดใช้งาน GitHub Pages

1. ไปที่ **Settings** > **Pages**
2. ใน **Source** เลือก **GitHub Actions**
3. คลิก **Save**

## ขั้นตอนที่ 3: Push Code และ Workflow

```bash
# Add และ commit workflow file
git add .github/workflows/deploy.yml
git commit -m "Add GitHub Actions workflow for auto deploy"

# Push ไปยัง main branch
git push origin main
```

## การทำงานของ Workflow

### เมื่อไหร่ที่จะทำงาน:
- เมื่อมีการ push ไปยัง `main` branch
- เมื่อมีการสร้าง Pull Request ไปยัง `main` branch

### ขั้นตอนการทำงาน:
1. **Checkout code** - ดาวน์โหลดโค้ดจาก repository
2. **Setup Node.js** - ติดตั้ง Node.js version 18
3. **Install dependencies** - ติดตั้ง packages (ถ้ามี)
4. **Create config.js** - สร้างไฟล์ config.js จาก GitHub Secrets
5. **Build application** - คัดลอกไฟล์ไปยัง dist directory
6. **Deploy to GitHub Pages** - อัปโหลดไปยัง GitHub Pages

## ตรวจสอบการ Deploy

### 1. ดู Status ของ Workflow:
1. ไปที่ tab **Actions** ใน GitHub repository
2. ดู workflow run ล่าสุด
3. ตรวจสอบว่าทุกขั้นตอนเสร็จสิ้นด้วยสีเขียว

### 2. ตรวจสอบ URL:
- แอปจะพร้อมใช้งานที่: `https://[username].github.io/[repository-name]/`
- ตัวอย่าง: `https://prhdev222.github.io/patient-monitoring-app/`

## การแก้ไขปัญหา

### ถ้า Workflow ล้มเหลว:
1. ไปที่ **Actions** tab
2. คลิกที่ workflow run ที่ล้มเหลว
3. ดู error message ในแต่ละ step
4. แก้ไขปัญหาและ push ใหม่

### ปัญหาที่พบบ่อย:
- **Secrets ไม่ถูกต้อง**: ตรวจสอบชื่อและค่าของ secrets
- **GitHub Pages ไม่เปิด**: ตรวจสอบการตั้งค่าใน Settings > Pages
- **Permission denied**: ตรวจสอบ repository permissions

## ข้อดีของวิธีนี้:

- 🔒 **ความปลอดภัย**: Secrets ไม่ถูกเปิดเผยในโค้ด
- 🚀 **Auto Deploy**: Deploy อัตโนมัติเมื่อ push code
- 🔄 **CI/CD**: ระบบ Continuous Integration/Deployment
- 📝 **Version Control**: ทุกการเปลี่ยนแปลงถูกบันทึก
- 🌐 **GitHub Pages**: ใช้งานฟรีสำหรับ public repositories

## หมายเหตุ:

- Workflow จะทำงานทุกครั้งที่มีการ push ไปยัง main branch
- การ deploy จะใช้เวลาประมาณ 2-5 นาที
- ถ้าต้องการแก้ไข Supabase credentials ให้แก้ไขใน GitHub Secrets
- ไฟล์ `config.js` จะถูกสร้างขึ้นใหม่ทุกครั้งที่ deploy