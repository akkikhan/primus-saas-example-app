# PrimusSaaS Frontend

Angular-based frontend application for PrimusSaaS with Azure AD and Email/Password authentication.

## Features

- **Dual Authentication**:
  - Azure Active Directory (Azure AD) integration
  - Email/Password login
- **Modern UI**: Premium design with gradient backgrounds, glassmorphism effects, and smooth animations
- **Protected Routes**: Dashboard protected by authentication guard
- **JWT Token Management**: Automatic token handling and HTTP interceptors
- **Responsive Design**: Works seamlessly on desktop and mobile devices

## Prerequisites

- Node.js (v20.x or v22.x recommended)
- npm (v10.x)
- Angular CLI (optional, uses npx)

## Installation

```bash
cd primus-frontend
npm install
```

## Configuration

### Azure AD Setup

Update the Azure AD configuration in `src/app/app-module.ts`:

```typescript
export function MSALInstanceFactory(): IPublicClientApplication {
  return new PublicClientApplication({
    auth: {
      clientId: 'YOUR_AZURE_AD_CLIENT_ID', // Replace with your Azure AD Client ID
      authority: 'https://login.microsoftonline.com/YOUR_TENANT_ID', // Replace with your tenant ID
      redirectUri: 'http://localhost:4200',
      postLogoutRedirectUri: 'http://localhost:4200'
    },
    cache: {
      cacheLocation: BrowserCacheLocation.LocalStorage,
      storeAuthStateInCookie: false
    }
  });
}
```

### Backend API URL

The frontend is configured to connect to the backend at `http://localhost:5001`. If your backend runs on a different port, update the `apiUrl` in `src/app/services/auth.service.ts`:

```typescript
private apiUrl = 'http://localhost:5001/api';
```

## Running the Application

### Development Server

```bash
npm start
```

Navigate to `http://localhost:4200/`. The application will automatically reload if you change any of the source files.

### Build for Production

```bash
npm run build
```

The build artifacts will be stored in the `dist/` directory.

## Project Structure

```
primus-frontend/
├── src/
│   ├── app/
│   │   ├── components/
│   │   │   ├── login/           # Login page with dual auth
│   │   │   └── dashboard/       # Protected dashboard
│   │   ├── guards/
│   │   │   └── auth.guard.ts    # Route protection
│   │   ├── models/
│   │   │   └── user.model.ts    # TypeScript interfaces
│   │   ├── services/
│   │   │   ├── auth.service.ts       # Authentication logic
│   │   │   └── auth.interceptor.ts   # HTTP interceptor
│   │   ├── app-module.ts        # Main module with MSAL config
│   │   └── app-routing-module.ts # Route definitions
│   ├── styles.css               # Global styles
│   └── index.html               # Main HTML file
└── package.json
```

## Authentication Flow

### Email/Password Login

1. User enters email and password
2. Frontend calls `/api/token/generate` endpoint
3. Backend generates JWT token
4. Token stored in localStorage
5. User redirected to dashboard

### Azure AD Login

1. User clicks "Sign in with Microsoft"
2. MSAL popup opens for Azure AD authentication
3. User authenticates with Microsoft
4. Azure AD token received
5. Token validated with backend
6. User redirected to dashboard

## API Integration

The frontend integrates with the following backend endpoints:

- `POST /api/token/generate` - Generate JWT token for email/password login
- `GET /api/secure/user-details` - Get authenticated user details
- `GET /api/secure/protected` - Protected endpoint example

## Security Features

- **HTTP Interceptor**: Automatically adds JWT tokens to all HTTP requests
- **Auth Guard**: Protects routes from unauthorized access
- **Token Expiration**: Automatic logout on token expiration
- **Secure Storage**: Tokens stored in localStorage with expiration checks

## Styling

The application uses:
- **CSS Variables**: For consistent theming
- **Google Fonts**: Inter font family
- **Gradient Backgrounds**: Purple/violet gradients
- **Glassmorphism**: Modern frosted glass effects
- **Animations**: Smooth transitions and micro-interactions

## Development

### Code Scaffolding

```bash
ng generate component component-name
ng generate service service-name
ng generate guard guard-name
```

### Running Tests

```bash
npm test
```

### Linting

```bash
npm run lint
```

## Troubleshooting

### CORS Issues

If you encounter CORS errors, ensure your backend has CORS configured to allow requests from `http://localhost:4200`.

### Azure AD Configuration

Make sure your Azure AD app registration has:
- Redirect URI: `http://localhost:4200`
- Platform: Single-page application (SPA)
- API permissions: User.Read (Microsoft Graph)

### Token Issues

If authentication fails:
1. Check browser console for errors
2. Verify backend is running on `http://localhost:5001`
3. Ensure JWT secret matches between frontend token generation and backend validation

## Built With

- [Angular](https://angular.dev/) - Web framework
- [@azure/msal-angular](https://www.npmjs.com/package/@azure/msal-angular) - Azure AD authentication
- [RxJS](https://rxjs.dev/) - Reactive programming
- [TypeScript](https://www.typescriptlang.org/) - Type-safe JavaScript

## License

This project is part of the PrimusSaaS ecosystem.
