import { Component, OnInit, OnDestroy } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { interval, Subscription } from 'rxjs';
import { switchMap } from 'rxjs/operators';

interface LogEntry {
    timestamp: string;
    level: string;
    message: string;
    context?: {
        applicationId?: string;
        environment?: string;
        category?: string;
        eventId?: number;
        eventName?: string;
        requestId?: string;
        method?: string;
        path?: string;
        statusCode?: number;
        duration?: number;
    };
}

interface LogsResponse {
    logs: LogEntry[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
}

interface LogStats {
    totalLogs: number;
    byLevel: { [key: string]: number };
    byCategory: { [key: string]: number };
    recentErrors: LogEntry[];
}

@Component({
    selector: 'app-logs',
    templateUrl: './logs.component.html',
    styleUrls: ['./logs.component.css'],
    standalone: false
})
export class LogsComponent implements OnInit, OnDestroy {
    private apiUrl = 'http://localhost:5001/api/logs';

    logs: LogEntry[] = [];
    stats: LogStats = this.createEmptyStats();
    categories: string[] = [];

    // Pagination
    currentPage = 1;
    pageSize = 50;
    totalLogs = 0;
    totalPages = 0;

    // Filters
    selectedLevel: string = '';
    selectedCategory: string = '';
    searchText: string = '';
    startDate: string = '';
    endDate: string = '';

    // UI State
    loading = false;
    autoRefresh = true;
    refreshInterval = 5000; // 5 seconds
    expandedLogIndex: number | null = null;

    private refreshSubscription?: Subscription;

    constructor(private http: HttpClient) { }

    ngOnInit(): void {
        this.loadCategories();
        this.loadStats();
        this.loadLogs();
        this.startAutoRefresh();
    }

    ngOnDestroy(): void {
        this.stopAutoRefresh();
    }

    loadLogs(): void {
        this.loading = true;

        let params = new HttpParams()
            .set('page', this.currentPage.toString())
            .set('pageSize', this.pageSize.toString());

        if (this.selectedLevel) {
            params = params.set('level', this.selectedLevel);
        }

        if (this.selectedCategory) {
            params = params.set('category', this.selectedCategory);
        }

        if (this.searchText) {
            params = params.set('search', this.searchText);
        }

        if (this.startDate) {
            params = params.set('startDate', this.startDate);
        }

        if (this.endDate) {
            params = params.set('endDate', this.endDate);
        }

        this.http.get<LogsResponse>(this.apiUrl, { params }).subscribe({
            next: (response) => {
                this.logs = response.logs;
                this.totalLogs = response.total;
                this.totalPages = response.totalPages;
                this.loading = false;
            },
            error: (error) => {
                console.error('Error loading logs:', error);
                this.loading = false;
            }
        });
    }

    loadStats(): void {
        this.http.get<LogStats>(`${this.apiUrl}/stats`).subscribe({
            next: (stats) => {
                this.stats = stats ?? this.createEmptyStats();
            },
            error: (error) => {
                console.error('Error loading stats:', error);
                this.stats = this.createEmptyStats();
            }
        });
    }

    loadCategories(): void {
        this.http.get<string[]>(`${this.apiUrl}/categories`).subscribe({
            next: (categories) => {
                this.categories = categories;
            },
            error: (error) => {
                console.error('Error loading categories:', error);
            }
        });
    }

    applyFilters(): void {
        this.currentPage = 1;
        this.loadLogs();
        this.loadStats();
    }

    clearFilters(): void {
        this.selectedLevel = '';
        this.selectedCategory = '';
        this.searchText = '';
        this.startDate = '';
        this.endDate = '';
        this.currentPage = 1;
        this.loadLogs();
        this.loadStats();
    }

    changePage(page: number): void {
        if (page >= 1 && page <= this.totalPages) {
            this.currentPage = page;
            this.loadLogs();
        }
    }

    toggleAutoRefresh(): void {
        this.autoRefresh = !this.autoRefresh;
        if (this.autoRefresh) {
            this.startAutoRefresh();
        } else {
            this.stopAutoRefresh();
        }
    }

    startAutoRefresh(): void {
        if (this.autoRefresh) {
            this.refreshSubscription = interval(this.refreshInterval)
                .pipe(switchMap(() => this.http.get<LogsResponse>(this.apiUrl, {
                    params: this.buildParams()
                })))
                .subscribe({
                    next: (response) => {
                        this.logs = response.logs;
                        this.totalLogs = response.total;
                        this.totalPages = response.totalPages;
                    },
                    error: (error) => {
                        console.error('Auto-refresh error:', error);
                    }
                });
        }
    }

    stopAutoRefresh(): void {
        if (this.refreshSubscription) {
            this.refreshSubscription.unsubscribe();
        }
    }

    private createEmptyStats(): LogStats {
        return {
            totalLogs: 0,
            byLevel: {},
            byCategory: {},
            recentErrors: []
        };
    }

    private buildParams(): HttpParams {
        let params = new HttpParams()
            .set('page', this.currentPage.toString())
            .set('pageSize', this.pageSize.toString());

        if (this.selectedLevel) params = params.set('level', this.selectedLevel);
        if (this.selectedCategory) params = params.set('category', this.selectedCategory);
        if (this.searchText) params = params.set('search', this.searchText);
        if (this.startDate) params = params.set('startDate', this.startDate);
        if (this.endDate) params = params.set('endDate', this.endDate);

        return params;
    }

    clearLogs(): void {
        if (confirm('Are you sure you want to clear all logs? This action cannot be undone.')) {
            this.http.delete(`${this.apiUrl}`).subscribe({
                next: () => {
                    this.loadLogs();
                    this.loadStats();
                    alert('Logs cleared successfully');
                },
                error: (error) => {
                    console.error('Error clearing logs:', error);
                    alert('Failed to clear logs');
                }
            });
        }
    }

    toggleLogDetails(index: number): void {
        this.expandedLogIndex = this.expandedLogIndex === index ? null : index;
    }

    getLevelClass(level: string): string {
        const levelMap: { [key: string]: string } = {
            'DEBUG': 'level-debug',
            'INFO': 'level-info',
            'WARNING': 'level-warning',
            'ERROR': 'level-error',
            'CRITICAL': 'level-critical'
        };
        return levelMap[level] || 'level-default';
    }

    getLevelIcon(level: string): string {
        const iconMap: { [key: string]: string } = {
            'DEBUG': '🔍',
            'INFO': 'ℹ️',
            'WARNING': '⚠️',
            'ERROR': '❌',
            'CRITICAL': '🔥'
        };
        return iconMap[level] || '📝';
    }

    formatTimestamp(timestamp: string): string {
        return new Date(timestamp).toLocaleString();
    }

    exportLogs(): void {
        const dataStr = JSON.stringify(this.logs, null, 2);
        const dataBlob = new Blob([dataStr], { type: 'application/json' });
        const url = URL.createObjectURL(dataBlob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `logs-${new Date().toISOString()}.json`;
        link.click();
        URL.revokeObjectURL(url);
    }

    getPageNumbers(): number[] {
        const pages: number[] = [];
        const maxPages = 5;
        let startPage = Math.max(1, this.currentPage - Math.floor(maxPages / 2));
        let endPage = Math.min(this.totalPages, startPage + maxPages - 1);

        if (endPage - startPage < maxPages - 1) {
            startPage = Math.max(1, endPage - maxPages + 1);
        }

        for (let i = startPage; i <= endPage; i++) {
            pages.push(i);
        }

        return pages;
    }
}
