// Supabase Configuration Example
// Copy this file to config.js and replace with your actual Supabase project credentials

const SUPABASE_CONFIG = {
    url: 'YOUR_SUPABASE_PROJECT_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY'
};

// Export configuration
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SUPABASE_CONFIG;
} else {
    window.SUPABASE_CONFIG = SUPABASE_CONFIG;
}

// Instructions:
// 1. Go to https://supabase.com/dashboard
// 2. Select your project
// 3. Go to Settings > API
// 4. Copy the Project URL and anon/public key
// 5. Replace the values above with your actual credentials
// 6. Save this file as config.js (not config.example.js)