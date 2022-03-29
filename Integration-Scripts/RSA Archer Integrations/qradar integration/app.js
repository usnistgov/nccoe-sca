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

  // QRadar Configuration
  QRadarHostname: "",
  QRadarAPIKey: "",
  ignoreLastRunTime: "true"
};

const eventMapping = {
    "Custom Policy 1": "HP_Sure_Start Integrity violation",
    "Custom Policy 2": "HP_Sure_Start Policy violation",
    "Custom Policy 3": "HP_Sure_Start Recovery",
    "Custom Policy 4": "HP_Sure_start Revert to default",
    "Custom Policy 5": "Sys_Config Policy violation",
    "Custom Policy 6": "HP_Sure_Start Attack mitigation",
    "Custom Policy 7": "HP_Sure_Start SMM execution halted",
    "Custom Policy 8": "Secure_Platform Management Attack mitigation",
    "TBD": "HP_Sure_Recover Recovery initiated",
    "TBD": "HP_Sure_Recover Recovery success",
    "TBD": "HP_Sure_Recover Recovery failure",
    "TBD": "HP_Sure_Start Illegal DMA Blocked",
    "TBD": "HP_Sure_Admin Power off due to failure authentication",
    "TBD": "HP_Sure_Admin WMI blocked due to failed authentication",
    "TBD": "HP_Sure_Start EpSC execution halted",
    "TBD": "HP_TamperLock Cover removed",
    "TBD": "HP_TamperLock TPM cleared based on Policy",
    "Custom User Medium": "Dell Laptop DTD BIOS Violation"
}

const outputWriter = (typeof context !== "undefined") ? context.OutputWriter.create("XML", { RootNode: "offenses" }) : null; // Used only for Write To Disk
const output = [];

/********************************************************/
/** DEBUGGING/TESTING SETTINGS
/********************************************************/
const testingModeTokens = {
  LastRunTime: "2018-06-13T18:31:41Z",
  PreviousRunContext: "",
};

const testingModeParams = {
  url: "",
  client_id: "",
  client_secret: "",
  ignoreLastRunTime: "true",
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

var APIFramework_1 = {
  APIFramework
};

const {
  APIFramework: APIFramework$1
} = APIFramework_1;

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
      callback(output, {
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

class QRadarAPI {
  constructor(URL) {
      this.URL = URL;
  }

  restHeaders() {
      /* build general headers */
      const restHeaders = {
          "Content-Type": "application/json",
          "User-Agent": "QRadar API nodejs client",
          "SEC": transportSettings.QRadarAPIKey,
      };

      return restHeaders;
  }

  async getViolations() {
    LogInfo("Requesting QRadar device offenses");
    const headers = this.restHeaders();
    const URI = `${this.URL}/api/siem/offenses?fields=offense_source,last_updated_time,offense_type,description,categories,id&filter=status=OPEN`;
    const options = {
        uri: URI,
        method: "GET",
        headers: headers
    };

    let result = await apif.webCall(options);
    result = JSON.parse(JSON.stringify(result.body));
    let out = ''
    result.forEach((e) => {
        out += `<offense>
            <UUID>${e.offense_source}</UUID>
            <lastUpdate>${new Date(e.last_updated_time).toISOString()}</lastUpdate>
            <description>${e.description}</description>`
        e.categories.forEach((c) => {
            if (c in eventMapping) out += `<event>${eventMapping[c]}</event>`
        });
        out += `<id>${e.id}</id></offense>`
    })

    await SendCompletedRecordsToArcher(out, "CONTENT");
    return out;
  }
}

/** ******************************************************/
/** DATAFEED BEGINS HERE
/********************************************************/

async function getQRadarData() {
  /* Create APIFramework Object */
  const APIFrameWorkConfig = {
      verifyCerts: transportSettings.verifyCerts.toLowerCase() === "true",
      requestsPerMinLimit: parseInt(transportSettings.requestsPerMin, 10),
      proxy: transportSettings.proxy,
  };
  apif = new APIFramework$1(APIFrameWorkConfig, transportSettings.debug);
  LogInfo("Datafeed Starting");
  /* Create QRadar Object */
  const ecapi = new QRadarAPI(transportSettings.QRadarHostname);

  return ecapi
      .getViolations()
      .catch((error) => {
          return Promise.reject(error);
      });
}

Init()
  .then(() => getQRadarData())
  .then(() => ReturnToArcher(false))
  .catch((error) => {
      CaptureError(error);
      ReturnToArcher(true);
  });