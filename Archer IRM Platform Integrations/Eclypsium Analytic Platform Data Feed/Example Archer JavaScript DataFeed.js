//Themistocles.Chronis@rsa.com
// VERSION 2.0.0

/** ******************************************************/
/** GLOBAL VARS
/********************************************************/
const transportSettings = {
  testingMode: false,
  verifyCerts: "true",
  useProxy: false,
  proxy: "",
  dataSource: "JSTransportName",
  tokens: {},
  LastRunTime: new Date("1970-01-10T00:00:00Z"),
  runTime: new Date(),
  // below are from LexisNexis
  url: "",
  username: "",
  password: "",
  jurisdictions: "",
  ignoreLastRunTime: "true",
};

const outputWriter = context.OutputWriter.create("XML", {
  RootNode: "LNresults",
}); // Used only for Write To Disk

/** ******************************************************/
/** DEBUGGING/TESTING SETTINGS
/********************************************************/

const testingModeTokens = {
  LastRunTime: "2018-06-13T18:31:41Z",
  PreviousRunContext: "",
};

const testingModeParams = {
  url: "",
  username: "",
  password: "",
  jurisdictions: "",
  ignoreLastRunTime: "true",
};

// PRODUCTION BUILD

const xml2js = require("xml2js");
const xmldom = require("xmldom");
const request = require("request");

function pad(num, size) {
  let s = `${num}`;
  while (s.length < size) {
    s = `0${s}`;
  }
  return s;
}
function getDateTime() {
  const dt = new Date();
  return (
    `${pad(dt.getFullYear(), 4)}-` +
    `${pad(dt.getMonth() + 1, 2)}-` +
    `${pad(dt.getDate(), 2)} ` +
    `${pad(dt.getHours(), 2)}:` +
    `${pad(dt.getMinutes(), 2)}:` +
    `${pad(dt.getSeconds(), 2)}`
  );
}
function jsonToXMLString(json, rootElement = null) {
  const bldrOpts = {
    headless: true,
    rootName: rootElement,
    renderOpts: { pretty: true, indent: "    ", newline: "\r\n", cdata: true },
  };
  // can't pass null to the 3rd party lib
  if (!rootElement) {
    delete bldrOpts.rootName;
  }
  return new xml2js.Builder(bldrOpts).buildObject(json);
}
function jsonToString(json) {
  return JSON.stringify(json, null, 4);
}
function xmlStringToJSON(xml) {
  return new Promise((resolve, reject) => {
    function xmlStringToJSONcallBack(jserr, js) {
      if (jserr) {
        reject(jserr);
      } else {
        resolve(js);
      }
    }
    xml2js.parseString(xml, {}, xmlStringToJSONcallBack);
  });
}
function xmlStringToXmlDoc(xml) {
  const p = new xmldom.DOMParser();
  return p.parseFromString(xml);
}
function jsonArrayToXMLBuffer(jsonArray, elementName) {
  if (jsonArray === null) {
    return Buffer.from("");
  }
  /* holds the buffers */
  const buffers = [];
  /* convert each element to an xml buffer */
  for (let i = 0; i < jsonArray.length; i += 1) {
    /* convert it to xml */
    const xmlString = jsonToXMLString(jsonArray[i], elementName);
    /* convert it to a buffer */
    const b = Buffer.from(`${xmlString}\n`, "utf8");
    /* add to buffers array */
    buffers.push(b);
  }
  /* concat to one giant buffer */
  return Buffer.concat(buffers);
}

// json object to xml buffer
// will handle json objects that contain arrays.
function RecursiveJSObjectToXMLBuffer(jsObj) {
  const buffers = [];

  Object.keys(jsObj).forEach((key) => {
    if (Array.isArray(jsObj[key])) {
      // ARRAYS
      // add array opening node
      buffers.push(Buffer.from(`<${key}>\n`, "utf8"));
      // eslint-disable-next-line no-use-before-define
      buffers.push(
        RecursiveJSArrayToXMLBuffer(jsObj[key], key.slice(0, key.length - 1))
      );
      buffers.push(Buffer.from(`</${key}>\n`, "utf8"));
    } else if (typeof jsObj[key] === "object") {
      // OBJECTS
      buffers.push(Buffer.from(`<${key}>\n`, "utf8"));
      buffers.push(RecursiveJSObjectToXMLBuffer(jsObj[key]));
      buffers.push(Buffer.from(`</${key}>\n`, "utf8"));
    } else {
      // ALL ELSE
      // convert it to xml
      buffers.push(
        Buffer.from(`${jsonToXMLString(jsObj[key], key)}\n`, "utf8")
      );
    }
  });

  return Buffer.concat(buffers);
}

// array to xml buffer
// nodeName is the name of the outer node of the collection
function RecursiveJSArrayToXMLBuffer(jsArray, nodeName) {
  const buffers = [];
  for (let i = 0; i < jsArray.length; i += 1) {
    // if contents of array are another array or object
    if (Array.isArray(jsArray[i])) {
      buffers.push(Buffer.from(`</${nodeName}>`, "utf8"));
      // not supported.
      // What would the expectation be on the inner portion of a multidimensional array??
    } else if (typeof jsArray[i] === "object") {
      // it is a collection of objects, process this object
      buffers.push(Buffer.from(`<${nodeName}>`, "utf8"));
      buffers.push(RecursiveJSObjectToXMLBuffer(jsArray[i]));
      buffers.push(Buffer.from(`</${nodeName}>`, "utf8"));
    } else {
      // it was just an array of values
      buffers.push(
        Buffer.from(`${jsonToXMLString(jsArray[i], nodeName)}`, "utf8")
      );
    }
  }
  return Buffer.concat(buffers);
}

