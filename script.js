// Patient Monitoring App JavaScript
// ระบบติดตามค่าความดันโลหิตและ DTX

// Supabase Configuration
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

// Initialize Supabase client
let supabase;

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    setupEventListeners();
});

function initializeApp() {
    // Initialize Supabase (will be configured later)
    if (SUPABASE_URL !== 'YOUR_SUPABASE_URL' && SUPABASE_ANON_KEY !== 'YOUR_SUPABASE_ANON_KEY') {
        supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    } else {
        console.warn('Supabase configuration not set. Please update SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
}

function setupEventListeners() {
    // Form submission
    document.getElementById('recordForm').addEventListener('submit', handleRecordSubmit);
    
    // Record type change
    document.getElementById('recordType').addEventListener('change', toggleRecordFields);
    
    // Tab change events
    document.querySelectorAll('[data-bs-toggle="tab"]').forEach(tab => {
        tab.addEventListener('shown.bs.tab', handleTabChange);
    });
}

function toggleRecordFields() {
    const recordType = document.getElementById('recordType').value;
    const bloodPressureFields = document.getElementById('bloodPressureFields');
    const dtxFields = document.getElementById('dtxFields');
    const systolic = document.getElementById('systolic');
    const diastolic = document.getElementById('diastolic');
    const dtxValue = document.getElementById('dtxValue');
    
    if (recordType === 'blood_pressure') {
        bloodPressureFields.classList.remove('d-none');
        dtxFields.classList.add('d-none');
        systolic.required = true;
        diastolic.required = true;
        dtxValue.required = false;
        dtxValue.value = '';
    } else if (recordType === 'dtx') {
        dtxFields.classList.remove('d-none');
        bloodPressureFields.classList.add('d-none');
        dtxValue.required = true;
        systolic.required = false;
        diastolic.required = false;
        systolic.value = '';
        diastolic.value = '';
    } else {
        bloodPressureFields.classList.add('d-none');
        dtxFields.classList.add('d-none');
        systolic.required = false;
        diastolic.required = false;
        dtxValue.required = false;
    }
}

async function handleRecordSubmit(event) {
    event.preventDefault();
    
    if (!supabase) {
        showAlert('กรุณาตั้งค่า Supabase ก่อนใช้งาน', 'warning');
        return;
    }
    
    const formData = getFormData();
    
    if (!validateFormData(formData)) {
        return;
    }
    
    showLoading(true);
    
    try {
        // Check if patient exists, if not create one
        await ensurePatientExists(formData.hn);
        
        // Insert record
        const { data, error } = await supabase
            .from('patient_records')
            .insert([{
                hn: formData.hn,
                record_type: formData.recordType,
                systolic: formData.systolic || null,
                diastolic: formData.diastolic || null,
                dtx_value: formData.dtxValue || null,
                time_period: formData.timePeriod,
                notes: formData.notes || null
            }]);
        
        if (error) throw error;
        
        showAlert('บันทึกข้อมูลเรียบร้อยแล้ว', 'success');
        document.getElementById('recordForm').reset();
        toggleRecordFields(); // Reset field visibility
        
    } catch (error) {
        console.error('Error saving record:', error);
        showAlert('เกิดข้อผิดพลาดในการบันทึกข้อมูล: ' + error.message, 'danger');
    } finally {
        showLoading(false);
    }
}

function getFormData() {
    return {
        hn: document.getElementById('hn').value.trim(),
        recordType: document.getElementById('recordType').value,
        timePeriod: document.getElementById('timePeriod').value,
        systolic: document.getElementById('systolic').value ? parseInt(document.getElementById('systolic').value) : null,
        diastolic: document.getElementById('diastolic').value ? parseInt(document.getElementById('diastolic').value) : null,
        dtxValue: document.getElementById('dtxValue').value ? parseFloat(document.getElementById('dtxValue').value) : null,
        notes: document.getElementById('notes').value.trim()
    };
}

function validateFormData(data) {
    if (!data.hn) {
        showAlert('กรุณากรอกหมายเลข HN', 'warning');
        return false;
    }
    
    if (!data.recordType) {
        showAlert('กรุณาเลือกประเภทการวัด', 'warning');
        return false;
    }
    
    if (!data.timePeriod) {
        showAlert('กรุณาเลือกช่วงเวลาที่วัด', 'warning');
        return false;
    }
    
    if (data.recordType === 'blood_pressure') {
        if (!data.systolic || !data.diastolic) {
            showAlert('กรุณากรอกค่าความดันโลหิตให้ครบถ้วน', 'warning');
            return false;
        }
        if (data.systolic < 50 || data.systolic > 300 || data.diastolic < 30 || data.diastolic > 200) {
            showAlert('ค่าความดันโลหิตไม่อยู่ในช่วงที่เหมาะสม', 'warning');
            return false;
        }
    }
    
    if (data.recordType === 'dtx') {
        if (!data.dtxValue) {
            showAlert('กรุณากรอกค่า DTX', 'warning');
            return false;
        }
        if (data.dtxValue < 0 || data.dtxValue > 1000) {
            showAlert('ค่า DTX ไม่อยู่ในช่วงที่เหมาะสม', 'warning');
            return false;
        }
    }
    
    return true;
}

async function ensurePatientExists(hn) {
    const { data, error } = await supabase
        .from('patients')
        .select('id')
        .eq('hn', hn)
        .single();
    
    if (error && error.code === 'PGRST116') {
        // Patient doesn't exist, create one
        const { error: insertError } = await supabase
            .from('patients')
            .insert([{ hn: hn }]);
        
        if (insertError) throw insertError;
    } else if (error) {
        throw error;
    }
}

async function searchRecords() {
    if (!supabase) {
        showAlert('กรุณาตั้งค่า Supabase ก่อนใช้งาน', 'warning');
        return;
    }
    
    const searchHN = document.getElementById('searchHN').value.trim();
    const searchType = document.getElementById('searchType').value;
    
    if (!searchHN) {
        showAlert('กรุณากรอกหมายเลข HN ที่ต้องการค้นหา', 'warning');
        return;
    }
    
    showLoading(true);
    
    try {
        let query = supabase
            .from('patient_records')
            .select('*')
            .eq('hn', searchHN)
            .order('measured_at', { ascending: false });
        
        if (searchType) {
            query = query.eq('record_type', searchType);
        }
        
        const { data, error } = await query;
        
        if (error) throw error;
        
        displaySearchResults(data, searchHN);
        
    } catch (error) {
        console.error('Error searching records:', error);
        showAlert('เกิดข้อผิดพลาดในการค้นหาข้อมูล: ' + error.message, 'danger');
    } finally {
        showLoading(false);
    }
}

function displaySearchResults(records, hn) {
    const resultsContainer = document.getElementById('searchResults');
    
    if (records.length === 0) {
        resultsContainer.innerHTML = `
            <div class="alert alert-info">
                <i class="fas fa-info-circle me-2"></i>
                ไม่พบข้อมูลสำหรับ HN: ${hn}
            </div>
        `;
        return;
    }
    
    let tableHTML = `
        <div class="card record-table">
            <div class="card-header">
                <h6 class="mb-0">
                    <i class="fas fa-list me-2"></i>
                    ผลการค้นหา HN: ${hn} (${records.length} รายการ)
                </h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>วันที่/เวลา</th>
                                <th>ประเภท</th>
                                <th>ช่วงเวลา</th>
                                <th>ค่าที่วัด</th>
                                <th>หมายเหตุ</th>
                            </tr>
                        </thead>
                        <tbody>
    `;
    
    records.forEach(record => {
        const date = new Date(record.measured_at).toLocaleString('th-TH');
        const type = record.record_type === 'blood_pressure' ? 'ความดันโลหิต' : 'DTX';
        const timePeriod = getTimePeriodText(record.time_period);
        
        let value = '';
        if (record.record_type === 'blood_pressure') {
            value = `${record.systolic}/${record.diastolic} mmHg`;
        } else {
            value = `${record.dtx_value} mg/dL`;
        }
        
        tableHTML += `
            <tr>
                <td>${date}</td>
                <td><span class="badge bg-primary">${type}</span></td>
                <td><span class="badge badge-${record.time_period}">${timePeriod}</span></td>
                <td><strong>${value}</strong></td>
                <td>${record.notes || '-'}</td>
            </tr>
        `;
    });
    
    tableHTML += `
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `;
    
    resultsContainer.innerHTML = tableHTML;
    resultsContainer.classList.add('fade-in');
}

async function generateStatistics() {
    if (!supabase) {
        showAlert('กรุณาตั้งค่า Supabase ก่อนใช้งาน', 'warning');
        return;
    }
    
    const statsHN = document.getElementById('statsHN').value.trim();
    const statsPeriod = parseInt(document.getElementById('statsPeriod').value);
    
    if (!statsHN) {
        showAlert('กรุณากรอกหมายเลข HN ที่ต้องการดูสถิติ', 'warning');
        return;
    }
    
    showLoading(true);
    
    try {
        const startDate = new Date();
        startDate.setMonth(startDate.getMonth() - statsPeriod);
        
        const { data, error } = await supabase
            .from('patient_records')
            .select('*')
            .eq('hn', statsHN)
            .gte('measured_at', startDate.toISOString())
            .order('measured_at', { ascending: true });
        
        if (error) throw error;
        
        displayStatistics(data, statsHN, statsPeriod);
        
    } catch (error) {
        console.error('Error generating statistics:', error);
        showAlert('เกิดข้อผิดพลาดในการสร้างสถิติ: ' + error.message, 'danger');
    } finally {
        showLoading(false);
    }
}

function displayStatistics(records, hn, period) {
    const resultsContainer = document.getElementById('statisticsResults');
    
    if (records.length === 0) {
        resultsContainer.innerHTML = `
            <div class="alert alert-info">
                <i class="fas fa-info-circle me-2"></i>
                ไม่พบข้อมูลสำหรับ HN: ${hn} ในช่วง ${period} เดือนที่ผ่านมา
            </div>
        `;
        return;
    }
    
    const stats = calculateStatistics(records);
    
    let statsHTML = `
        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h6 class="mb-0">
                            <i class="fas fa-chart-bar me-2"></i>
                            สถิติ HN: ${hn} (${period} เดือนที่ผ่านมา)
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="row">
    `;
    
    // Blood Pressure Statistics
    if (stats.bloodPressure.count > 0) {
        statsHTML += `
            <div class="col-md-6 mb-4">
                <div class="card stats-card">
                    <div class="card-body">
                        <h6 class="card-title">ความดันโลหิต</h6>
                        <div class="row">
                            <div class="col-6">
                                <div class="stats-value">${Math.round(stats.bloodPressure.avgSystolic)}</div>
                                <div class="stats-label">ค่าเฉลี่ยตัวบน</div>
                            </div>
                            <div class="col-6">
                                <div class="stats-value">${Math.round(stats.bloodPressure.avgDiastolic)}</div>
                                <div class="stats-label">ค่าเฉลี่ยตัวล่าง</div>
                            </div>
                        </div>
                        <hr>
                        <small class="text-muted">
                            สูงสุด: ${stats.bloodPressure.maxSystolic}/${stats.bloodPressure.maxDiastolic} | 
                            ต่ำสุด: ${stats.bloodPressure.minSystolic}/${stats.bloodPressure.minDiastolic}
                        </small>
                    </div>
                </div>
            </div>
        `;
    }
    
    // DTX Statistics
    if (stats.dtx.count > 0) {
        statsHTML += `
            <div class="col-md-6 mb-4">
                <div class="card stats-card">
                    <div class="card-body">
                        <h6 class="card-title">DTX (น้ำตาลในเลือด)</h6>
                        <div class="stats-value">${Math.round(stats.dtx.avg * 10) / 10}</div>
                        <div class="stats-label">ค่าเฉลี่ย (mg/dL)</div>
                        <hr>
                        <small class="text-muted">
                            สูงสุด: ${stats.dtx.max} | ต่ำสุด: ${stats.dtx.min}
                        </small>
                    </div>
                </div>
            </div>
        `;
    }
    
    statsHTML += `
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Time period analysis
    const timePeriodStats = analyzeTimePeriods(records);
    if (Object.keys(timePeriodStats).length > 0) {
        statsHTML += `
            <div class="row mt-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h6 class="mb-0">
                                <i class="fas fa-clock me-2"></i>
                                การวิเคราะห์ตามช่วงเวลา
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
        `;
        
        Object.entries(timePeriodStats).forEach(([period, data]) => {
            const periodText = getTimePeriodText(period);
            statsHTML += `
                <div class="col-md-3 mb-3">
                    <div class="text-center">
                        <span class="badge badge-${period} fs-6">${periodText}</span>
                        <div class="mt-2">
                            <small class="text-muted">${data.count} ครั้ง</small>
                        </div>
                    </div>
                </div>
            `;
        });
        
        statsHTML += `
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
    
    resultsContainer.innerHTML = statsHTML;
    resultsContainer.classList.add('fade-in');
}

function calculateStatistics(records) {
    const stats = {
        bloodPressure: {
            count: 0,
            avgSystolic: 0,
            avgDiastolic: 0,
            maxSystolic: 0,
            maxDiastolic: 0,
            minSystolic: Infinity,
            minDiastolic: Infinity
        },
        dtx: {
            count: 0,
            avg: 0,
            max: 0,
            min: Infinity
        }
    };
    
    const bpRecords = records.filter(r => r.record_type === 'blood_pressure');
    const dtxRecords = records.filter(r => r.record_type === 'dtx');
    
    // Blood Pressure Statistics
    if (bpRecords.length > 0) {
        stats.bloodPressure.count = bpRecords.length;
        stats.bloodPressure.avgSystolic = bpRecords.reduce((sum, r) => sum + r.systolic, 0) / bpRecords.length;
        stats.bloodPressure.avgDiastolic = bpRecords.reduce((sum, r) => sum + r.diastolic, 0) / bpRecords.length;
        stats.bloodPressure.maxSystolic = Math.max(...bpRecords.map(r => r.systolic));
        stats.bloodPressure.maxDiastolic = Math.max(...bpRecords.map(r => r.diastolic));
        stats.bloodPressure.minSystolic = Math.min(...bpRecords.map(r => r.systolic));
        stats.bloodPressure.minDiastolic = Math.min(...bpRecords.map(r => r.diastolic));
    }
    
    // DTX Statistics
    if (dtxRecords.length > 0) {
        stats.dtx.count = dtxRecords.length;
        stats.dtx.avg = dtxRecords.reduce((sum, r) => sum + r.dtx_value, 0) / dtxRecords.length;
        stats.dtx.max = Math.max(...dtxRecords.map(r => r.dtx_value));
        stats.dtx.min = Math.min(...dtxRecords.map(r => r.dtx_value));
    }
    
    return stats;
}

function analyzeTimePeriods(records) {
    const timePeriods = {};
    
    records.forEach(record => {
        if (!timePeriods[record.time_period]) {
            timePeriods[record.time_period] = {
                count: 0
            };
        }
        timePeriods[record.time_period].count++;
    });
    
    return timePeriods;
}

function getTimePeriodText(period) {
    const periods = {
        'morning': 'เช้า',
        'afternoon': 'กลางวัน',
        'evening': 'เย็น',
        'before_sleep': 'ก่อนนอน'
    };
    return periods[period] || period;
}

function handleTabChange(event) {
    const targetTab = event.target.getAttribute('data-bs-target');
    
    // Clear search results when switching tabs
    if (targetTab === '#search') {
        document.getElementById('searchResults').innerHTML = '';
    }
    
    if (targetTab === '#statistics') {
        document.getElementById('statisticsResults').innerHTML = '';
    }
}

function showAlert(message, type = 'info') {
    // Remove existing alerts
    const existingAlerts = document.querySelectorAll('.alert-custom');
    existingAlerts.forEach(alert => alert.remove());
    
    const alertHTML = `
        <div class="alert alert-${type} alert-dismissible fade show alert-custom" role="alert">
            <i class="fas fa-${getAlertIcon(type)} me-2"></i>
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;
    
    // Insert alert at the top of the active tab content
    const activeTab = document.querySelector('.tab-pane.active');
    if (activeTab) {
        activeTab.insertAdjacentHTML('afterbegin', alertHTML);
        
        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            const alert = activeTab.querySelector('.alert-custom');
            if (alert) {
                const bsAlert = new bootstrap.Alert(alert);
                bsAlert.close();
            }
        }, 5000);
    }
}

function getAlertIcon(type) {
    const icons = {
        'success': 'check-circle',
        'danger': 'exclamation-triangle',
        'warning': 'exclamation-circle',
        'info': 'info-circle'
    };
    return icons[type] || 'info-circle';
}

function showLoading(show) {
    const modal = document.getElementById('loadingModal');
    const bsModal = new bootstrap.Modal(modal);
    
    if (show) {
        bsModal.show();
    } else {
        bsModal.hide();
    }
}

// Utility function to format dates
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('th-TH', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// Export functions for testing (if needed)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        validateFormData,
        calculateStatistics,
        analyzeTimePeriods,
        getTimePeriodText
    };
}