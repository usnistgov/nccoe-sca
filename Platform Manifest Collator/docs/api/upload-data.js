module.exports = {
    post: {
        description: "Upload JSON file",
        operationId: "uploadJson",
        parameters: [],
        requestBody: {
            content: {
                "application/json": {
                    schema: {
                        $ref: "#/components/schemas/UploadRequest"
                    }
                }
            }
        },
        responses: {
            200: {
                description: "JSON uploaded and converted successfully",
                content: {
                    "application/json": {
                        schema: {
                            $ref: "#components/schemas/APISuccessResponse"
                        }
                    }
                }
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
            }
        }
    }
}