// function to clean the keys/property names for XML processing
// array of characters To Remove, replacement char, reference obj
function CleanKeys(charsToRemove, replaceChar, obj) {
  if (typeof obj !== "object") {
    return obj;
  }

  return Object.keys(obj).reduce((newObject, key) => {
    let newKey = key;
    let val = obj[key];
    charsToRemove.forEach((ctr) => {
      newKey = newKey.split(ctr).join(replaceChar);
    });

    if (Array.isArray(val)) {
      val = val.map((item) => CleanKeys(charsToRemove, replaceChar, item));
    } else if (val && typeof val === "object") {
      val = CleanKeys(charsToRemove, replaceChar, val);
    }
    const objectToAdd = { [newKey]: val };

    return Object.assign({}, newObject, objectToAdd);
  }, {});
}

// remove known bad characters from XML node names
// accepts an object as well as the replacement character
function CleanStringForXMLNodeName(obj, replaceChar) {
  if (typeof obj !== "object") {
    return obj;
  }
  const badChars = [
    /[\u0020-\u002C]|[\u002F]|[\u003A-\u0040]|[\u005B-\u005E]|[\u0060]|[\u007B-\u007E]|[\u00A0-\u00B6]|[\u00B8-\u00BF]|[\u00D7]|[\u00F7]/g,
  ];
  const result = CleanKeys(badChars, replaceChar, obj);
  return result;
}

// flatten object structure to reduce resulting xml node nesting
function FlattenObjects(obj, prevKey) {
  if (typeof obj !== "object") {
    return obj;
  }
  const flatObject = {};

  Object.keys(obj).forEach((key) => {
    let val = obj[key];
    if (Array.isArray(val)) {
      val = val.map((item) => FlattenObjects(item));
    } else if (typeof val === "object") {
      Object.assign(flatObject, FlattenObjects(obj[key], prevKey));
    } else {
      flatObject[`${prevKey}_${key}`] = obj[key];
    }
  });

  return flatObject;
}

// turn an object with many properties into an array of label, value objects
// useful when the object can contain dynamic node names for input into a subform
function CreateArrayOfKeyValuePairs(obj, newKey) {
  const keyValuePairs = {};
  keyValuePairs[newKey] = [];
  Object.keys(obj).forEach((key) => {
    const keyValuePair = { Label: key, Value: obj[key] };
    keyValuePairs[newKey].push(keyValuePair);
  });
  return keyValuePairs;
}

function decodeXML(text) {
  return text
    .replace(/&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&gt;/g, ">")
    .replace(/&lt;/g, "<")
    .replace(/&amp;/g, "&");
}

function UnixSecondsToDateTime(unixSeconds) {
  /* convert to date */
  const dt = new Date(unixSeconds * 1000);

  let hours = dt.getHours();
  let ampm = "AM";

  /* translate hours */
  if (hours > 12) {
    ampm = "PM";
    hours -= 12;
  }

  /* build the string */
  return `${pad(dt.getMonth() + 1, 2)}/${pad(dt.getDate(), 2)}/${pad(
    dt.getFullYear(),
    4
  )} ${pad(hours, 2)}:${pad(dt.getMinutes(), 2)} ${ampm}`;
}

function AddDays(date, days) {
  const dat = date;
  dat.setDate(date.getDate() + days);
  return dat;
}

function TrimChar(instring, searchSubstr, newSubstr = "") {
  if (instring.length < 2) {
    return instring;
  }

  const start = instring.slice(0, 1);
  const mid = instring.slice(1, -1);
  const end = instring.slice(-1);
  return (
    start.replace(searchSubstr, newSubstr) +
    mid +
    end.replace(searchSubstr, newSubstr)
  );
}

var Data = {
  pad,
  getDateTime,
  jsonToXMLString,
  jsonToString,
  xmlStringToJSON,
  xmlStringToXmlDoc,
  jsonArrayToXMLBuffer,
  RecursiveJSObjectToXMLBuffer,
  RecursiveJSArrayToXMLBuffer,
  CleanStringForXMLNodeName,
  CleanKeys,
  FlattenObjects,
  CreateArrayOfKeyValuePairs,
  decodeXML,
  UnixSecondsToDateTime,
  AddDays,
  TrimChar,
};

const { getDateTime: getDateTime$1 } = Data;

const messageLogMap = new Map();

function LogMessage(text, level) {
  let logMap = messageLogMap.get(level);
  if (!logMap) {
    logMap = messageLogMap.set(level, []).get(level);
  }
  logMap.push(text);
  if (logMap.length > 30 && level !== "ERROR") {
    logMap.splice(0, logMap.length - 30);
  }
  console.log(`${getDateTime$1()} :: ${level}  :: ${text}`);
}
function LogInfo(text) {
  LogMessage(text, "INFO");
}
function LogError(text) {
  LogMessage(text, "ERROR");
}
function LogWarn(text) {
  LogMessage(text, "WARN");
}

function BuildMessageArray() {
  if (messageLogMap.size > 0) {
    return [].concat(...[].concat(...Array.from(messageLogMap)));
  }
  return [];
}

function CaptureError(err) {
  if (err != null) {
    let { stack } = err;
    let { message } = err;
    if (!stack) {
      /* create a new error to get the stack */
      const e = new Error();
      ({ stack } = e);
    }
    if (typeof err === "string") {
      message = err;
    }
    /* create error string for array */
    const errString = `${message}\n${stack}`;
    /* add to error array */
    LogError(errString);
  }
}

var Logging = {
  LogMessage,
  LogInfo,
  LogError,
  LogWarn,
  messageLogMap,
  CaptureError,
  BuildMessageArray,
};

const { LogError: LogError$1, LogInfo: LogInfo$1 } = Logging;

