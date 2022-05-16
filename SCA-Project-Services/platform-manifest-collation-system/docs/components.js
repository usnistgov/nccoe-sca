module.exports = {
    components: {
        schemas: {
            UploadRequest: {
                type: "object",
                properties: {
                    jsonFile: {
                        type: "string",
                        description: "XML input as either file or string",
                        example: ""
                    },
                    assetType: {
                        type: "string",
                        description: "Type of asset represented by the jsonFile",
                        example: "Dell"
                    },
                    UUID: {
                        type: "string",
                        description: "UUID, where not included in the translation",
                        example: "123e4567-e89b-12d3-a456-426614174000"
                    }
                }
            },
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