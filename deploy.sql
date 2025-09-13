-- ============================================
-- Patient Monitoring System - Complete SQL Setup
-- ใช้สำหรับ deploy ไปยัง Supabase ในครั้งเดียว
-- ============================================

-- ลบตารางเก่า (ถ้ามี) เพื่อเริ่มใหม่
DROP VIEW IF EXISTS latest_patient_records;
DROP VIEW IF EXISTS patient_statistics;
DROP FUNCTION IF EXISTS get_patient_averages(VARCHAR, INTEGER);
DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP TABLE IF EXISTS patient_records;
DROP TABLE IF EXISTS patients;

-- ============================================
-- สร้างตารางหลัก
-- ============================================

-- ตารางข้อมูลผู้ป่วย (ไม่เก็บชื่อ-นามสกุล เพื่อความเป็นส่วนตัว)
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
    record_type VARCHAR(20) NOT NULL, -- 'blood_pressure' หรือ 'dtx'
    systolic INTEGER, -- สำหรับความดันโลหิต (ตัวบน)
    diastolic INTEGER, -- สำหรับความดันโลหิต (ตัวล่าง)
    dtx_value DECIMAL(5,2), -- สำหรับค่า DTX
    time_period VARCHAR(20) NOT NULL, -- 'morning', 'afternoon', 'evening', 'before_sleep'
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- สร้าง Indexes เพื่อเพิ่มประสิทธิภาพ
-- ============================================

CREATE INDEX idx_patient_records_hn ON patient_records(hn);
CREATE INDEX idx_patient_records_measured_at ON patient_records(measured_at);
CREATE INDEX idx_patient_records_type ON patient_records(record_type);
CREATE INDEX idx_patient_records_time_period ON patient_records(time_period);

-- ============================================
-- ตั้งค่า Row Level Security (RLS)
-- ============================================

ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_records ENABLE ROW LEVEL SECURITY;

-- Policy สำหรับการเข้าถึงข้อมูล (อนุญาตให้ทุกคนเข้าถึงได้)
CREATE POLICY "Allow all operations for all users" ON patients
    FOR ALL USING (true);

CREATE POLICY "Allow all operations for all users" ON patient_records
    FOR ALL USING (true);

-- ============================================
-- สร้าง Functions และ Triggers
-- ============================================

-- Function สำหรับอัพเดท updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger สำหรับอัพเดท updated_at อัตโนมัติ
CREATE TRIGGER update_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function สำหรับคำนวณค่าเฉลี่ยในช่วงเวลาที่กำหนด
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
    GROUP BY pr.time_period
    ORDER BY 
        CASE pr.time_period
            WHEN 'morning' THEN 1
            WHEN 'afternoon' THEN 2
            WHEN 'evening' THEN 3
            WHEN 'before_sleep' THEN 4
        END;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- สร้าง Views
-- ============================================

-- สร้าง view สำหรับดูข้อมูลสถิติ
CREATE OR REPLACE VIEW patient_statistics AS
SELECT 
    hn,
    record_type,
    time_period,
    COUNT(*) as total_records,
    AVG(CASE WHEN record_type = 'blood_pressure' THEN systolic END) as avg_systolic,
    AVG(CASE WHEN record_type = 'blood_pressure' THEN diastolic END) as avg_diastolic,
    AVG(CASE WHEN record_type = 'dtx' THEN dtx_value END) as avg_dtx,
    MAX(CASE WHEN record_type = 'blood_pressure' THEN systolic END) as max_systolic,
    MIN(CASE WHEN record_type = 'blood_pressure' THEN systolic END) as min_systolic,
    MAX(CASE WHEN record_type = 'dtx' THEN dtx_value END) as max_dtx,
    MIN(CASE WHEN record_type = 'dtx' THEN dtx_value END) as min_dtx
FROM patient_records
GROUP BY hn, record_type, time_period;

-- สร้าง view สำหรับดูข้อมูลล่าสุดของแต่ละผู้ป่วย
CREATE OR REPLACE VIEW latest_patient_records AS
SELECT DISTINCT ON (hn, record_type, time_period)
    hn,
    record_type,
    time_period,
    systolic,
    diastolic,
    dtx_value,
    measured_at,
    notes
