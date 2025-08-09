const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Proxy API calls to backend service
app.get('/api/message', async (req, res) => {
    try {
        console.log('Frontend: Received request for /api/message, proxying to backend...');
        
        // Call backend service using Kubernetes service name
        const backendUrl = 'http://backend-service:80/api/message';
        console.log('Frontend: Calling backend at:', backendUrl);
        
        // Use node-fetch for HTTP requests
        const fetch = (await import('node-fetch')).default;
        
        const response = await fetch(backendUrl);
        console.log('Frontend: Backend response status:', response.status);
        
        if (!response.ok) {
            throw new Error(`Backend responded with status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Frontend: Backend data received:', data);
        res.json(data);
        
    } catch (error) {
        console.error('Frontend: Error connecting to backend:', error.message);
        res.status(500).json({ 
            error: 'Could not connect to backend service',
            message: error.message,
            timestamp: new Date().toISOString(),
            backendUrl: 'http://backend-service:80/api/message'
        });
    }
});

// Optional: Proxy the status endpoint too
app.get('/api/status', async (req, res) => {
    try {
        const backendUrl = 'http://backend-service:80/api/status';
        const fetch = (await import('node-fetch')).default;
        
        const response = await fetch(backendUrl);
        if (!response.ok) {
            throw new Error(`Backend responded with status: ${response.status}`);
        }
        
        const data = await response.json();
        res.json(data);
        
    } catch (error) {
        console.error('Frontend: Error connecting to backend:', error.message);
        res.status(500).json({ 
            error: 'Could not connect to backend service',
            message: error.message 
        });
    }
});

app.listen(port, () => {
    console.log(`Frontend server running on port ${port}`);
});
