export interface User {
    userId: string;
    email: string;
    name: string;
    roles: string[];
    tenantId?: string;
}

export interface LoginRequest {
    email: string;
    password: string;
}

export interface TokenResponse {
    token: string;
    expiresIn: number;
    user: User;
}

export interface AzureAdConfig {
    clientId: string;
    authority: string;
    redirectUri: string;
}
