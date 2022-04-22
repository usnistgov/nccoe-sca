const express = require('express');
const fs = require('fs');
const multer = require('multer');
const saxon = require('saxon-js');
const path = require('path');
const swaggerUI = require("swagger-ui-express");
const docs = require('./docs');

const app = express();
const config = JSON.parse(fs.readFileSync('config.json', 'utf8'));
const port = process.env.PORT || 3001;

const reversePairs = arr => arr.map((_, i) => arr[arr.length - i - 2 * (1 - i % 2)])
const xmlOutputDirectory = config.xmlOutputDirectory;

app.set('view engine', 'ejs');

app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(express.json( { limit: '50mb' } ));
app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(docs));
app.use((req, res, next) => {
    res.locals.query = req.query;
    res.locals.url = req.originalUrl;
    next();
});

// Setup disk storage
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, './uploads');
    },
    filename: function (req, file, cb) {
        cb(null, file.fieldname +  '-' + Date.now() + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage })

app.get('/', (req, res) => {
    const files = fs.readdirSync('./uploads');
    res.render('pages/home', { files: files, vendors: config.assetTypes });
});

app.get('/TSC', (req, res) => {
    const files = fs.readdirSync('./uploads');
    res.render('pages/intel', { files: files, vendors: config.assetTypes });
});
// Tested with curl via the following commands
//
// curl.exe -F "jsonFile=@.\Test Data\Intel DPD1.json" \ 
//  -F "type=Intel" http://localhost:3001/upload
//
// curl.exe -F "jsonFile=@.\Test Data\example allcomponents output.json"  \
// -F "type=HIRS" -F "UUID=06d4ada1-4972-465d-ad6b-5ecc61ad1388" \ 
// http://localhost:3001/api/upload
app.post('/api/upload', upload.single('jsonFile'), (req, res) => {
    let convertedXML = "";

    const isWebUI = (req.body.webUI !== undefined);
    const assetType = req.body.type;
    const jsonString = (req.file !== undefined) ? fs.readFileSync(path.join(__dirname, req.file.path), "utf-8") : req.body.jsonFile;
    const assetName = config.assetTypes[assetType];

    if (req.file == undefined) {
        fs.writeFileSync('uploads/jsonFile-' + Date.now() + '.json', jsonString);
    }

    if (!assetName) {
        if (isWebUI)
            res.redirect('/?error=true');
        else
            res.status(400).json({ success: false, message: "Invalid asset type" });
        return;
    }

    if (config.assetTypesUUIDFromUser.includes(assetType))
        convertedXML = convertToXML(jsonString, assetType, req.body.UUID);
    else
        convertedXML = convertToXML(jsonString, assetType);

    if (convertedXML == null) {
        res.status(400).json({ success: false, message: "Invalid JSON" });
        return;
    }

    saveToFile(convertedXML, assetType);
    if (isWebUI)
        res.redirect('/?success=true');
    else
        res.json({ success: true });
});

// Support for Intel server TSCVerifyUtil (linux) and the Intel GUI AutoVerifyTool (windows laptop) 
// which does not support JSON output
 
app.post('/api/uploadXML', upload.single('XMLFile'), (req, res) => {
    let convertedXML = "";

    const isWebUI = (req.body.webUI !== undefined);
    const assetType = req.body.type;
    const xmlString = (req.file !== undefined) ? fs.readFileSync(path.join(__dirname, req.file.path), "utf-8") : req.body.XMLFile;
    const assetName = config.assetTypes[assetType];

    if (req.file == undefined) {
        fs.writeFileSync('uploads/xmlFile-' + Date.now() + '.xml', xmlString);
    }

    if (!assetName) {
        if (isWebUI)
            res.redirect('/?error=true');
        else
            res.status(400).json({ success: false, message: "Invalid asset type" });
        return;
    }

    if (config.assetTypesUUIDFromUser.includes(assetType))
        convertedXML = convertXMLToXML(xmlString, assetType, req.body.UUID);
    else
        convertedXML = convertXMLToXML(xmlString, assetType);

    if (convertedXML == null) {
        res.status(400).json({ success: false, message: "Invalid XML" });
        return;
    }

    saveToFile(convertedXML, assetType);
    if (isWebUI)
        res.redirect('/?success=true');
    else
        res.json({ success: true });
});

