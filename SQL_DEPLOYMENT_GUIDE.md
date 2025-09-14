# คู่มือการ Deploy SQL ไปยัง Supabase

## ขั้นตอนการตั้งค่าฐานข้อมูล

### 1. เข้าสู่ Supabase Dashboard
1. ไปที่ [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. เข้าสู่ระบบด้วยบัญชีของคุณ
3. เลือกโปรเจค: 

### 2. เปิด SQL Editor
1. คลิกที่ "SQL Editor" ในเมนูด้านซ้าย
2. คลิก "New query" เพื่อสร้าง query ใหม่

### 3. รัน SQL Commands
คัดลอกและรัน SQL commands ตามลำดับดังนี้:

#### ขั้นตอนที่ 1: สร้างตารางหลัก
```sql
-- ตารางข้อมูลผู้ป่วย
CREATE TABLE patients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    hn VARCHAR(20) UNIQUE NOT NULL,
    age INTEGER,
    gender VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ตารางบันทึกการวัดค่าต่างๆ
CREATE TABLE patient_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    hn VARCHAR(20) NOT NULL,
    record_type VARCHAR(20) NOT NULL,
    systolic INTEGER,
    diastolic INTEGER,
    dtx_value DECIMAL(5,2),
    time_period VARCHAR(20) NOT NULL,
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### ขั้นตอนที่ 2: สร้าง Indexes
```sql
CREATE INDEX idx_patient_records_hn ON patient_records(hn);
CREATE INDEX idx_patient_records_measured_at ON patient_records(measured_at);
CREATE INDEX idx_patient_records_type ON patient_records(record_type);
```

#### ขั้นตอนที่ 3: ตั้งค่า RLS (Row Level Security)
```sql
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations for all users" ON patients
    FOR ALL USING (true);

CREATE POLICY "Allow all operations for all users" ON patient_records
    FOR ALL USING (true);
```

#### ขั้นตอนที่ 4: สร้าง Functions และ Triggers
```sql
-- Function สำหรับอัพเดท timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger
CREATE TRIGGER update_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### ขั้นตอนที่ 5: สร้าง Views และ Functions
```sql
-- View สำหรับสถิติ
CREATE OR REPLACE VIEW patient_statistics AS
SELECT 
    hn,
    record_type,
    time_period,
    COUNT(*) as total_records,
    AVG(CASE WHEN record_type = 'blood_pressure' THEN systolic END) as avg_systolic,
    AVG(CASE WHEN record_type = 'blood_pressure' THEN diastolic END) as avg_diastolic,
    AVG(CASE WHEN record_type = 'dtx' THEN dtx_value END) as avg_dtx
FROM patient_records
GROUP BY hn, record_type, time_period;

-- Function สำหรับคำนวณค่าเฉลี่ย
CREATE OR REPLACE FUNCTION get_patient_averages(
    p_hn VARCHAR(20),
    p_months INTEGER DEFAULT 1
)
RETURNS TABLE(
    time_period VARCHAR(20),
    avg_systolic DECIMAL,
    avg_diastolic DECIMAL,
    avg_dtx DECIMAL,
    record_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.time_period,
        ROUND(AVG(CASE WHEN pr.record_type = 'blood_pressure' THEN pr.systolic END), 1) as avg_systolic,
        ROUND(AVG(CASE WHEN pr.record_type = 'blood_pressure' THEN pr.diastolic END), 1) as avg_diastolic,
        ROUND(AVG(CASE WHEN pr.record_type = 'dtx' THEN pr.dtx_value END), 1) as avg_dtx,
        COUNT(*)::INTEGER as record_count
    FROM patient_records pr
    WHERE pr.hn = p_hn
        AND pr.measured_at >= NOW() - INTERVAL '1 month' * p_months
    GROUP BY pr.time_period;
END;
$$ LANGUAGE plpgsql;
```

#### ขั้นตอนที่ 6: เพิ่มข้อมูลทดสอบ (ไม่บังคับ)
```sql
-- Sample patients
INSERT INTO patients (hn, age, gender) VALUES 
('HN001', 45, 'male'),
('HN002', 52, 'female'),
('HN003', 38, 'male')
ON CONFLICT (hn) DO NOTHING;

-- Sample records
INSERT INTO patient_records (hn, record_type, systolic, diastolic, time_period) VALUES 
('HN001', 'blood_pressure', 120, 80, 'morning'),
('HN001', 'blood_pressure', 125, 82, 'afternoon'),
('HN002', 'blood_pressure', 135, 85, 'morning')
ON CONFLICT DO NOTHING;
```

## การตรวจสอบการติดตั้ง

### 1. ตรวจสอบตาราง
```sql
-- ดูรายการตาราง
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- ตรวจสอบข้อมูลในตาราง
SELECT * FROM patients;
SELECT * FROM patient_records;
```

### 2. ทดสอบ Functions
```sql
-- ทดสอบ function คำนวณค่าเฉลี่ย
SELECT * FROM get_patient_averages('HN001', 1);
```

### 3. ตรวจสอบ Views
```sql
-- ดูข้อมูลสถิติ
SELECT * FROM patient_statistics;
SELECT * FROM latest_patient_records;
```

## หมายเหตุสำคัญ

1. **RLS Policy**: ตั้งค่าให้ทุกคนเข้าถึงได้ (`true`) เพื่อความสะดวกในการทดสอบ
2. **Sample Data**: ข้อมูลทดสอบจะถูกเพิ่มอัตโนมัติ
3. **Indexes**: สร้างขึ้นเพื่อเพิ่มประสิทธิภาพการค้นหา
4. **Functions**: ใช้สำหรับคำนวณค่าเฉลี่ยและสถิติต่างๆ

## การแก้ไขปัญหา

หากพบ error "requested path is invalid":
1. ตรวจสอบว่าตารางถูกสร้างแล้ว
2. ตรวจสอบ RLS policies
3. ตรวจสอบ API URL และ Key ใน config.js
4. รีเฟรช browser และลองใหม่
