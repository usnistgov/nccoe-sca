module.exports = {
    components: {
        schemas: {
            APIErrorResponse: {
                type: "object",
                properties: {
                    success: {
                        type: "boolean",
                        description: "If the call was successful or not",
                        example: false
                    },
                    message: {
                        type: "string",
                        description: "Error message",
                        example: "Invalid request"
                    }
                }
            },
            APISuccessResponse: {
                type: "object",
                properties: {
                    success: {
                        type: "boolean",
                        description: "If the call was successful or not",
                        example: true
                    }
                }
            }
        }
    }
}