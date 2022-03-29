module.exports = {
    get: {
        description: "Get all stored XML data",
        operationId: "getData",
        parameters: [],
        responses: {
            200: {
                description: "XML data was obtained",
                content: {
                    "text/xml": {}
                }
            }
        }
    }
}