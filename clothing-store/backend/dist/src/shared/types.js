export function ok(data) {
    return { data, error: null };
}
export function fail(code, message, details) {
    return {
        data: null,
        error: { code, message, details },
    };
}
//# sourceMappingURL=types.js.map