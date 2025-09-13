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

-- Policy สำหรับการเข้าถึงข้อมูล
CREATE POLICY "Allow all operations for authenticated users" ON patients
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow all operations for authenticated users" ON patient_records
    FOR ALL USING (auth.role() = 'authenticated');