// maintains a queue based prioritized call structure
// limits the concurrent number of calls
// also limits the call rate
class APIFramework {
  constructor(apiFrameWorkConfig, debug) {
    const queueConfig = Object.assign(
      {},
      APIFramework.DefaultConfig().queueConfig,
      apiFrameWorkConfig.queueConfig
    );
    this.params = Object.assign(
      {},
      APIFramework.DefaultConfig(),
      apiFrameWorkConfig
    );
    this.params.queueConfig = queueConfig;
    this.holdQueueMap = new Map();
    this.throttle = 0;
    this.stop = false;
    this.requestRamp = 0;
    this.intervalStartMS = new Date().getTime();
    this.intervalRequestCnt = 0;
    this.inCoolDown = false;
    this.debug = debug;

    this.baseRequest = request.defaults({
      forever: true,
      agentOptions: {
        keepAlive: true,
        keepAliveMsecs: 1000,
        maxSockets: this.params.socketLimit,
        maxFreeSockets: this.params.socketLimit,
      },
      pool: {
        maxSockets: this.params.socketLimit,
      },
      timeout: 120000,
    });
  }

  /**
   * This is the Default config applied upon instantiation.
   * DO NOT MODIFY
   * Use the APIFramework constructor to pass in a new config with new values
   *
   * @returns {object} That contains defaulted parameters.
   */
  static DefaultConfig() {
    return {
      queueConfig: {
        default: {
          key: "default",
          priority: 50,
        },
      },
      verifyCerts: true,
      concurrencyLimit: 10,
      socketLimit: 10,
      maxRetry: 1,
      retryCodes: ["ECONNRESET"],
      requestsPerMinLimit: 60,
      proxy: "",
    };
  }

  CreateQueueMap(queueKey) {
    let queueConfig = this.params.queueConfig.default;
    if (this.params.queueConfig[queueKey]) {
      queueConfig = this.params.queueConfig[queueKey];
    }

    return { requestItems: [], queueKey, queueConfig };
  }

  CreateRequestItem(queueKey, req, reqCallBack, retryCount) {
    const qmap = this.holdQueueMap.get(queueKey);
    if (retryCount && retryCount <= this.params.maxRetry) {
      qmap.requestItems.unshift({ req, reqCallBack, retryCount });
    } else {
      qmap.requestItems.push({ req, reqCallBack, retryCount: 0 });
    }

    return qmap;
  }

  QueueItem(queueKey, req, reqCallBack) {
    if (!this.holdQueueMap.get(queueKey)) {
      this.holdQueueMap.set(queueKey, this.CreateQueueMap(queueKey));
    }
    this.CreateRequestItem(queueKey, req, reqCallBack);
    if (
      this.throttle <= this.params.concurrencyLimit &&
      this.requestRamp <= 1
    ) {
      this.requestRamp += 1;
      this.ExecuteNext();
    }
  }

  async webCall(opt) {
    /* build options */
    const options = Object.assign(
      {
        rejectUnauthorized: this.params.verifyCerts,
      },
      opt
    );

    /* add in proxy */
    if (this.params.proxy && this.params.proxy !== "") {
      options.proxy = this.params.proxy;
    }

    /* make the request */
    return new Promise((resolve, reject) => {
      this.baseRequest(options, function handleResponse(err, response, body) {
        /* check for error */
        if (err) {
          let errorToCapture = `WEB CALL ERROR:         ${err} \n`;
          errorToCapture +=
            err.code === "ETIMEDOUT"
              ? `[${err.connect}] T-Connection Timeout, F-Read Timeout\n`
              : " ";
          errorToCapture += `WEB CALL ERROR HEADERS: ${JSON.stringify(
            options.headers
          )} \n WEB CALL ERROR BODY:    ${body}`;
          LogError$1(errorToCapture);
          return reject(err);
        }

        if (response.statusCode !== 200) {
          let errorMsg = `INVALID HTTP ERROR CODE RETURNED : ${response.statusCode}\n`;
          errorMsg += `ERROR HEADERS: ${JSON.stringify(options.headers)}\n`;
          errorMsg += `ERROR BODY:    ${body}`;
          LogError$1(errorMsg);
          return reject(response);
        }
        const resHeaders = response.headers ? response.headers : [];
        return resolve({ resHeaders, body });
      });
    });
  }

  static async delay(ms) {
    return new Promise((resolve) => {
      if (ms) {
        // try again after period of time
        setTimeout(() => resolve(), ms);
      } else {
        // try again on next event loop cycle
        setImmediate(() => resolve());
      }
    });
  }

  Stop(resolvePromises = true) {
    this.stop = true;
    this.holdQueueMap.forEach((qMap) => {
      while (qMap.requestItems.length > 0) {
        const r = qMap.requestItems.shift();
        if (resolvePromises) {
          r.reqCallBack(null, null);
        } else {
          r.reqCallBack(new Error("Stop Requested"));
        }
      }
    });
  }

  async GetNextItem() {
    while (this.throttle >= this.params.concurrencyLimit || this.inCoolDown) {
      if (this.stop) {
        return null;
      }
      // This is an exception
      // Recursion in this case would lead to a large memory hogging stack
      // eslint-disable-next-line no-await-in-loop
      await APIFramework.delay();
    }

    let queue = null;
    let highestPriority = Infinity; // highest number is least prioritized
    this.holdQueueMap.forEach((qMap) => {
      if (
        qMap.queueConfig.priority < highestPriority &&
        qMap.requestItems.length > 0
      ) {
        highestPriority = qMap.queueConfig.priority;
        queue = qMap;
      }
    });

    let item = null;
    if (queue) {
      this.throttle += 1;
      this.intervalRequestCnt += 1;
      item = queue.requestItems.shift(); // FIFO

      const coolDownMS = this.coolDownCheck();
      // check if we need to slow down.
      // only check for a slow down if we have something to do.
      if (coolDownMS > 0) {
        this.inCoolDown = true;
        // wait for a minimum of 1 sec
        if (this.debug) {
          LogInfo$1(`[APIF]   Cooling ${Math.max(coolDownMS, 1000)}`);
        }
        await APIFramework.delay(Math.max(coolDownMS, 1000));
        this.inCoolDown = false;
      }
    }

    return { item, queue };
  }

