const express = require('express');
const fs = require('fs');
const swaggerUI = require("swagger-ui-express");
const docs = require('./docs');

const app = express();
const port = process.env.PORT || 3001;

app.set('view engine', 'ejs');

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(docs));

// iPXE route
app.get('/boot.ipxe', (req, res) => {
    let { manufacturer, product } = req.query;
    let rawMappingData, mappingData;

    try {
        rawMappingData = fs.readFileSync('./iPXE/mapping.json');
        mappingData = JSON.parse(rawMappingData);
    } catch (_) {
        res.status(500).json({ success: false, message: "Failed to parse iPXE mapping data" });
        return;
    }
    

    if (!manufacturer || !product) {
        res.status(400).json({ success: false, message: "Both manufacturer and product are required" });
        return;
    }

    if (!(manufacturer in mappingData)) {
        res.send(getBootFile(mappingData['default']));
        return;
    }

    let currentManufacturer = mappingData[manufacturer];

    if (!(product in currentManufacturer)) {
        res.send(getBootFile(mappingData['default']));
    } else {
        res.send(getBootFile(currentManufacturer[product]));
    }
});

function getBootFile(fileName) {
    let fileData, globalConfig;

    try {
        fileData = fs.readFileSync('./iPXE/' + fileName);
        globalConfig = fs.readFileSync('./iPXE/boot.ipxe.cfg');
    } catch (_) {
        return null;
    }

    return globalConfig + fileData;
}

app.all('*', (req, res) => {
    res.status(404).json({ success: false, error: "Not found" });
});

app.listen(port, () => {
    console.log(`App is listening on port ${port}`);
});