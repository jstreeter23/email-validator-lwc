import { LightningElement, api } from 'lwc';
import validateEmail from '@salesforce/apex/EmailValidationController.validateEmail';
import SONOSIM_LOGO from '@salesforce/resourceUrl/sonosim_logo';

export default class EmailValidator extends LightningElement {
    @api recordId;
    emailInput = '';
    result = null;
    isLoading = false;
    errorMessage = '';
    
    sonosimLogo = SONOSIM_LOGO;

    get isValidateDisabled() {
        return !this.emailInput || this.isLoading;
    }

    get hasResult() {
        return this.result !== null && !this.isLoading;
    }

    get hasSuggestion() {
        return this.result?.suggestion && this.result.suggestion.length > 0;
    }

    get overallStatusClass() {
        const base = 'overall-status slds-p-around_small slds-m-top_small';
        return this.result?.isValid && !this.result?.isDisposable
            ? base + ' status-success'
            : base + ' status-warning';
    }

    get overallStatusIcon() {
        return this.result?.isValid && !this.result?.isDisposable
            ? 'utility:success'
            : 'utility:warning';
    }

    get overallStatusText() {
        if (!this.result?.isValid) return 'Invalid Email Address';
        if (this.result?.isDisposable) return 'Valid but Disposable Email';
        if (this.result?.isRoleBased) return 'Valid but Role-Based Email';
        return 'Valid Email Address';
    }

    get statusBadgeClass() {
        const base = 'slds-badge ';
        if (this.result?.status === 'VALID') return base + 'slds-theme_success';
        return base + 'slds-theme_error';
    }

    // Syntax/Format validation
    get syntaxCardClass() {
        return this.result?.syntaxValid ? 'result-card card-success' : 'result-card card-error';
    }

    get syntaxIcon() {
        return this.result?.syntaxValid ? 'utility:success' : 'utility:close';
    }

    // Domain exists
    get domainCardClass() {
        return this.result?.domainExists ? 'result-card card-success' : 'result-card card-error';
    }

    get domainIcon() {
        return this.result?.domainExists ? 'utility:success' : 'utility:close';
    }

    // MX Record
    get mxCardClass() {
        return this.result?.hasMxRecord ? 'result-card card-success' : 'result-card card-error';
    }

    get mxIcon() {
        return this.result?.hasMxRecord ? 'utility:success' : 'utility:close';
    }

    // Mailbox exists
    get mailboxCardClass() {
        return this.result?.mailboxExists ? 'result-card card-success' : 'result-card card-error';
    }

    get mailboxIcon() {
        return this.result?.mailboxExists ? 'utility:success' : 'utility:close';
    }

    // Disposable - warning if true (it's bad), success if false (it's good)
    get disposableCardClass() {
        return this.result?.isDisposable ? 'result-card card-warning' : 'result-card card-success';
    }

    get disposableIcon() {
        return this.result?.isDisposable ? 'utility:warning' : 'utility:success';
    }

    // Role-based - warning if true, success if false
    get roleBasedCardClass() {
        return this.result?.isRoleBased ? 'result-card card-warning' : 'result-card card-success';
    }

    get roleBasedIcon() {
        return this.result?.isRoleBased ? 'utility:warning' : 'utility:success';
    }

    handleEmailChange(event) {
        this.emailInput = event.target.value;
        this.errorMessage = '';
    }

    handleKeyUp(event) {
        if (event.key === 'Enter' && this.emailInput) {
            this.handleValidate();
        }
    }

    async handleValidate() {
        if (!this.emailInput) return;

        this.isLoading = true;
        this.errorMessage = '';
        this.result = null;

        try {
            this.result = await validateEmail({ email: this.emailInput });
            console.log('Full validation result:', JSON.stringify(this.result, null, 2));
            console.log('isValid type:', typeof this.result.isValid, 'value:', this.result.isValid);
        } catch (error) {
            console.error('Validation error:', error);
            // Handle different error formats
            if (error.body) {
                this.errorMessage = error.body.message || error.body.pageErrors?.[0]?.message || JSON.stringify(error.body);
            } else if (error.message) {
                this.errorMessage = error.message;
            } else {
                this.errorMessage = 'An error occurred during validation. Check browser console for details.';
            }
        } finally {
            this.isLoading = false;
        }
    }
}