  coolDownCheck() {
    const nowMS = new Date().getTime();
    let elapsedMS = nowMS - this.intervalStartMS;
    if (this.debug) {
      LogInfo$1(`[APIF]   Elapsed Milliseconds ${elapsedMS}`);
    }
    // reset interval for rate calculation if we exceeded interval
    // calculations are based on one minute intervals
    if (elapsedMS > 60000) {
      this.intervalStartMS = new Date().getTime();
      this.intervalRequestCnt = 1; // the only way we got here is because we have something to do
      elapsedMS = 500; // default to half second to ensure no division by zero
      if (this.debug) {
        LogInfo$1(`[APIF]   Reset request interval`);
      }
    }
    const effectiveRatePerMin = this.intervalRequestCnt / (elapsedMS / 60000);

    // amount we need to slow down to stay within the requestsPerMinLimit threshold at our current effective rate
    // default to zero since negative numbers are useless
    // take the overage as a percentage of the elapsed time to get the amount to slow down
    return Math.max(
      (effectiveRatePerMin / this.params.requestsPerMinLimit - 1) * elapsedMS,
      0
    );
  }

  async queueRetry(reqMap) {
    await APIFramework.delay();
    this.CreateRequestItem(
      reqMap.queue.queueKey,
      reqMap.item.req,
      reqMap.item.reqCallBack,
      reqMap.item.retryCount + 1
    );
    this.ExecuteNext(); // keep the thread alive
  }

  async ExecuteNext() {
    const reqMap = await this.GetNextItem();

    if (!reqMap || !reqMap.item || !reqMap.item.req) {
      this.requestRamp = 0;
      return;
    }
    try {
      if (this.debug) {
        LogInfo$1(`[APIF]   Sending call`);
      }
      const p = reqMap.item.req();
      const data = await p;

      // trigger the next call
      // after response is received to avoid early returns in low volume situations
      this.ExecuteNext();

      this.throttle = Math.max(this.throttle - 1, 0); // ensure we don't ever go below zero
      if (this.debug) {
        LogInfo$1(`[APIF]   Returning data`);
      }
      reqMap.item.reqCallBack(null, data);
    } catch (error) {
      this.throttle = Math.max(this.throttle - 1, 0); // ensure we don't ever go below zero
      if (
        error.code &&
        this.params.retryCodes.includes(error.code.toUpperCase()) &&
        reqMap.item.retryCount < this.params.maxRetry
      ) {
        this.queueRetry(reqMap);
      } else if (
        error.statusCode &&
        this.params.retryCodes.includes(`${error.statusCode}`) &&
        reqMap.item.retryCount < this.params.maxRetry
      ) {
        this.queueRetry(reqMap);
      } else {
        this.requestRamp = 0;
        reqMap.item.reqCallBack(error);
        this.ExecuteNext();
      }
    }
  }

  /**
   * This is the entry point for the framework.  It adds a request to the queue.  options will overwrite config defaults.
   *
   * @param {string} queueKey The queue you want this request to go in to
   * @param {object} options uri(str),method(str),headers(obj),body(str),rejectUnauthorized(bool) See NPM Request module for details
   * @returns {object} That contains { resHeaders, body }
   */
  QueueWebCall(queueKey, options) {
    return new Promise((resolve, reject) => {
      // Store without calling
      this.QueueItem(
        queueKey,
        () => this.webCall(options),
        (error, data) => {
          if (error) {
            return reject(error);
          }
          return resolve(data);
        }
      );
    });
  }
}

var APIFramework_1 = { APIFramework };

const { jsonArrayToXMLBuffer: jsonArrayToXMLBuffer$1 } = Data;

const {
  LogError: LogError$2,
  LogInfo: LogInfo$2,
  LogWarn: LogWarn$1,
  CaptureError: CaptureError$1,
  BuildMessageArray: BuildMessageArray$1,
} = Logging;

const { APIFramework: APIFramework$1 } = APIFramework_1;

/** ******************************************************/
/** ARCHER CALLBACK INTERFACE
/********************************************************/
function getArcherObjects() {
  if (transportSettings.testingMode) {
    Object.assign(transportSettings, testingModeParams);
    transportSettings.tokens = testingModeTokens;
  } else {
    Object.assign(transportSettings, context.CustomParameters);
    transportSettings.tokens = context.Tokens;
  }
}

// let Archer know we are done. If no records are being returned then write an empty record so that the datafeed doesn't display a warning message in Archer
function ReturnToArcher(err) {
  if (
    outputWriter.IsNewFile &&
    outputWriter.fileHelper &&
    outputWriter.fileHelper.fileIndex &&
    outputWriter.fileHelper.fileIndex === 1
  ) {
    outputWriter.writeItem("");
  }
  if (err) {
    LogError$2("Datafeed Failure due to error.");
    callback(BuildMessageArray$1(), {
      output: null,
      previousRunContext: JSON.stringify(transportSettings.previousRunContext),
    });
  } else {
    LogInfo$2("Sending Complete to Archer.");
    callback(null, {
      output: null,
      previousRunContext: JSON.stringify(transportSettings.previousRunContext),
    });
  }
  return Promise.resolve(true);
}

let apif = null; // will be instantiated from init()

