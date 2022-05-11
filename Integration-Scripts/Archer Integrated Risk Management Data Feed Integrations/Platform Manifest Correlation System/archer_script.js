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
    LastRunTime: "2022-01-10T00:00:00Z",
    runTime: new Date(),
  
    // API configuration
    url: "",
  };
  
  const outputWriter = (typeof context !== "undefined") ? context.OutputWriter.create("XML", { RootNode: "results" }) : null; // Used only for Write To Disk
  const output = [];
  
  /********************************************************/
  /** DEBUGGING/TESTING SETTINGS
  /********************************************************/
  const testingModeTokens = {
    LastRunTime: "2021-04-13T18:31:41Z",
    PreviousRunContext: "",
  };
  
  const testingModeParams = {
    url: transportSettings.url
  };
  
  const request = require("request");
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
    console.log(`${level}  :: ${text}`);
    output.push(`${level}  :: ${text}`);
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
  
  function CaptureError(err) {
    if (err != null) {
        let {
            stack
        } = err;
        let {
            message
        } = err;
        if (!stack) {
            /* create a new error to get the stack */
            const e = new Error();
            ({
                stack
            } = e);
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
  
  // maintains a queue based prioritized call structure
  // limits the concurrent number of calls
  // also limits the call rate
  class APIFramework {
    constructor(apiFrameWorkConfig, debug) {
        const queueConfig = Object.assign({},
            APIFramework.DefaultConfig().queueConfig,
            apiFrameWorkConfig.queueConfig
        );
  
        this.params = Object.assign({},
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
            json: true,
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
  
    async webCall(opt) {
        /* build options */
        const options = Object.assign({
                rejectUnauthorized: this.params.verifyCerts,
            },
            opt
        );
  
        /* make the request */
        return new Promise((resolve, reject) => {
            this.baseRequest(options, function handleResponse(err, response, body) {
                /* check for error */
                if (err) {
                    let errorToCapture = `WEB CALL ERROR:         ${err} \n`;
                    errorToCapture +=
                        err.code === "ETIMEDOUT" ?
                        `[${err.connect}] T-Connection Timeout, F-Read Timeout\n` :
                        " ";
                    errorToCapture += `WEB CALL ERROR HEADERS: ${JSON.stringify(
              options.headers
            )} \n WEB CALL ERROR BODY:    ${body}`;
                    LogError(errorToCapture);
                    return reject(err);
                }
  
                if (response.statusCode !== 200) {
                    let errorMsg = `INVALID HTTP ERROR CODE RETURNED : ${response.statusCode}\n`;
                    errorMsg += `ERROR HEADERS: ${JSON.stringify(options.headers)}\n`;
                    errorMsg += `ERROR BODY:    ${body}`;
                    LogError(errorMsg);
                    return reject(response);
                }
                const resHeaders = response.headers ? response.headers : [];
                return resolve({
                    resHeaders,
                    body
                });
            });
        });
    }
  }
  
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
        outputWriter !== null &&
        outputWriter.IsNewFile &&
        outputWriter.fileHelper &&
        outputWriter.fileHelper.fileIndex &&
        outputWriter.fileHelper.fileIndex === 1
    ) {
        outputWriter.writeItem("");
    }
    if (err) {
        LogError("Datafeed Failure due to error.");
        callback(null, {
            output: null,
            previousRunContext: JSON.stringify(transportSettings.previousRunContext),
        });
    } else {
        LogInfo("Sending Complete to Archer.");
        callback(null, {
            output: null,
            previousRunContext: JSON.stringify(transportSettings.previousRunContext),
        });
    }
    return Promise.resolve(true);
  }
  
  // write completed records to disk
  function SendCompletedRecordsToArcher(data, callId) {
      return new Promise((resolve) => {
        // don't write empty data
        if (transportSettings.debug) {
          LogInfo(`[${callId}] Sending ${data.length} to Archer`);
        }
        if (outputWriter !== null && data && data.length > 0) {
          outputWriter.writeItem(data);
        }
        resolve(true);
      });
    }
  
  let apif = null; // will be instantiated from init()
  
  /** ******************************************************/
  /** INIT
  /********************************************************/
  function Init() {
    return new Promise((resolve, reject) => {
        try {
            /* run the feed */
            LogInfo("Datafeed Init");
            /* check if testing mode should be active (no archer DFE present) */
            if (
                typeof context === "undefined" ||
                typeof context.CustomParameters === "undefined" ||
                Object.keys(context.CustomParameters).length === 0
            ) {
                LogWarn("Testing Mode Active");
                transportSettings.testingMode = true;
            }
            /* get params and tokens */
            getArcherObjects();
  
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
            LogInfo(
                `Last Datafeed Run Time: ${transportSettings.LastRunTime.toISOString()}`
            );
        } catch (error) {
            CaptureError(error.message);
            return reject(error);
        }
        return resolve(true);
    });
  }
  
  /** ******************************************************/
  /** DATAFEED BEGINS HERE
  /********************************************************/
  
  async function getDeviceData() {
    const requestOptions = {
        uri: `${transportSettings.url}/api/data/?lastrun=${transportSettings.LastRunTime}&filter=${transportSettings.filter}`,
        method: "GET",
    };

    LogInfo(`Filter: ${transportSettings.filter}`);
    apif = new APIFramework({}, transportSettings.debug);
    const result = await apif.webCall(requestOptions);
    const cleanedData = result.body.replace(/\n|\s+(?=<)/g, '');
    SendCompletedRecordsToArcher(cleanedData);
  }
  
  Init()
    .then(() => getDeviceData())
    .then(() => ReturnToArcher(false))
    .catch((error) => {
        CaptureError(error);
        ReturnToArcher(true);
    });