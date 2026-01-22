// Configuration
const API_BASE_URL = 'http://localhost:8080/api/v1';

// State
let authToken = null;
let tenantId = null;
let currentUser = null;

// Utility Functions
function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.remove('active');
    });
    document.getElementById(screenId).classList.add('active');
}

function showTab(tabId) {
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    document.getElementById(tabId).classList.add('active');

    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabId.replace('-tab', '')}"]`).classList.add('active');
}

function showModal(modalId) {
    document.getElementById(modalId).classList.add('active');
}

function hideModal(modalId) {
    document.getElementById(modalId).classList.remove('active');
}

function showError(elementId, message) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = message;
        element.style.display = 'block';
    }
}

function clearError(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = '';
        element.style.display = 'none';
    }
}

// API Functions
async function apiRequest(endpoint, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers
    };

    if (authToken) {
        headers['Authorization'] = `Bearer ${authToken}`;
    }

    if (tenantId) {
        headers['X-Tenant-ID'] = tenantId;
    }

    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers
        });

        if (response.status === 401) {
            logout();
            throw new Error('Session expired. Please login again.');
        }

        if (!response.ok) {
            const error = await response.json().catch(() => ({ message: 'Request failed' }));
            throw new Error(error.message || `HTTP ${response.status}`);
        }

        if (response.status === 204) {
            return null;
        }

        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Authentication
async function login(username, password) {
    try {
        const response = await apiRequest('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ username, password })
        });

        authToken = response.token;
        tenantId = response.tenantId;
        currentUser = response.username;

        localStorage.setItem('authToken', authToken);
        localStorage.setItem('tenantId', tenantId);
        localStorage.setItem('currentUser', currentUser);

        showDashboard();
    } catch (error) {
        throw error;
    }
}

function logout() {
    authToken = null;
    tenantId = null;
    currentUser = null;

    localStorage.removeItem('authToken');
    localStorage.removeItem('tenantId');
    localStorage.removeItem('currentUser');

    showScreen('login-screen');
}

function checkAuth() {
    authToken = localStorage.getItem('authToken');
    tenantId = localStorage.getItem('tenantId');
    currentUser = localStorage.getItem('currentUser');

    if (authToken && tenantId && currentUser) {
        showDashboard();
    }
}

function showDashboard() {
    document.getElementById('current-user').textContent = currentUser;
    showScreen('dashboard-screen');
    loadInstances();
}

