import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User } from '../../models/user.model';

@Component({
    selector: 'app-dashboard',
    templateUrl: './dashboard.component.html',
    styleUrls: ['./dashboard.component.css'],
    standalone: false
})
export class DashboardComponent implements OnInit {
    user: User | null = null;
    userDetails: any = null;
    loading = true;
    error = '';

    stats = [
        {
            title: 'Active Sessions',
            value: '1',
            icon: 'activity',
            color: '#667eea',
            trend: '+12%'
        },
        {
            title: 'API Calls',
            value: '2,847',
            icon: 'zap',
            color: '#f6ad55',
            trend: '+23%'
        },
        {
            title: 'Success Rate',
            value: '99.8%',
            icon: 'check-circle',
            color: '#48bb78',
            trend: '+0.2%'
        },
        {
            title: 'Avg Response',
            value: '124ms',
            icon: 'clock',
            color: '#4299e1',
            trend: '-8%'
        }
    ];

    recentActivities = [
        {
            action: 'User logged in',
            timestamp: new Date(),
            status: 'success'
        },
        {
            action: 'Token validated',
            timestamp: new Date(Date.now() - 5 * 60000),
            status: 'success'
        },
        {
            action: 'API request processed',
            timestamp: new Date(Date.now() - 15 * 60000),
            status: 'success'
        }
    ];

    constructor(
        private authService: AuthService,
        private router: Router
    ) { }

    ngOnInit(): void {
        console.log('=== DASHBOARD: ngOnInit ===');
        this.user = this.authService.currentUserValue;
        console.log('Current user from auth service:', this.user);

        // If we already have user data, show the dashboard immediately
        if (this.user) {
            this.loading = false;
            console.log('User exists, loading set to false immediately');
        }

        // Safety timeout - ensure loading never stays true forever
        setTimeout(() => {
            if (this.loading) {
                console.warn('=== DASHBOARD: Timeout - forcing loading to false ===');
                this.loading = false;
                if (!this.user) {
                    this.user = this.authService.currentUserValue;
                }
            }
        }, 5000);

        // Try to load additional details, but don't block the UI
        this.loadUserDetails();
    }

    loadUserDetails(): void {
        console.log('=== DASHBOARD: Loading user details ===');
        console.log('Current user:', this.user);
        console.log('Has token:', !!this.authService.token);
        
        // Don't show loading spinner if we already have basic user info
        if (!this.user) {
            this.loading = true;
        }

        this.authService.getUserDetails().subscribe({
            next: (details) => {
                console.log('=== DASHBOARD: User details received ===', details);
                this.userDetails = details;
                
                // Map the response correctly - use the actual property names
                this.user = {
                    userId: details.userId || details.email,
                    email: details.email || 'unknown@example.com',
                    name: details.name || 'Unknown User',
                    roles: details.roles || [],
                    tenantId: details.tenantContext?.tenantId || details.tenantId || 'default'
                };
                
                console.log('=== DASHBOARD: User object updated ===', this.user);
                this.loading = false;
                console.log('=== DASHBOARD: Loading set to false ===');
            },
            error: (error) => {
                console.error('=== DASHBOARD: Error loading user details ===', error);
                this.error = 'Failed to load user details';
                this.loading = false;

                // If we have basic user info from auth, use that
                if (!this.user) {
                    this.user = this.authService.currentUserValue;
                }
                
                console.log('=== DASHBOARD: Loading set to false (error case) ===');
            }
        });
    }

    logout(): void {
        this.authService.logout();
        this.router.navigate(['/login']);
    }

    getTimeOfDay(): string {
        const hour = new Date().getHours();
        if (hour < 12) return 'Good morning';
        if (hour < 18) return 'Good afternoon';
        return 'Good evening';
    }

    formatTimestamp(date: Date): string {
        const now = new Date();
        const diff = now.getTime() - date.getTime();
        const minutes = Math.floor(diff / 60000);

        if (minutes < 1) return 'Just now';
        if (minutes < 60) return `${minutes}m ago`;

        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours}h ago`;

        const days = Math.floor(hours / 24);
        return `${days}d ago`;
    }
}
