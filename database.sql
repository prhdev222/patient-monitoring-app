-- Patient Monitoring System Database Schema
-- สำหรับระบบติดตามค่าความดันโลหิตและ DTX ของผู้ป่วย

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

-- สร้าง index เพื่อเพิ่มประสิทธิภาพการค้นหา
CREATE INDEX idx_patient_records_hn ON patient_records(hn);
CREATE INDEX idx_patient_records_measured_at ON patient_records(measured_at);
CREATE INDEX idx_patient_records_type ON patient_records(record_type);

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

-- RLS (Row Level Security) policies
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_records ENABLE ROW LEVEL SECURITY;

-- Policy สำหรับการเข้าถึงข้อมูล (อนุญาตให้ anonymous users เข้าถึงได้)
CREATE POLICY "Allow all operations for all users" ON patients
    FOR ALL USING (true);

CREATE POLICY "Allow all operations for all users" ON patient_records
    FOR ALL USING (true);

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

-- Sample data สำหรับทดสอบ
INSERT INTO patients (hn, age, gender) VALUES 
('HN001', 45, 'male'),
('HN002', 52, 'female'),
('HN003', 38, 'male')
ON CONFLICT (hn) DO NOTHING;

-- Sample records สำหรับทดสอบ
INSERT INTO patient_records (hn, record_type, systolic, diastolic, time_period, measured_at) VALUES 
('HN001', 'blood_pressure', 120, 80, 'morning', NOW() - INTERVAL '1 day'),
('HN001', 'blood_pressure', 125, 82, 'afternoon', NOW() - INTERVAL '1 day'),
('HN001', 'blood_pressure', 118, 78, 'evening', NOW() - INTERVAL '1 day'),
('HN002', 'blood_pressure', 135, 85, 'morning', NOW() - INTERVAL '2 days'),
('HN002', 'blood_pressure', 140, 88, 'afternoon', NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

INSERT INTO patient_records (hn, record_type, dtx_value, time_period, measured_at) VALUES 
('HN001', 'dtx', 95.5, 'morning', NOW() - INTERVAL '1 day'),
('HN001', 'dtx', 110.2, 'afternoon', NOW() - INTERVAL '1 day'),
('HN002', 'dtx', 88.7, 'morning', NOW() - INTERVAL '2 days'),
('HN002', 'dtx', 105.3, 'evening', NOW() - INTERVAL '2 days')
ON CONFLICT DO NOTHING;

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