// Compute Functions
async function loadInstances() {
    const container = document.getElementById('instances-list');
    container.innerHTML = '<div class="loading">Loading instances...</div>';

    try {
        const instances = await apiRequest('/compute/instances');
        
        if (instances.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No instances yet</h3>
                    <p>Create your first compute instance to get started</p>
                </div>
            `;
            return;
        }

        container.innerHTML = instances.map(instance => `
            <div class="resource-card">
                <div class="resource-header">
                    <div>
                        <div class="resource-title">${instance.name}</div>
                        <span class="status-badge status-${instance.status}">${instance.status}</span>
                    </div>
                    <div class="resource-actions">
                        ${instance.status === 'running' ? 
                            `<button class="btn btn-small btn-secondary" onclick="stopInstance('${instance.id}')">Stop</button>` :
                            `<button class="btn btn-small btn-success" onclick="startInstance('${instance.id}')">Start</button>`
                        }
                        <button class="btn btn-small btn-danger" onclick="deleteInstance('${instance.id}')">Delete</button>
                    </div>
                </div>
                <div class="resource-details">
                    <div class="resource-detail">
                        <span class="resource-detail-label">ID</span>
                        <span class="resource-detail-value">${instance.id}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">Type</span>
                        <span class="resource-detail-value">${instance.type}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">Flavor</span>
                        <span class="resource-detail-value">${instance.flavor}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">Image</span>
                        <span class="resource-detail-value">${instance.imageId}</span>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        container.innerHTML = `<div class="error-message">Failed to load instances: ${error.message}</div>`;
    }
}

async function createInstance(data) {
    try {
        await apiRequest('/compute/instances', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        hideModal('create-instance-modal');
        loadInstances();
    } catch (error) {
        alert('Failed to create instance: ' + error.message);
    }
}

async function startInstance(id) {
    try {
        await apiRequest(`/compute/instances/${id}/start`, { method: 'POST' });
        loadInstances();
    } catch (error) {
        alert('Failed to start instance: ' + error.message);
    }
}

async function stopInstance(id) {
    try {
        await apiRequest(`/compute/instances/${id}/stop`, { method: 'POST' });
        loadInstances();
    } catch (error) {
        alert('Failed to stop instance: ' + error.message);
    }
}

async function deleteInstance(id) {
    if (!confirm('Are you sure you want to delete this instance?')) return;
    
    try {
        await apiRequest(`/compute/instances/${id}`, { method: 'DELETE' });
        loadInstances();
    } catch (error) {
        alert('Failed to delete instance: ' + error.message);
    }
}

// Network Functions
async function loadNetworks() {
    const container = document.getElementById('networks-list');
    container.innerHTML = '<div class="loading">Loading networks...</div>';

    try {
        const networks = await apiRequest('/network/networks');
        
        if (networks.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No networks yet</h3>
                    <p>Create your first virtual network to get started</p>
                </div>
            `;
            return;
        }

        container.innerHTML = networks.map(network => `
            <div class="resource-card">
                <div class="resource-header">
                    <div>
                        <div class="resource-title">${network.name}</div>
                        <span class="status-badge status-${network.status}">${network.status}</span>
                    </div>
                    <div class="resource-actions">
                        <button class="btn btn-small btn-danger" onclick="deleteNetwork('${network.id}')">Delete</button>
                    </div>
                </div>
                <div class="resource-details">
                    <div class="resource-detail">
                        <span class="resource-detail-label">ID</span>
                        <span class="resource-detail-value">${network.id}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">CIDR</span>
                        <span class="resource-detail-value">${network.cidr}</span>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        container.innerHTML = `<div class="error-message">Failed to load networks: ${error.message}</div>`;
    }
}

async function createNetwork(data) {
    try {
        await apiRequest('/network/networks', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        hideModal('create-network-modal');
        loadNetworks();
    } catch (error) {
        alert('Failed to create network: ' + error.message);
    }
}

async function deleteNetwork(id) {
    if (!confirm('Are you sure you want to delete this network?')) return;
    
    try {
        await apiRequest(`/network/networks/${id}`, { method: 'DELETE' });
        loadNetworks();
    } catch (error) {
        alert('Failed to delete network: ' + error.message);
    }
}

// Storage Functions
async function loadVolumes() {
    const container = document.getElementById('volumes-list');
    container.innerHTML = '<div class="loading">Loading volumes...</div>';

    try {
        const volumes = await apiRequest('/storage/volumes');
        
        if (volumes.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No volumes yet</h3>
                    <p>Create your first storage volume to get started</p>
                </div>
            `;
            return;
        }

        container.innerHTML = volumes.map(volume => `
            <div class="resource-card">
                <div class="resource-header">
                    <div>
                        <div class="resource-title">${volume.name}</div>
                        <span class="status-badge status-${volume.status}">${volume.status}</span>
                    </div>
                    <div class="resource-actions">
                        <button class="btn btn-small btn-danger" onclick="deleteVolume('${volume.id}')">Delete</button>
                    </div>
                </div>
                <div class="resource-details">
                    <div class="resource-detail">
                        <span class="resource-detail-label">ID</span>
                        <span class="resource-detail-value">${volume.id}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">Type</span>
                        <span class="resource-detail-value">${volume.type}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">Size</span>
                        <span class="resource-detail-value">${volume.sizeGB} GB</span>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        container.innerHTML = `<div class="error-message">Failed to load volumes: ${error.message}</div>`;
    }
}

async function createVolume(data) {
    try {
        await apiRequest('/storage/volumes', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        hideModal('create-volume-modal');
        loadVolumes();
    } catch (error) {
        alert('Failed to create volume: ' + error.message);
    }
}

async function deleteVolume(id) {
    if (!confirm('Are you sure you want to delete this volume?')) return;
    
    try {
        await apiRequest(`/storage/volumes/${id}`, { method: 'DELETE' });
        loadVolumes();
    } catch (error) {
        alert('Failed to delete volume: ' + error.message);
    }
}

// Monitoring Functions
async function loadMetrics() {
    try {
        const [instances, networks, volumes] = await Promise.all([
            apiRequest('/compute/instances'),
            apiRequest('/network/networks'),
            apiRequest('/storage/volumes')
        ]);

        document.getElementById('metric-instances').textContent = instances.length;
        document.getElementById('metric-networks').textContent = networks.length;
        document.getElementById('metric-volumes').textContent = volumes.length;
    } catch (error) {
        console.error('Failed to load metrics:', error);
    }
}

async function loadAlerts() {
    const container = document.getElementById('alerts-list');
    container.innerHTML = '<div class="loading">Loading alerts...</div>';

    try {
        const alerts = await apiRequest('/monitoring/alerts');
        
        if (alerts.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No alerts</h3>
                    <p>System is operating normally</p>
                </div>
            `;
            return;
        }

        container.innerHTML = alerts.map(alert => `
            <div class="resource-card">
                <div class="resource-header">
                    <div>
                        <div class="resource-title">${alert.name}</div>
                        <span class="status-badge status-${alert.severity}">${alert.severity}</span>
                    </div>
                </div>
                <div class="resource-details">
                    <div class="resource-detail">
                        <span class="resource-detail-label">Message</span>
                        <span class="resource-detail-value">${alert.message}</span>
                    </div>
                    <div class="resource-detail">
                        <span class="resource-detail-label">Source</span>
                        <span class="resource-detail-value">${alert.source}</span>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        container.innerHTML = `<div class="error-message">Failed to load alerts: ${error.message}</div>`;
    }
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    // Check authentication
    checkAuth();

    // Login form
    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        clearError('login-error');

        const username = document.getElementById('username').value;
        const password = document.getElementById('password').value;

        try {
            await login(username, password);
        } catch (error) {
            showError('login-error', error.message);
        }
    });

    // Logout button
    document.getElementById('logout-btn').addEventListener('click', logout);

    // Tab navigation
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const tab = e.target.dataset.tab;
            showTab(tab + '-tab');

            // Load data for the selected tab
            if (tab === 'compute') loadInstances();
            else if (tab === 'network') loadNetworks();
            else if (tab === 'storage') loadVolumes();
            else if (tab === 'monitoring') {
                loadMetrics();
                loadAlerts();
            }
        });
    });

    // Create instance modal
    document.getElementById('create-instance-btn').addEventListener('click', () => {
        showModal('create-instance-modal');
    });

    document.getElementById('create-instance-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const data = {
            name: document.getElementById('instance-name').value,
            type: document.getElementById('instance-type').value,
            flavor: document.getElementById('instance-flavor').value,
            imageId: document.getElementById('instance-image').value
        };
        await createInstance(data);
    });

    // Create network modal
    document.getElementById('create-network-btn').addEventListener('click', () => {
        showModal('create-network-modal');
    });

    document.getElementById('create-network-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const data = {
            name: document.getElementById('network-name').value,
            cidr: document.getElementById('network-cidr').value
        };
        await createNetwork(data);
    });

    // Create volume modal
    document.getElementById('create-volume-btn').addEventListener('click', () => {
        showModal('create-volume-modal');
    });

    document.getElementById('create-volume-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const data = {
            name: document.getElementById('volume-name').value,
            type: document.getElementById('volume-type').value,
            sizeGB: parseInt(document.getElementById('volume-size').value)
        };
        await createVolume(data);
    });

    // Refresh metrics
    document.getElementById('refresh-metrics-btn').addEventListener('click', () => {
        loadMetrics();
        loadAlerts();
    });

    // Modal close buttons
    document.querySelectorAll('.close').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modal = e.target.closest('.modal');
            if (modal) {
                modal.classList.remove('active');
            }
        });
    });

    // Close modal on outside click
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.classList.remove('active');
            }
        });
    });
});
