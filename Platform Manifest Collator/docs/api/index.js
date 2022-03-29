const getData = require('./get-data');
const uploadData = require('./upload-data');

module.exports = {
    paths: {
        '/api/data': {
            ...getData,
        },
        '/api/upload': {
            ...uploadData
        }
    }
}