// write completed records to disk
function SendCompletedRecordsToArcher(data, callId) {
  return new Promise((resolve) => {
    // don't write empty data
    if (transportSettings.debug) {
      LogInfo$2(`[${callId}] Sending ${data.length} to Archer`);
    }
    if (data && data.length > 0) {
      const xmlData = jsonArrayToXMLBuffer$1(data, callId);
      outputWriter.writeItem(xmlData);
    }
    resolve(true);
  });
}

/** ******************************************************/
/** INIT
/********************************************************/
function Init() {
  return new Promise((resolve, reject) => {
    try {
      /* run the feed */
      LogInfo$2("Datafeed Init");
      /* check if testing mode should be active (no archer DFE present) */
      if (
        typeof context === "undefined" ||
        typeof context.CustomParameters === "undefined" ||
        Object.keys(context.CustomParameters).length === 0
      ) {
        LogWarn$1("Testing Mode Active");
        transportSettings.testingMode = true;
      }
      /* get params and tokens */
      getArcherObjects();

      /* setup cert verify. This is a failsafe to ensure that we do not verify certs */
      if (transportSettings.verifyCerts.toLowerCase() === "false") {
        process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
      }
      /* setup proxy */
      if (transportSettings.proxy != null && transportSettings.proxy !== "") {
        transportSettings.useProxy = true;
      }

      /* check for last run time */
      if (
        "LastRunTime" in transportSettings.tokens &&
        transportSettings.tokens.LastRunTime !== null &&
        transportSettings.tokens.LastRunTime !== ""
      ) {
        transportSettings.LastRunTime = new Date(
          transportSettings.tokens.LastRunTime
        );
      }
      LogInfo$2(
        `Last Datafeed Run Time: ${transportSettings.LastRunTime.toISOString()}`
      );
    } catch (error) {
      CaptureError$1(error.message);
      return reject(error);
    }
    return resolve(true);
  });
}

/** ******************************************************/
/** ******	LEXISNEXIS LIBRARY
/********************************************************/

class LexisNexisAPI {
  constructor(URL) {
    this.URL = URL;
    this.TOKEN = "";
    this.CUSTOMER_ID = "";
  }

  static restHeaders(addOverride) {
    /* build general headers */
    const restHeaders = {
      "Content-Type": "application/json",
      "User-Agent": "Lexis Nexis API NODE Client",
    };
    /* get override? */
    if (addOverride) {
      restHeaders["X-Http-Method-Override"] = "GET";
    }
    return restHeaders;
  }

  /* This function sets the Access Token and Customer ID from LexisNexis authetication response */
  AuthResponse(data) {
    const jObj = JSON.parse(data);
    /* get the access token and customer id*/
    this.TOKEN = jObj.token;
    this.CUSTOMER_ID = jObj.customer_id;
    return Promise.resolve(true);
  }

  /* This function autheticates to LexisNexis using username and password*/
  async authenticate(user, pass) {
    LogInfo$2("Authenticating to Lexis Nexis Instance");
    const authPath = `${this.URL}/rest/api/v1.1/authtoken?email=${user}&password=${pass}`;
    /* build the authentication post body object */
    const authBody = null;
    const authHeader = LexisNexisAPI.restHeaders(true);
    const authOptions = {
      uri: authPath,
      method: "GET",
      headers: authHeader,
      body: authBody,
    };
    /* make the web call */
    return apif
      .QueueWebCall("default", authOptions)
      .then((authResponse) => this.AuthResponse(authResponse.body))
      .catch((authError) => {
        return Promise.reject(authError);
      });
  }

  /** ******************************************************/
  /** GET SUBSCRIBED CONTENT
  /********************************************************/

  getContentsURI() {
    // CREATE CONTENTS URL
    let contentsURI = `${this.URL}/rest/api/v1.1/contents?token=${this.TOKEN}&customer_id=${this.CUSTOMER_ID}`;

    const ignorelastRunTime = transportSettings.ignoreLastRunTime;
    const jurisdiction = transportSettings.jurisdictions;

    // ignoreLastRunTime IS ONLY USED FOR DIFFERENTIAL DATA
    if (ignorelastRunTime.toLowerCase() !== "true") {
      const months = [
        "JAN",
        "FEB",
        "MAR",
        "APR",
        "MAY",
        "JUN",
        "JUL",
        "AUG",
        "SEP",
        "OCT",
        "NOV",
        "DEC",
      ];
      const fromdate =
        transportSettings.LastRunTime.getDate() +
        months[transportSettings.LastRunTime.getMonth()] +
        transportSettings.LastRunTime.getFullYear();
      contentsURI += `&from_date=${fromdate}`;
    }
    if (typeof jurisdiction !== "undefined" && jurisdiction !== "") {
      contentsURI += `&jurisdictions=${jurisdiction}`;
    }
    return contentsURI;
  }

  async getSubscribedContent() {
    // Default values
    let currentPage = 1;
    let isStopTriggered = false;

    /* build the Content headers and URL */
    const contheaders = LexisNexisAPI.restHeaders(true);
    const postBody = null;
    let contURI = this.getContentsURI();

    /* process muliples pages of content */
    while (!isStopTriggered) {
      LogInfo$2(`Collecting Page ${currentPage} Content Data from Lexis Nexis`);
      contURI = `${contURI}&page=${currentPage}`;
      const contOptions = {
        uri: contURI,
        method: "GET",
        headers: contheaders,
        body: postBody,
      };
      /* make the web call */
      // eslint-disable-next-line no-await-in-loop
      const webResult = await apif.QueueWebCall("default", contOptions);
      const data = JSON.parse(webResult.body);
      const contents = [];
      contents.push(data);
      // eslint-disable-next-line no-await-in-loop
      await SendCompletedRecordsToArcher(contents, "CONTENT");
      if (
        data.results &&
        (data.results.num_pages === 0 || data.results.num_pages === currentPage)
      ) {
        isStopTriggered = true;
      } else {
        currentPage += 1;
      }
    }
    return Promise.resolve(true);
  }
}

