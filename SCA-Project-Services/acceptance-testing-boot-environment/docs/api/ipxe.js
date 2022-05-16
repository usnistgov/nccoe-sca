module.exports = {
    get: {
        description: "Get iPXE boot file",
        operationId: "getBootFile",
        parameters: [
            {
                in: "path",
                name: "manufacturer",
                schema: {
                    type: "string"
                },
                required: true,
                description: "URL-encoded manufacturer of the asset"
            },
            {
                in: "path",
                name: "product",
                schema: {
                    type: "string"
                },
                required: true,
                description: "URL-encoded product model"
            }
        ],
        requestBody: {
            schema: {
                type: "string"
            }
        },
        responses: {
            200: {
                description: "Boot file retrieved successfully"
            },
            400: {
                description: "Invalid request",
                content: {
                    "application/json": {
                        schema: {
                            $ref: "#components/schemas/APIErrorResponse"
                        }
                    }
                }
            },
            500: {
                description: "Internal server error",
                content: {
                    "application/json": {
                        schema: {
                            $ref: "#components/schemas/APIErrorResponse"
                        }
                    }
                }
            }
        }
    }
}