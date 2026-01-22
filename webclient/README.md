# UIM IaaS Web Client

A modern, responsive web-based client for managing the UIM IaaS Platform.

## Features

- **Authentication**: Secure login with JWT tokens
- **Compute Management**: Create, start, stop, and delete compute instances
- **Network Management**: Create and manage virtual networks
- **Storage Management**: Create and manage storage volumes
- **Monitoring Dashboard**: View system metrics and alerts
- **Multi-tenant Support**: Automatic tenant isolation

## Quick Start

### Option 1: Simple HTTP Server (Python)

```bash
cd webclient
python3 -m http.server 8000
```

Open http://localhost:8000 in your browser.

### Option 2: Simple HTTP Server (Node.js)

```bash
cd webclient
npx http-server -p 8000
```

### Option 3: Direct File Access

Simply open `index.html` in your browser. Note that some browsers may have CORS restrictions with file:// protocol.

## Prerequisites

Make sure the following services are running:

- API Gateway: http://localhost:8080
- Auth Service: http://localhost:8084
- Compute Service: http://localhost:8081
- Network Service: http://localhost:8083
- Storage Service: http://localhost:8082
- Monitoring Service: http://localhost:8085

Start all services with:
```bash
make run
```

## Default Credentials

- **Username**: admin
- **Password**: admin123

## Usage

### Login
1. Enter your credentials on the login page
2. The application will automatically store your auth token

### Manage Compute Instances
1. Click on "Compute" tab
2. Click "Create Instance" to provision a new VM or container
3. Use Start/Stop/Delete buttons to manage instances

### Manage Networks
1. Click on "Network" tab
2. Click "Create Network" to create a virtual network
3. Specify the CIDR block for your network

### Manage Storage
1. Click on "Storage" tab
2. Click "Create Volume" to create a new storage volume
3. Choose between block and object storage

### View Monitoring
1. Click on "Monitoring" tab
2. View system metrics and resource counts
3. Check recent alerts
4. Click "Refresh" to update metrics

## Architecture

The web client is a single-page application (SPA) built with vanilla JavaScript:

- **index.html**: Main HTML structure
- **styles.css**: Modern, responsive CSS styling
- **app.js**: Application logic and API integration

### API Integration

All requests go through the API Gateway at `http://localhost:8080/api/v1`:

- Authentication: `/auth/login`
- Compute: `/compute/instances`
- Network: `/network/networks`
- Storage: `/storage/volumes`
- Monitoring: `/monitoring/alerts`

The client automatically includes:
- Bearer token in Authorization header
- Tenant ID in X-Tenant-ID header

## Configuration

To change the API endpoint, edit `app.js`:

```javascript
const API_BASE_URL = 'http://localhost:8080/api/v1';
```

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Development

The client uses modern JavaScript (ES6+) and CSS3 features. No build process required.

To modify:
1. Edit HTML structure in `index.html`
2. Update styles in `styles.css`
3. Modify logic in `app.js`
4. Refresh browser to see changes

## Security Notes

- Tokens are stored in localStorage
- All API requests require authentication
- Tenant isolation is enforced via X-Tenant-ID header
- HTTPS should be used in production

## Troubleshooting

**Login fails**: Check that auth-service is running on port 8084

**Resources not loading**: Verify that all services are running with `make run`

**CORS errors**: Make sure the API Gateway allows requests from your origin

**Token expired**: Click logout and login again

## Future Enhancements

- Real-time updates with WebSockets
- Advanced filtering and search
- Resource usage charts
- Bulk operations
- Dark mode theme
- Mobile app version
