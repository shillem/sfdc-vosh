export const aura = (framework, request) => {
    return new Promise((resolve, reject) => {
        try {
            if (request.params) {
                let params;

                if (request.jsonify) {
                    params = Object.keys(request.params).reduce((acc, key) => {
                        acc[key] = JSON.stringify(request.params[key]);

                        return acc;
                    }, {});
                } else {
                    params = request.params;
                }

                request.method.setParams(params);
            }

            request.method.setCallback(this, function (response) {
                if (response.getState() !== "SUCCESS") {
                    reject(response.getError());

                    return;
                }

                const payload = response.getReturnValue();

                resolve(request.jsonify ? JSON.parse(payload) : payload);
            });

            framework.enqueueAction(request.method);
        } catch (e) {
            reject(e);
        }
    });
};

export const extractErrorMessages = (error) => {
    if (typeof error === "string") {
        return [error];
    }

    if (Array.isArray(error)) {
        const sweep = (errors, acc) => {
            Object.values(errors).forEach((entries) => {
                entries.forEach(({ message }) => acc.push(message));
            });
        };

        return error.reduce((acc, { fieldErrors, message, pageErrors }) => {
            if (fieldErrors) {
                sweep(fieldErrors, acc);
            }

            if (message) {
                acc.push(message);
            }

            if (pageErrors) {
                sweep(pageErrors, acc);
            }

            return acc;
        }, []);
    }

    if (typeof error === "object" && error.message) {
        return [error.message];
    }

    return error;
};

export const getUrlQueryParam = (name, url = document.location) => {
    return new URL(url).searchParams.get(name);
};

export const getUrlQueryParams = (names, url = document.location) => {
    const params = new URL(url).searchParams;

    return names.reduce((acc, name) => {
        acc[name] = params.get(name);
        return acc;
    }, {});
};

export const untanglePageReference = ({ state: { inContextOfRef: base64 } }) => {
    return JSON.parse(window.atob(base64.startsWith("1.") ? base64.substring(2) : base64));
};

export const validate = (values, validateAll = false) => {
    let valid = true;

    values.forEach((input) => {
        if (!valid && !validateAll) {
            return;
        }

        if (input.reportValidity) {
            if (!input.reportValidity()) valid = false;

            return;
        }

        if (input.checkValidity) {
            if (input.checkValidity()) {
                return;
            }

            input.showHelpMessageIfInvalid();

            valid = false;
        }
    });

    return valid;
};
