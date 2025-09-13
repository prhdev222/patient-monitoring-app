// Supabase Configuration
// Replace these values with your actual Supabase project credentials

const SUPABASE_CONFIG = {
    url: 'https://aasojf2zf6eqaaocsau.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhc29qZjJ6ZjZlcWFhb2NzYXUiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc1NzcyODA5MiwiZXhwIjoyMDczMzA0MDkyfQ.SYJzM13bDtckQLL135rGp5R3jPjQhVzy4yUFyLhtWcA'
};

// Export configuration
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SUPABASE_CONFIG;
} else {
    window.SUPABASE_CONFIG = SUPABASE_CONFIG;
}