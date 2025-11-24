import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';
import { User, LoginRequest, TokenResponse } from '../models/user.model';

@Injectable({
    providedIn: 'root'
})
export class AuthService {
    private apiUrl = 'http://localhost:5001/api';
    private currentUserSubject: BehaviorSubject<User | null>;
    public currentUser: Observable<User | null>;
    private tokenKey = 'primus_auth_token';

    constructor(private http: HttpClient) {
        const storedToken = localStorage.getItem(this.tokenKey);
        this.currentUserSubject = new BehaviorSubject<User | null>(
            storedToken ? this.decodeToken(storedToken) : null
        );
        this.currentUser = this.currentUserSubject.asObservable();
    }

    public get currentUserValue(): User | null {
        return this.currentUserSubject.value;
    }

    public get token(): string | null {
        return localStorage.getItem(this.tokenKey);
    }

    login(email: string, password: string): Observable<TokenResponse> {
        console.log('=== AUTH SERVICE: Starting login ===');
        console.log('API URL:', this.apiUrl);
        console.log('Email:', email);

        // Generate token using the backend's token endpoint
        return this.http.post<any>(`${this.apiUrl}/token/generate`, {
            userId: email,
            email: email,
            name: email.split('@')[0],
            roles: ['User'],
            tenantId: 'default'
        }).pipe(
            map(response => {
                console.log('=== TOKEN RECEIVED ===');
                console.log('Token (first 50 chars):', response.token?.substring(0, 50));
                console.log('Full response:', response);

                const tokenResponse: TokenResponse = {
                    token: response.token,
                    expiresIn: 3600,
                    user: {
                        userId: email,
                        email: email,
                        name: email.split('@')[0],
                        roles: ['User']
                    }
                };

                // Store token in localStorage
                localStorage.setItem(this.tokenKey, response.token);
                console.log('Token stored in localStorage');
                this.currentUserSubject.next(tokenResponse.user);

                return tokenResponse;
            }),
            catchError(error => {
                console.error('Login error:', error);
                return throwError(() => new Error('Login failed. Please try again.'));
            })
        );
    }

    loginWithAzureAd(azureToken: string): Observable<User> {
        console.log('=== AUTH SERVICE: Azure AD Login ===');
        console.log('Azure token (first 50 chars):', azureToken?.substring(0, 50));
        console.log('Making request to:', `${this.apiUrl}/secure/user-details`);

        // In a real scenario, you would validate the Azure AD token with your backend
        // For now, we'll use it to generate a local token
        const headers = new HttpHeaders().set('Authorization', `Bearer ${azureToken}`);

        return this.http.get<any>(`${this.apiUrl}/secure/user-details`, { headers }).pipe(
            map(response => {
                console.log('=== BACKEND RESPONSE RECEIVED ===', response);
                
                const user: User = {
                    userId: response.userId || response.email,
                    email: response.email || 'unknown@example.com',
                    name: response.name || 'Unknown User',
                    roles: response.roles || [],
                    tenantId: response.tenantContext?.tenantId || response.tenantId || 'default'
                };

                console.log('=== USER OBJECT CREATED ===', user);
                
                localStorage.setItem(this.tokenKey, azureToken);
                console.log('=== TOKEN STORED ===');
                
                this.currentUserSubject.next(user);
                console.log('=== USER SUBJECT UPDATED ===');

                return user;
            }),
            catchError(error => {
                console.error('=== AZURE AD LOGIN ERROR ===', error);
                console.error('Error status:', error.status);
                console.error('Error message:', error.message);
                return throwError(() => new Error('Azure AD login failed.'));
            })
        );
    }

    logout(): void {
        localStorage.removeItem(this.tokenKey);
        this.currentUserSubject.next(null);
    }

    isAuthenticated(): boolean {
        return !!this.token && !this.isTokenExpired();
    }

    private isTokenExpired(): boolean {
        const token = this.token;
        if (!token) return true;

        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            const exp = payload.exp;
            return exp ? Date.now() >= exp * 1000 : false;
        } catch {
            return true;
        }
    }

    private decodeToken(token: string): User | null {
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            return {
                userId: payload.sub || payload.userId,
                email: payload.email,
                name: payload.name,
                roles: payload.role || [],
                tenantId: payload.tid || payload.tenantId
            };
        } catch {
            return null;
        }
    }

    getUserDetails(): Observable<any> {
        const token = this.token;

        // If no token, return an observable that immediately errors
        if (!token) {
            return throwError(() => new Error('No authentication token available'));
        }

        const headers = new HttpHeaders().set('Authorization', `Bearer ${token}`);

        return this.http.get(`${this.apiUrl}/secure/user-details`, { headers }).pipe(
            catchError(error => {
                console.error('Error fetching user details:', error);
                return throwError(() => error);
            })
        );
    }
}
