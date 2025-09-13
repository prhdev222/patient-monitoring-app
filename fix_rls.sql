-- ============================================
-- แก้ไขปัญหา "requested path is invalid" 
-- โดยการตั้งค่า RLS policies ใหม่
-- ============================================

-- ปิด RLS ชั่วคราวเพื่อแก้ไขปัญหา
ALTER TABLE patients DISABLE ROW LEVEL SECURITY;
ALTER TABLE patient_records DISABLE ROW LEVEL SECURITY;

-- ลบ policies เก่า
DROP POLICY IF EXISTS "Allow all operations for all users" ON patients;
DROP POLICY IF EXISTS "Allow all operations for all users" ON patient_records;

-- เปิด RLS อีกครั้ง
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_records ENABLE ROW LEVEL SECURITY;

-- สร้าง policies ใหม่ที่ชัดเจนกว่า
CREATE POLICY "Enable read access for all users" ON patients
    FOR SELECT USING (true);

CREATE POLICY "Enable insert access for all users" ON patients
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON patients
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete access for all users" ON patients
    FOR DELETE USING (true);

-- Policies สำหรับ patient_records
CREATE POLICY "Enable read access for all users" ON patient_records
    FOR SELECT USING (true);

CREATE POLICY "Enable insert access for all users" ON patient_records
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON patient_records
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete access for all users" ON patient_records
    FOR DELETE USING (true);

-- ตรวจสอบสถานะ RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('patients', 'patient_records');

-- แสดง policies ที่มีอยู่
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('patients', 'patient_records');