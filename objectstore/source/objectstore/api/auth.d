module objectstore.api.auth;

import vibe.vibe;
import std.algorithm : startsWith;

HTTPServerRequestDelegate authMiddleware(string authToken)
{
    return (HTTPServerRequest req, HTTPServerResponse res) {
        // Check Authorization header
        auto authHeader = req.headers.get("Authorization", "");
        
        if (authHeader.length == 0)
        {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody([
                "error": "Missing Authorization header",
                "message": "Please provide a valid Bearer token"
            ]);
            return;
        }
        
        // Extract token from "Bearer <token>"
        if (!authHeader.startsWith("Bearer "))
        {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody([
                "error": "Invalid Authorization header format",
                "message": "Use 'Bearer <token>' format"
            ]);
            return;
        }
        
        auto token = authHeader[7..$];
        
        if (token != authToken)
        {
            res.statusCode = HTTPStatus.unauthorized;
            res.writeJsonBody([
                "error": "Invalid token",
                "message": "The provided token is not valid"
            ]);
            return;
        }
        
        // Token is valid, continue to next handler
    };
}
