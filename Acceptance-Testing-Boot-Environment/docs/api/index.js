const ipxe = require('./ipxe');

module.exports = {
    paths: {
        '/boot.ipxe': {
            ...ipxe
        }
    }
}