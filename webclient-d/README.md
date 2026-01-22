# UIM IaaS Web Client (D Language + vibe.d)

A server-side web application for managing the UIM IaaS Platform, built with D language and vibe.d framework.

## Features

- **Server-Side Rendering**: Uses vibe.d's Diet template engine (Pug/Jade-like syntax)
- **Session Management**: Secure session handling with cookies
- **Authentication**: JWT token-based authentication with the Auth Service
- **Multi-tenant Support**: Automatic tenant isolation via X-Tenant-ID header
- **Full CRUD Operations**: Manage compute instances, networks, and storage volumes
- **Monitoring Dashboard**: View system metrics and resource counts

## Technology Stack

- **Language**: D (DMD compiler)
- **Web Framework**: vibe.d 0.10.3
- **Template Engine**: Diet Templates
- **HTTP Client**: vibe.d HTTPClient
- **Session Store**: In-memory session storage

## Prerequisites

- DMD or LDC D compiler
- DUB package manager
- Running UIM IaaS services:
  - API Gateway: http://localhost:8080
  - Auth Service: http://localhost:8084
  - Compute Service: http://localhost:8081
  - Network Service: http://localhost:8083
  - Storage Service: http://localhost:8082

## Installation

```bash
cd webclient-d
dub build
```

## Running

```bash
dub run
```

The web client will start on http://localhost:8090

## Usage

### Login
1. Navigate to http://localhost:8090
2. Login with default credentials:
   - Username: `admin`
   - Password: `admin123`

### Manage Resources

**Compute Instances:**
- View all instances at `/compute`
- Create new instance at `/compute/create`
- Start/Stop/Delete instances with action buttons

**Virtual Networks:**
- View all networks at `/network`
- Create new network at `/network/create`
- Delete networks with delete button

**Storage Volumes:**
- View all volumes at `/storage`
- Create new volume at `/storage/create`
- Delete volumes with delete button

**Monitoring:**
- View metrics at `/monitoring`
- See resource counts and system health

## Architecture

### Directory Structure

```
webclient-d/
├── source/
│   └── app.d              # Main application code
├── views/                  # Diet templates
│   ├── layout.dt          # Base layout
│   ├── login.dt           # Login page
│   ├── dashboard.dt       # Dashboard
│   ├── compute.dt         # Compute instances list
│   ├── compute_create.dt  # Create instance form
│   ├── network.dt         # Networks list
│   ├── network_create.dt  # Create network form
│   ├── storage.dt         # Volumes list
│   ├── storage_create.dt  # Create volume form
│   └── monitoring.dt      # Monitoring dashboard
├── public/                # Static files (optional)
└── dub.sdl               # DUB configuration
```

### Key Components

**WebInterface Class:**
- Handles all HTTP routes and requests
- Manages user sessions
- Communicates with backend services via HTTP API
- Renders Diet templates with data

**Session Management:**
- Uses vibe.d's SessionVar for secure session storage
- Stores: username, JWT token, tenant ID, authentication status
- Automatic session cookie handling

**API Integration:**
- HTTPClient for REST API calls
- Automatic token and tenant ID headers
- Error handling and status code checking

## Configuration

Edit the API Gateway URL in `source/app.d`:

```d
immutable string API_GATEWAY = "http://localhost:8080/api/v1";
```

Change the web client port:

```d
settings.port = 8090;
```

## Diet Template Syntax

Diet templates use indentation-based syntax similar to Pug/Jade:

```pug
doctype html
html
  head
    title My Page
  body
    h1 Welcome
    .container
      p This is content
```

Variables from D code:
```pug
h1= username
p Welcome, #{username}!
```

Conditionals and loops:
```pug
- if (instances.length > 0)
  ul
    - foreach (instance; instances)
      li= instance.name
```

## Advantages of D + vibe.d

1. **Performance**: Compiled native code, faster than interpreted languages
2. **Type Safety**: Compile-time type checking prevents runtime errors
3. **Memory Safety**: @safe functions prevent memory corruption
4. **Async I/O**: High-performance asynchronous HTTP operations
5. **Single Binary**: Compiled to standalone executable
6. **Low Memory**: Efficient memory usage compared to JVM/Node.js

## API Endpoints Used

- POST `/auth/login` - User authentication
- GET `/compute/instances` - List instances
- POST `/compute/instances` - Create instance
- POST `/compute/instances/:id/start` - Start instance
- POST `/compute/instances/:id/stop` - Stop instance
- DELETE `/compute/instances/:id` - Delete instance
- GET `/network/networks` - List networks
- POST `/network/networks` - Create network
- DELETE `/network/networks/:id` - Delete network
- GET `/storage/volumes` - List volumes
- POST `/storage/volumes` - Create volume
- DELETE `/storage/volumes/:id` - Delete volume

## Development

### Hot Reload
For development with auto-rebuild on file changes:

```bash
dub run --force
```

### Build Release Version
```bash
dub build --build=release
./webclient-d
```

### Debug Mode
```bash
dub run --build=debug
```

## Security Features

- Session-based authentication
- CSRF protection via session validation
- Secure cookie handling
- Token-based API authentication
- Automatic session timeout on logout

## Troubleshooting

**Port already in use:**
Change the port in `app.d` or kill the process using port 8090:
```bash
lsof -ti:8090 | xargs kill
```

**Cannot connect to API Gateway:**
Ensure all services are running with `make run` from the main directory.

**Template not found:**
Make sure the `views/` directory is in the same directory as the executable.

**Session lost:**
Check that cookies are enabled in your browser.

## Production Deployment

1. Build release version:
   ```bash
   dub build --build=release
   ```

2. Configure reverse proxy (nginx example):
   ```nginx
   location / {
       proxy_pass http://localhost:8090;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
   }
   ```

3. Use HTTPS in production
4. Configure session timeout
5. Enable rate limiting
6. Monitor with systemd or supervisor

## License

Apache-2.0