FROM patient_records
ORDER BY hn, record_type, time_period, measured_at DESC;

-- ============================================
-- เพิ่มข้อมูลทดสอบ
-- ============================================

-- Sample patients
INSERT INTO patients (hn, age, gender) VALUES 
('HN001', 45, 'male'),
('HN002', 52, 'female'),
('HN003', 38, 'male'),
('HN004', 60, 'female'),
('HN005', 35, 'male')
ON CONFLICT (hn) DO NOTHING;

-- Sample blood pressure records
INSERT INTO patient_records (hn, record_type, systolic, diastolic, time_period, measured_at) VALUES 
-- HN001 - วันที่ 1
('HN001', 'blood_pressure', 120, 80, 'morning', NOW() - INTERVAL '1 day'),
('HN001', 'blood_pressure', 125, 82, 'afternoon', NOW() - INTERVAL '1 day'),
('HN001', 'blood_pressure', 118, 78, 'evening', NOW() - INTERVAL '1 day'),
('HN001', 'blood_pressure', 115, 75, 'before_sleep', NOW() - INTERVAL '1 day'),
-- HN001 - วันที่ 2
('HN001', 'blood_pressure', 122, 81, 'morning', NOW() - INTERVAL '2 days'),
('HN001', 'blood_pressure', 128, 84, 'afternoon', NOW() - INTERVAL '2 days'),
-- HN002 - วันที่ 1
('HN002', 'blood_pressure', 135, 85, 'morning', NOW() - INTERVAL '1 day'),
('HN002', 'blood_pressure', 140, 88, 'afternoon', NOW() - INTERVAL '1 day'),
('HN002', 'blood_pressure', 132, 82, 'evening', NOW() - INTERVAL '1 day'),
-- HN003 - วันที่ 1
('HN003', 'blood_pressure', 110, 70, 'morning', NOW() - INTERVAL '1 day'),
('HN003', 'blood_pressure', 115, 72, 'afternoon', NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;

-- Sample DTX records
INSERT INTO patient_records (hn, record_type, dtx_value, time_period, measured_at) VALUES 
-- HN001 DTX
('HN001', 'dtx', 95.5, 'morning', NOW() - INTERVAL '1 day'),
('HN001', 'dtx', 110.2, 'afternoon', NOW() - INTERVAL '1 day'),
('HN001', 'dtx', 88.7, 'evening', NOW() - INTERVAL '1 day'),
('HN001', 'dtx', 92.3, 'before_sleep', NOW() - INTERVAL '1 day'),
-- HN002 DTX
('HN002', 'dtx', 105.8, 'morning', NOW() - INTERVAL '1 day'),
('HN002', 'dtx', 125.4, 'afternoon', NOW() - INTERVAL '1 day'),
('HN002', 'dtx', 98.6, 'evening', NOW() - INTERVAL '1 day'),
-- HN003 DTX
('HN003', 'dtx', 85.2, 'morning', NOW() - INTERVAL '1 day'),
('HN003', 'dtx', 102.7, 'afternoon', NOW() - INTERVAL '1 day')
ON CONFLICT DO NOTHING;

-- ============================================
-- ตรวจสอบการติดตั้ง
-- ============================================

-- แสดงจำนวนข้อมูลในแต่ละตาราง
SELECT 'patients' as table_name, COUNT(*) as record_count FROM patients
UNION ALL
SELECT 'patient_records' as table_name, COUNT(*) as record_count FROM patient_records;

-- แสดงข้อมูลตัวอย่าง
SELECT 'Sample Patients:' as info;
SELECT hn, age, gender FROM patients LIMIT 3;

SELECT 'Sample Records:' as info;
SELECT hn, record_type, systolic, diastolic, dtx_value, time_period 
FROM patient_records 
ORDER BY measured_at DESC 
LIMIT 5;

-- ทดสอบ function
SELECT 'Testing get_patient_averages function:' as info;
SELECT * FROM get_patient_averages('HN001', 1);

-- แสดงข้อความสำเร็จ
SELECT '✅ Database setup completed successfully!' as status;
SELECT '🏥 Patient Monitoring System is ready to use!' as message;