/** ******************************************************/
/** DATAFEED BEGINS HERE
/********************************************************/

async function getLexisNexisData() {
  /* Create APIFramework Object */
  const APIFrameWorkConfig = {
    verifyCerts: transportSettings.verifyCerts.toLowerCase() === "true",
    requestsPerMinLimit: parseInt(transportSettings.requestsPerMin, 10),
    proxy: transportSettings.proxy,
  };
  apif = new APIFramework$1(APIFrameWorkConfig, transportSettings.debug);
  LogInfo$2("Datafeed Starting");
  /* Create LexisNexisAPI Object */
  const lnapi = new LexisNexisAPI(transportSettings.url);

  return lnapi
    .authenticate(transportSettings.username, transportSettings.password) // authenticate to Lexis Nexis api
    .then(() => lnapi.getSubscribedContent()) // call to Lexis Nexis Subscribed Content api
    .catch((error) => {
      return Promise.reject(error);
    });
}

Init()
  .then(() => getLexisNexisData())
  .then(() => ReturnToArcher(false))
  .catch((error) => {
    CaptureError$1(error);
    ReturnToArcher(true);
  });

// SIG // Begin signature block
// SIG // MIIXtAYJKoZIhvcNAQcCoIIXpTCCF6ECAQExDzANBglg
// SIG // hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
// SIG // BgEEAYI3AgEeMCQCAQEEEBDgyQbOONQRoqMAEEvTUJAC
// SIG // AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
// SIG // Ppo4RkCn/uXay96elt1nU4jJEKMXVbJ3BkzSnU0AH8Cg
// SIG // ghK6MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8
// SIG // OzANBgkqhkiG9w0BAQUFADCBizELMAkGA1UEBhMCWkEx
// SIG // FTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIGA1UEBxML
// SIG // RHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsG
// SIG // A1UECxMUVGhhd3RlIENlcnRpZmljYXRpb24xHzAdBgNV
// SIG // BAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcgQ0EwHhcNMTIx
// SIG // MjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYD
// SIG // VQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9y
// SIG // YXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3Rh
// SIG // bXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZI
// SIG // hvcNAQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrY
// SIG // JXmRIlcqb9y4JsRDc2vCvy5QWvsUwnaOQwElQ7Sh4kX0
// SIG // 6Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
// SIG // i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+J
// SIG // zueZ5/6M4lc/PcaS3Er4ezPkeQr78HWIQZz/xQNRmarX
// SIG // bJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3+3R8
// SIG // J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrl
// SIG // Dqcsn6plINPYlujIfKVOSET/GeJEB5IL12iEgF1qeGRF
// SIG // zWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAdBgNVHQ4E
// SIG // FgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUH
// SIG // AQEEJjAkMCIGCCsGAQUFBzABhhZodHRwOi8vb2NzcC50
// SIG // aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYBAf8CAQAwPwYD
// SIG // VR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUu
// SIG // Y29tL1RoYXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNV
// SIG // HSUEDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCAQYw
// SIG // KAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFt
// SIG // cC0yMDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nv
// SIG // f1kwqu9otfrjCR27T4IGXTdfplKfFo3qHJIJRG71betY
// SIG // fDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
// SIG // 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq
// SIG // 3dlXPx13SYcqFgZepjhqIhKjURmDfrYwggSjMIIDi6AD
// SIG // AgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3DQEB
// SIG // BQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1h
// SIG // bnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50
// SIG // ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcy
// SIG // MB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVow
// SIG // YjELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVj
// SIG // IENvcnBvcmF0aW9uMTQwMgYDVQQDEytTeW1hbnRlYyBU
// SIG // aW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0
// SIG // MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
// SIG // omMLOUS4uyOnREm7Dv+h8GEKU5OwmNutLA9KxW7/hjxT
// SIG // VQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf
// SIG // 2Gi0jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh
// SIG // 3WPVF4kyW7BemVqonShQDhfultthO0VRHc8SVguSR/yr
// SIG // rvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
// SIG // d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsy
// SIG // i1aLM73ZY8hJnTrFxeozC9Lxoxv0i77Zs1eLO94Ep3oi
// SIG // siSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQABo4IB
// SIG // VzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAK
// SIG // BggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwcwYIKwYB
// SIG // BQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRwOi8vdHMt
// SIG // b2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKG
// SIG // K2h0dHA6Ly90cy1haWEud3Muc3ltYW50ZWMuY29tL3Rz
// SIG // cy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAxoC+gLYYraHR0
// SIG // cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNh
// SIG // LWcyLmNybDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQ
// SIG // VGltZVN0YW1wLTIwNDgtMjAdBgNVHQ4EFgQURsZpow5K
// SIG // FB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzM
// SIG // zHSa1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEB
// SIG // AHg7tJEqAEzwj2IwN3ijhCcHbxiy3iXcoNSUA6qGTiWf
// SIG // mkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
// SIG // BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1
// SIG // zSgEIKOq8UvEiCmRDoDREfzdXHZuT14ORUZBbg2w6jia
// SIG // sTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IWyhOB
// SIG // bQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4ax
// SIG // gohd8D20UaF5Mysue7ncIAkTcetqGVvP6KUwVyyJST+5
// SIG // z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUwggTSMIID
// SIG // uqADAgECAhBowaMHr0w++ZzIKhJ9jl4fMA0GCSqGSIb3
// SIG // DQEBCwUAMIGEMQswCQYDVQQGEwJVUzEdMBsGA1UEChMU
// SIG // U3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5
// SIG // bWFudGVjIFRydXN0IE5ldHdvcmsxNTAzBgNVBAMTLFN5
// SIG // bWFudGVjIENsYXNzIDMgU0hBMjU2IENvZGUgU2lnbmlu
// SIG // ZyBDQSAtIEcyMB4XDTE5MDIwMTAwMDAwMFoXDTIxMDEz
// SIG // MTIzNTk1OVowgYIxCzAJBgNVBAYTAnVzMRYwFAYDVQQI
// SIG // DA1NYXNzYWNodXNldHRzMRAwDgYDVQQHDAdCZWRmb3Jk
// SIG // MRkwFwYDVQQKDBBSU0EgU2VjdXJpdHkgTExDMRMwEQYD
// SIG // VQQLDApSU0EgQXJjaGVyMRkwFwYDVQQDDBBSU0EgU2Vj
// SIG // dXJpdHkgTExDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
// SIG // MIIBCgKCAQEArF+zGB8UNMiZXf9yz5/fzEIlFf/NyotC
// SIG // RhE9HBvO5bdbuVRlhJfrdt2PXlI0n0bXb5CULFQexF++
// SIG // 6S/HEz4QehP/WUdYhotlxVX8UZv6vit2OuYGTCv4Grw9
// SIG // 8WSNxeI5MB0lz5kzl2IWl3DgZQTSd/FYUehNRGiP0/cC
// SIG // ZBedgSQnV5MAERyQWhshxnEwz/NFaJOxDINYQBzwvRRD
// SIG // gBAbkG+9ixCzCi85Yz8yGRo68uL0zjkArxmPfOCFJ2Pr
// SIG // zbv6QQbAyLX36WlMq31m43lTT/1q/fgw6l0Ku+28EZiu
// SIG // +gdXAE/E/KMD1sJwiIb9XPABt+Xg1JIEdJLSYaywEVIO
// SIG // sQIDAQABo4IBPjCCATowCQYDVR0TBAIwADAOBgNVHQ8B
// SIG // Af8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwYQYD
// SIG // VR0gBFowWDBWBgZngQwBBAEwTDAjBggrBgEFBQcCARYX
// SIG // aHR0cHM6Ly9kLnN5bWNiLmNvbS9jcHMwJQYIKwYBBQUH
// SIG // AgIwGQwXaHR0cHM6Ly9kLnN5bWNiLmNvbS9ycGEwHwYD
// SIG // VR0jBBgwFoAU1MAGIknrOUvdk+JcobhHdglyA1gwKwYD
// SIG // VR0fBCQwIjAgoB6gHIYaaHR0cDovL3JiLnN5bWNiLmNv
// SIG // bS9yYi5jcmwwVwYIKwYBBQUHAQEESzBJMB8GCCsGAQUF
// SIG // BzABhhNodHRwOi8vcmIuc3ltY2QuY29tMCYGCCsGAQUF
// SIG // BzAChhpodHRwOi8vcmIuc3ltY2IuY29tL3JiLmNydDAN
// SIG // BgkqhkiG9w0BAQsFAAOCAQEAOsgHWRMiKP7JLfJj1akO
// SIG // lQpVEY9VxXFbVBlGsUdSUM0UI4/qb/3zKGDRbHV/PBXR
// SIG // O1LK+QlfOohZe0l7HKVF/z9W6UHQM1HhihDwBb8VEdVN
// SIG // t5Xv44dkzuoArcCe2+6fuFq50iQTQYYXMx2kHiJwdkFl
// SIG // XAFs8OrHLw7wXradkWkMFzLwhvFtmzbfr1IxI10/K55N
// SIG // 3jjhb/8/49rQ7e4xlUUgZGn+V1Qe3vFoA5jU1klVcJNl
// SIG // hAGgl8fONTLXzkKQ1rOtkyyZZmGjiusKBGLlbHZwkPCi
// SIG // 19D6sPcHj/bOJ4AcxeSA5XrzXcVzzY4VreIWhXTTfw7/
// SIG // Bu+/TyUgA3T23zCCBUcwggQvoAMCAQICEHwbNTVK59t0
// SIG // 50FfEWnKa6gwDQYJKoZIhvcNAQELBQAwgb0xCzAJBgNV
// SIG // BAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEf
// SIG // MB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6
// SIG // MDgGA1UECxMxKGMpIDIwMDggVmVyaVNpZ24sIEluYy4g
// SIG // LSBGb3IgYXV0aG9yaXplZCB1c2Ugb25seTE4MDYGA1UE
// SIG // AxMvVmVyaVNpZ24gVW5pdmVyc2FsIFJvb3QgQ2VydGlm
// SIG // aWNhdGlvbiBBdXRob3JpdHkwHhcNMTQwNzIyMDAwMDAw
// SIG // WhcNMjQwNzIxMjM1OTU5WjCBhDELMAkGA1UEBhMCVVMx
// SIG // HTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMR8w
// SIG // HQYDVQQLExZTeW1hbnRlYyBUcnVzdCBOZXR3b3JrMTUw
// SIG // MwYDVQQDEyxTeW1hbnRlYyBDbGFzcyAzIFNIQTI1NiBD
// SIG // b2RlIFNpZ25pbmcgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
// SIG // AQEBBQADggEPADCCAQoCggEBANeVQ9Tc32euOftSpLYm
// SIG // MQRw6beOWyq6N2k1lY+7wDDnhthzu9/r0XY/ilaO6y1L
// SIG // 8FcYTrGNpTPTC3Uj1Wp5J92j0/cOh2W13q0c8fU1tCJR
// SIG // ryKhwV1LkH/AWU6rnXmpAtceSbE7TYf+wnirv+9Srpyv
// SIG // CNk55ZpRPmlfMBBOcWNsWOHwIDMbD3S+W8sS4duMxICU
// SIG // crv2RZqewSUL+6McntimCXBx7MBHTI99w94Zzj7uBHKO
// SIG // F9P/8LIFMhlM07Acn/6leCBCcEGwJoxvAMg6ABFBekGw
// SIG // p4qRBKCZePR3tPNgKuZsUAS3FGD/DVH0qIuE/iHaXF59
// SIG // 9Sl5T7BEdG9tcv8CAwEAAaOCAXgwggF0MC4GCCsGAQUF
// SIG // BwEBBCIwIDAeBggrBgEFBQcwAYYSaHR0cDovL3Muc3lt
// SIG // Y2QuY29tMBIGA1UdEwEB/wQIMAYBAf8CAQAwZgYDVR0g
// SIG // BF8wXTBbBgtghkgBhvhFAQcXAzBMMCMGCCsGAQUFBwIB
// SIG // FhdodHRwczovL2Quc3ltY2IuY29tL2NwczAlBggrBgEF
// SIG // BQcCAjAZGhdodHRwczovL2Quc3ltY2IuY29tL3JwYTA2
// SIG // BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vcy5zeW1jYi5j
// SIG // b20vdW5pdmVyc2FsLXJvb3QuY3JsMBMGA1UdJQQMMAoG
// SIG // CCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIBBjApBgNVHREE
// SIG // IjAgpB4wHDEaMBgGA1UEAxMRU3ltYW50ZWNQS0ktMS03
// SIG // MjQwHQYDVR0OBBYEFNTABiJJ6zlL3ZPiXKG4R3YJcgNY
// SIG // MB8GA1UdIwQYMBaAFLZ3+mlIR59TEtXC6gcydgfRlwcZ
// SIG // MA0GCSqGSIb3DQEBCwUAA4IBAQB/68qn6ot2Qus+jiBU
// SIG // MOO3udz6SD4Wxw9FlRDNJ4ajZvMC7XH4qsJVl5Fwg/lS
// SIG // flJpPMnx4JRGgBi7odSkVqbzHQCR1YbzSIfgy8Q0aCBe
// SIG // tMv5Be2cr3BTJ7noPn5RoGlxi9xR7YA6JTKfRK9uQyjT
// SIG // IXW7l9iLi4z+qQRGBIX3FZxLEY3ELBf+1W5/muJWkvGW
// SIG // s60t+fTf2omZzrI4RMD3R3vKJbn6Kmgzm1By3qif1M0s
// SIG // CzS9izB4QOCNjicbkG8avggVgV3rL+JR51EeyXgp5x5l
// SIG // vzjvAUoBCSQOFsQUecFBNzTQPZFSlJ3haO8I8OJpnGdu
// SIG // kAsak3HUJgLDwFojMYIEUjCCBE4CAQEwgZkwgYQxCzAJ
// SIG // BgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jw
// SIG // b3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3Qg
// SIG // TmV0d29yazE1MDMGA1UEAxMsU3ltYW50ZWMgQ2xhc3Mg
// SIG // MyBTSEEyNTYgQ29kZSBTaWduaW5nIENBIC0gRzICEGjB
// SIG // owevTD75nMgqEn2OXh8wDQYJYIZIAWUDBAIBBQCgfDAQ
// SIG // BgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
// SIG // KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
// SIG // BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQglQjyxVWZRY46
// SIG // YH8+E9Rh9XZ83KzBho5YsZTnFmy1e+UwDQYJKoZIhvcN
// SIG // AQEBBQAEggEAcUiyy/BQgxPk+kUfD8cQstbdPyPJIjtK
// SIG // xhO15bKDJ9rr6VpI9/qRrZqWmN2ZTqS1TX0gzr6/+UEk
// SIG // +jycTwz5miJinTnNKRSJJrg4QSmkhwB6xU8Y+Qhwty5g
// SIG // CdHHLgeehDK069D1Jl0h3e/mAVqm+ZAJS+P8JmOTzhDx
// SIG // VHwoF8S7jGzXXIm/Xh4bhqHhT2/9n+eqGygdBVEpkHhr
// SIG // CNeW/lAyHxByq2J8PCGe8NW9mRtGQGO+nQTR5O8WLFe3
// SIG // /XeR1NGI4JKJKWeV7QYLAvT/A1aB/k4uECYp0wt6tdpr
// SIG // opLwE9E9l9BUesZTR0k1j0VY4dTUysl4Ur3O/DQf5Ut2
// SIG // dqGCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATBy
// SIG // MF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRl
// SIG // YyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMg
// SIG // VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAO
// SIG // z/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkq
// SIG // hkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJ
// SIG // BTEPFw0yMDExMTIwNjE2NTZaMCMGCSqGSIb3DQEJBDEW
// SIG // BBQ0RXBBZ8ShHUY4DO9KmM7za1zMcDANBgkqhkiG9w0B
// SIG // AQEFAASCAQAO1QW8BQ8MQRoeColWE31y4qtkvzWnOc35
// SIG // hbPtT+OWuHppnpWKeSHuE6D1biLrRCuqIyKGw0feKE1W
// SIG // 6IbmRn4jDMgTs/CVtpXMEbhiCQVyv+9oOZ43ssDV+VaD
// SIG // Vhj/UOQozS7W2K88e4SHQzGUdOjp+e10aAuBoreef/aK
// SIG // vug+V6J+8/qVX4oUWPkGPrCswbmUQf5ziYeXM4bQifcQ
// SIG // jqyGbAONN4gQ04xubHb0al8QNgrEIVnWG+i/8CebSBfI
// SIG // ZQRf22FYICEU94e/0PcmBzEuOD6Mmuip+08M5WFsFvzJ
// SIG // juHExuVBmjqjke2RhdE28seVO4usGYm5+cSbqlBciEYa
// SIG // End signature block