import { api, LightningElement } from "lwc";
import { getUrlQueryParams } from "c/utils";
import generateAuthorizationCode from "@salesforce/apex/PrivacyManager.auraGenerateAuthorizationCode";
import getAuthorizationStatus from "@salesforce/apex/PrivacyManager.auraGetAuthorizationStatus";
import getSnapshot from "@salesforce/apex/PrivacyManager.auraGetSnapshot";

export default class PrivacyConsole extends LightningElement {
    auth_code;
    error;
    loading = false;
    ref_id;
    snapshot;
    status;
    individualId;

    async authorizeCode() {
        try {
            this.loading = true;

            this.status = await getAuthorizationStatus({
                authCode: this.auth_code,
                refId: this.ref_id
            });

            if (this.status !== "VALID") {
                const input = this.template.querySelector("[data-id='auth_code']");

                input.setCustomValidity("Invalid code");
                input.reportValidity();

                return;
            }

            this.snapshot = JSON.parse(
                await getSnapshot({
                    payload: JSON.stringify({ referenceId: this.ref_id })
                })
            );
        } catch (error) {
            this.error = JSON.stringify(error);
        } finally {
            this.loading = false;
        }
    }

    @api get authorizationCode() {
        return this.auth_code;
    }

    set authorizationCode(value) {
        this.auth_code = value;
    }

    get authorized() {
        return this.status === "VALID" && this.snapshot;
    }

    connectedCallback() {
        if (this.connected) {
            return;
        }

        if (!this.ref_id) {
            const { ref_id, auth_code } = getUrlQueryParams(["ref_id", "auth_code"]);

            this.ref_id = ref_id;
            this.auth_code = auth_code;
        }

        if (!this.ref_id) {
            this.error = "Missing reference Id";
        } else if (!this.auth_code) {
            this.status = "ABSENT";

            this.generateCode();
        } else {
            this.authorizeCode();
        }

        this.connected = true;
    }

    generateCode(force = false) {
        this.loading = true;

        generateAuthorizationCode({ refId: this.ref_id, force })
            .catch((error) => {
                this.error = JSON.stringify(error);
            })
            .then(() => (this.loading = false));
    }

    generateNewCode() {
        this.generateCode(true);
    }

    handleInputCode(event) {
        this.auth_code = event.target.value;
    }

    handleSubmitCode() {
        const valid = this.template.querySelectorAll("lightning-input").reduce((flag, input) => {
            input.setCustomValidity("");

            return input.reportValidity() ? flag : false;
        }, true);

        if (valid) {
            this.authorizeCode();
        }
    }

    @api get referenceId() {
        return this.ref_id;
    }

    set referenceId(value) {
        this.ref_id = value;
    }

    get unauthorized() {
        return (
            this.status === "ABSENT" ||
            this.status === "EXPIRED" ||
            this.status === "INVALID" ||
            !this.status
        );
    }
}
