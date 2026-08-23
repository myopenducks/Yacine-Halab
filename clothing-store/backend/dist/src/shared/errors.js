export class AppError extends Error {
    code;
    statusCode;
    details;
    constructor(params) {
        super(params.message);
        this.name = 'AppError';
        this.code = params.code;
        this.statusCode = params.statusCode;
        this.details = params.details;
    }
}
export function isAppError(err) {
    return (typeof err === 'object' &&
        err !== null &&
        err.name === 'AppError' &&
        typeof err.code === 'string' &&
        typeof err.statusCode === 'number');
}
//# sourceMappingURL=errors.js.map