import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { MsalService } from '@azure/msal-angular';

@Component({
    selector: 'app-login',
    templateUrl: './login.component.html',
    styleUrls: ['./login.component.css'],
    standalone: false
})
export class LoginComponent implements OnInit {
    loginForm!: FormGroup;
    loading = false;
    submitted = false;
    error = '';
    returnUrl = '';
    activeTab: 'email' | 'azure' = 'email';

    constructor(
        private formBuilder: FormBuilder,
        private route: ActivatedRoute,
        private router: Router,
        private authService: AuthService,
        private msalService: MsalService
    ) { }

    ngOnInit(): void {
        // Initialize form
        this.loginForm = this.formBuilder.group({
            email: ['', [Validators.required, Validators.email]],
            password: ['', [Validators.required, Validators.minLength(6)]]
        });

        // Get return URL from route parameters or default to dashboard
        this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';

        // Redirect to dashboard if already logged in
        if (this.authService.isAuthenticated()) {
            this.router.navigate([this.returnUrl]);
        }
    }

    // Convenience getter for easy access to form fields
    get f() {
        return this.loginForm.controls;
    }

    switchTab(tab: 'email' | 'azure'): void {
        this.activeTab = tab;
        this.error = '';
        this.submitted = false;
    }

    onSubmit(): void {
        this.submitted = true;
        this.error = '';

        // Stop if form is invalid
        if (this.loginForm.invalid) {
            console.log('Form is invalid:', this.loginForm.errors);
            return;
        }

        this.loading = true;
        console.log('=== LOGIN COMPONENT: Submitting login ===');
        console.log('Email:', this.f['email'].value);
        console.log('Return URL:', this.returnUrl);

        this.authService.login(this.f['email'].value, this.f['password'].value)
            .subscribe({
                next: () => {
                    console.log('Login successful, navigating to:', this.returnUrl);
                    this.router.navigate([this.returnUrl]);
                },
                error: (error) => {
                    console.error('Login error:', error);
                    this.error = error.message || 'Login failed. Please check your credentials.';
                    this.loading = false;
                }
            });
    }

    loginWithAzureAd(): void {
        this.loading = true;
        this.error = '';
        console.log('=== LOGIN COMPONENT: Starting Azure AD login ===');

        this.msalService.loginPopup({
            scopes: ['api://32979413-dcc7-4efa-b8b2-47a7208be405/access_as_user']
        })
            .subscribe({
                next: (response) => {
                    console.log('Azure AD popup response:', response);
                    if (response && response.accessToken) {
                        console.log('Access token received, calling backend...');
                        console.log('Token (first 100 chars):', response.accessToken.substring(0, 100));
                        this.authService.loginWithAzureAd(response.accessToken)
                            .subscribe({
                                next: (user) => {
                                    console.log('Azure AD login successful, user:', user);
                                    console.log('Navigating to:', this.returnUrl);
                                    this.loading = false;
                                    this.router.navigate([this.returnUrl]).then(
                                        success => console.log('Navigation success:', success),
                                        error => console.error('Navigation error:', error)
                                    );
                                },
                                error: (error) => {
                                    console.error('Backend Azure AD authentication error:', error);
                                    this.error = 'Azure AD authentication failed.';
                                    this.loading = false;
                                }
                            });
                    } else {
                        console.warn('No access token in Azure AD response');
                        this.error = 'No access token received from Azure AD.';
                        this.loading = false;
                    }
                },
                error: (error) => {
                    this.error = 'Azure AD login failed. Please try again.';
                    this.loading = false;
                    console.error('Azure AD login popup error:', error);
                }
            });
    }
}
