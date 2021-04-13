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

  // Eclypsium Configuration
  url: "https://demo-0124.eclypsium.cloud/api/v1",
  client_id: "3vs6DAjqZEqE3g",
  client_secret: "oKGTw3iv8GxzG0AakB_-RQ--ppcAmiTJYUhG6XJ6",
  ignoreLastRunTime: "true",
};

const outputWriter = (typeof context !== "undefined") ? context.OutputWriter.create("XML", {
  RootNode: "LNresults",
}) : null; // Used only for Write To Disk

/********************************************************/
/** DEBUGGING/TESTING SETTINGS
/********************************************************/
const testingModeTokens = {
  LastRunTime: "2018-06-13T18:31:41Z",
  PreviousRunContext: "",
};

const testingModeParams = {
  url: "https://demo-0124.eclypsium.cloud/api/v1",
  client_id: "3vs6DAjqZEqE3g",
  client_secret: "oKGTw3iv8GxzG0AakB_-RQ--ppcAmiTJYUhG6XJ6",
  ignoreLastRunTime: "true",
};

const xml2js = require("xml2js");
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
      Archer.callback(BuildMessageArray(), {
          output: null,
          previousRunContext: JSON.stringify(transportSettings.previousRunContext),
      });
  } else {
      LogInfo("Sending Complete to Archer.");
      Archer.callback(null, {
          output: null,
          previousRunContext: JSON.stringify(transportSettings.previousRunContext),
      });
  }
  return Promise.resolve(true);
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

class EclypsiumAPI {
  constructor(URL) {
      this.URL = URL;
      this.access_token = "";
      this.refresh_token = "";
  }

  restHeaders(needsAuth) {
      /* build general headers */
      const restHeaders = {
          "Content-Type": "application/json",
          "User-Agent": "Eclypsium API nodejs client",
      };

      if (needsAuth) {
          restHeaders.Authorization = "Bearer " + this.access_token;
      }

      return restHeaders;
  }

  AuthResponse(data) {
      const jObj = JSON.parse(JSON.stringify(data));
      /* get the access token and customer id*/
      this.access_token = jObj.access_token;
      this.refresh_token = jObj.refresh_token;
      return Promise.resolve(true);
  }

  /* This function autheticates to Eclypsium using username and password*/
  async authenticate(clientID, clientSecret) {
      LogInfo("Authenticating to Eclypsium Instance");
      const authPath = `${this.URL}/oauth/service/token`;
      /* build the authentication post body object */
      const authBody = {
          grant_type: "client_credentials",
          client_id: clientID,
          client_secret: clientSecret
      };

      const authHeader = this.restHeaders(false);
      const authOptions = {
          uri: authPath,
          method: "POST",
          headers: authHeader,
          body: authBody,
      };
      
      /* make the web call */
      return apif
          .webCall(authOptions)
          .then((authResponse) => this.AuthResponse(authResponse.body))
          .catch((authError) => {
              return Promise.reject(authError);
          });
  }

  async getIntegrityReport() {
      LogInfo("Requesting Eclypsium integrity report");
      const headers = this.restHeaders(true);
      const URI = `${this.URL}/report/device-integrity/json`;
      const options = {
          uri: URI,
          method: "POST",
          headers: headers
      };

      let result = await apif.webCall(options);
      result = JSON.parse(JSON.stringify(result.body));
      const cleanJSON = {
          records: []
      };
      result.Devices.data.forEach((device) => {
        cleanJSON.records.push({
            record: {
                hostname: device.hostname,
                customerId: device.customerId,
                integrityStatus: device.integrityAggregationStatus,
                passedIntegrityCheck: device.passedIntegrityCheck,
                lastScanDate: device.lastScanDate
            }});
      });
      
      const bldrOpts = {
        headless: true,
        renderOpts: {
            pretty: false,
            cdata: true
        },
    };
    
    result = new xml2js.Builder(bldrOpts).buildObject(cleanJSON);
    return result;
  }
}

/** ******************************************************/
/** DATAFEED BEGINS HERE
/********************************************************/

async function getEclypsiumData() {
  /* Create APIFramework Object */
  const APIFrameWorkConfig = {
      verifyCerts: transportSettings.verifyCerts.toLowerCase() === "true",
      requestsPerMinLimit: parseInt(transportSettings.requestsPerMin, 10),
      proxy: transportSettings.proxy,
  };
  apif = new APIFramework$1(APIFrameWorkConfig, transportSettings.debug);
  LogInfo("Datafeed Starting");
  /* Create Eclypsium Object */
  const ecapi = new EclypsiumAPI(transportSettings.url);

  return ecapi
      .authenticate(transportSettings.client_id, transportSettings.client_secret)
      .then(() => ecapi.getIntegrityReport())
      .catch((error) => {
          return Promise.reject(error);
      });
}

Init()
  .then(() => getEclypsiumData())
  .then(() => ReturnToArcher(false))
  .catch((error) => {
      CaptureError(error);
      ReturnToArcher(true);
  });