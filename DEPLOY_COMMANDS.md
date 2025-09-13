# คำสั่งสำหรับ Deploy ด้วย GitHub Actions

## ขั้นตอนการ Deploy

### 1. ตรวจสอบไฟล์ที่สร้างขึ้น
```bash
# ตรวจสอบว่าไฟล์ workflow ถูกสร้างแล้ว
ls -la .github/workflows/

# ตรวจสอบเนื้อหาไฟล์
cat .github/workflows/deploy.yml
```

### 2. Add และ Commit ไฟล์ใหม่
```bash
# Add ไฟล์ workflow และเอกสาร
git add .github/workflows/deploy.yml
git add GITHUB_ACTIONS_SETUP.md
git add CONFIG_SETUP.md
git add config.example.js
git add DEPLOY_COMMANDS.md

# Commit การเปลี่ยนแปลง
git commit -m "Add GitHub Actions workflow for auto deploy

- Add deploy.yml workflow for GitHub Pages
- Add comprehensive setup documentation
- Add config.example.js template
- Support automatic config.js generation from secrets"
```

### 3. Push ไปยัง GitHub
```bash
# Push ไปยัง main branch
git push origin main
```

### 4. ตั้งค่า GitHub Secrets (ทำใน GitHub Web Interface)

1. ไปที่ GitHub repository
2. **Settings** > **Secrets and variables** > **Actions**
3. เพิ่ม secrets:
   - `SUPABASE_URL`: `https://aasojf2zf6eqaaocsau.supabase.co`
   - `SUPABASE_ANON_KEY`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhc29qdHR6YmZlcWVhc29va3V1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3MjgwOTIsImV4cCI6MjA3MzMwNDA5Mn0.SYJzM13bDtckQLL135rGp5R3jPjQhVzy4yUFyLhtWcA`

### 5. เปิดใช้งาน GitHub Pages

1. **Settings** > **Pages**
2. **Source**: เลือก **GitHub Actions**
3. **Save**

### 6. ตรวจสอบการ Deploy

```bash
# ดู status ของ workflow
# ไปที่ GitHub > Actions tab

# หรือใช้ GitHub CLI (ถ้าติดตั้งแล้ว)
gh workflow list
gh run list
```

## การทดสอบ Workflow

### ทดสอบการเปลี่ยนแปลงเล็กน้อย:
```bash
# แก้ไขไฟล์เล็กน้อย
echo "<!-- Updated: $(date) -->" >> index.html

# Commit และ push
git add index.html
git commit -m "Test auto deploy workflow"
git push origin main
```

### ตรวจสอบผลลัพธ์:
1. ไปที่ **Actions** tab ใน GitHub
2. ดู workflow run ล่าสุด
3. ตรวจสอบว่าทุก step เสร็จสิ้นสำเร็จ
4. เปิด URL: `https://[username].github.io/patient-monitoring-app/`

## คำสั่งเพิ่มเติม

### ดู Git Status:
```bash
git status
git log --oneline -5
```

### ดู Remote Repository:
```bash
git remote -v
```

### Force Push (ใช้เมื่อจำเป็น):
```bash
git push origin main --force
```

## หมายเหตุ:

- Workflow จะทำงานอัตโนมัติทุกครั้งที่ push ไปยัง main branch
- การ deploy ใช้เวลาประมาณ 2-5 นาที
- ตรวจสอบ Actions tab เพื่อดู progress
- ถ้ามี error ให้ดู logs ใน workflow run