function saveToFile(assetXML, type) {
    fs.writeFileSync(xmlOutputDirectory + "/" + type.toLowerCase() + "-" + Date.now() + ".xml", assetXML);
}

function convertXMLToXML(xmlAssetString, type, UUID) {
    let contents, output, assetXML;
    const stylesheetPath = `data/${type.toLowerCase()}.asset.sef.json`;

    //TODO: Check XML Validation
    
    if (config.assetTypesUUIDFromUser.includes(type)) {
        try {
            output = saxon.transform({
                stylesheetFileName: stylesheetPath,
                stylesheetParams: {
                    "UUID": UUID
                },
                sourceText: "<record>" + xmlAssetString + "</record>",
                destination: "serialized"
            }, "sync");
        } catch (e) {
            return null;
        }
    } else {
        try {
            output = saxon.transform({
                stylesheetFileName: stylesheetPath,        
                sourceText: "<record>" + xmlAssetString + "</record>",
                destination: "serialized"
            }, "sync");
        } catch (e) {
            return null;
        }
    }

    return output.principalResult;


}
function convertToXML(jsonAssetString, type, UUID) {
    let contents, output, assetJSON;
    const stylesheetPath = `data/${type.toLowerCase()}.asset.sef.json`;

    try {
        contents = JSON.parse(jsonAssetString);
    } catch (e) {
        console.log("Failed to parse JSON");
        console.log("JSON string: " + jsonAssetString);
        return null;
    }

    if (type == "Intel") {
        delete contents['_rev='];
        let currentUUIDChunks = contents.TYPE1System.UUID.split("-");
        currentUUIDChunks[0] = reversePairs(currentUUIDChunks[0].split('')).join('');
        currentUUIDChunks[1] = reversePairs(currentUUIDChunks[1].split('')).join('');
        currentUUIDChunks[2] = reversePairs(currentUUIDChunks[2].split('')).join('');
        contents.TYPE1System.UUID = currentUUIDChunks.join('-');
    }
    
    assetJSON = JSON.stringify(contents);

    /* Couldn't figure out the async version */
    
    if (config.assetTypesUUIDFromUser.includes(type)) {
        try {
            output = saxon.transform({
                stylesheetFileName: stylesheetPath,
                stylesheetParams: {
                    "UUID": UUID
                },
                sourceText: "<record>" + assetJSON + "</record>",
                destination: "serialized"
            }, "sync");
        } catch (e) {
            return null;
        }
    } else {
        try {
            output = saxon.transform({
                stylesheetFileName: stylesheetPath,        
                sourceText: "<record>" + assetJSON + "</record>",
                destination: "serialized"
            }, "sync");
        } catch (e) {
            return null;
        }
    }

    return output.principalResult;
}

// Entry point for Archer JS DataFeed. Expects "lastrun"
// parameter which is the last time the datafeed ran. Returns
// newer records.
// Tested with:
//
// curl.exe http://localhost:3001/api/data?lastrun=1609978679
app.get('/api/data', (req, res) => {
    let files;
    const filter = req.query.filter;

    try {
        files = fs.readdirSync(xmlOutputDirectory);
    } catch (e) {
        res.json({ success: false, error: e.message });
        return;
    }

    let currentFile, parsedFilename, assetCreatedDate;
    let lastRunDateFromArcher = (req.query.lastrun !== undefined) ? new Date(req.query.lastrun) : null;
    let recordsOutput = "";

    console.log(`Last run date: ${lastRunDateFromArcher}`);

    for (currentFile of files) {
        if (!currentFile.endsWith('.xml')) continue;
        
        parsedFilename = currentFile.split("-");
        assetCreatedDate = new Date(parseInt(parsedFilename[1].split('.')[0]));

        if (filter !== undefined && filter !== "" && filter.toLowerCase() !== parsedFilename[0]) continue;
        
        // if the file is newer than when the last time the 
        // Archer JS datafeed ran ...
        if (lastRunDateFromArcher === null || lastRunDateFromArcher < assetCreatedDate) {
            console.log(currentFile + " newer than last Archer run date");
            recordsOutput += fs.readFileSync(`${xmlOutputDirectory}/${currentFile}`, 'utf8');
        }
    }
   
    res.set('Content-Type', 'text/xml');
    res.send(recordsOutput);
});

app.all('*', (req, res) => {
    res.status(404).json({ success: false, error: "Not found" });
});

app.listen(port, () => {
    console.log(`App is listening on port ${port}`);
});