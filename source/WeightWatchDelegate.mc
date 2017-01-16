using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

class WeightWatchDelegate extends Ui.BehaviorDelegate {
	const OAUTH2_AUTHORIZATION_URI = "https://www.fitbit.com/oauth2/authorize";
	const OAUTH2_ACCESS_URL = "https://api.fitbit.com/oauth2/token";
	const REDIRECT_URI = "https://localhost/weightwatch/callback";
    var notify;
	var accessToken;
	var refreshToken;

	function initialize(handler) {
        Ui.BehaviorDelegate.initialize();
        notify = handler;
		Comm.registerForOAuthMessages(method(:handleOAuthValue));
		//! If no access_token is available, authorize
	    authorize();
 	}

    function onMenu() {
        return true;
    }

    function onSelect() {
        return true;
    }

	//! Get an authorization code from Fitbit
	function authorize() {
		System.println("Getting the authorization code...");
       	var reqUrl = OAUTH2_AUTHORIZATION_URI;
       	var requestParams = {
	    	"client_id"=>$.clientId,
           	"response_type"=>"code",
           	"scope"=>"weight",
           	"state"=>"gyarados",
           	"redirect_uri"=>REDIRECT_URI
       	};
       	var redirectUrl = REDIRECT_URI;
       	var resultType = Comm.OAUTH_RESULT_TYPE_URL;
       	var resultKeys = {"code"=>"auth_code"};

       	Comm.makeOAuthRequest(
			reqUrl,
			requestParams,
           	redirectUrl,
           	resultType,
           	resultKeys
    	);
    }

	//! Callback for the authorize
	function handleOAuthValue(response) {
		if( response.data != null) {
            //! Extract the access code from the JSON response
            var authCode = response.data["auth_code"];
            System.println("authCode: " +authCode);
            getAccessToken(authCode);
        }
        else {
            System.println("Error in accessCodeResult");
            System.println("response = " + response);
        }
	}

	//! Convert the authorization code to a access token
	function getAccessToken(authCode) {
		System.println("Get access token by using the auth code: " +authCode);
        var headers = {
	  		"Authorization"=>"Basic sajKDSnfdskjksadkjkjsad2343kjdaskdjsfdsjkfd",
	  		"Content-Type"=>Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
		};
		var reqUrl = OAUTH2_ACCESS_URL;
		var requestParameters = {
            "client_id"=>$.clientId,
            "client_secret"=>$.clientSecret,
            "code"=>authCode,
            "grant_type"=>"authorization_code",
            "redirect_uri"=>REDIRECT_URI,
            "state"=>"gyarados"
		};
        Comm.makeWebRequest(
           	reqUrl,
           	requestParameters,
            {
            	:headers => headers,
                :method => Comm.HTTP_REQUEST_METHOD_POST
            },
            //! Callback to handle response
            method(:handleAccessResponse)
        );
	}

	function handleAccessResponse(responseCode, data) {
		System.println("handleAccessResponse(), responseCode: " +responseCode +", with the obtained access token: " +data);
	     //! If we got data back then we were successful. Otherwise pass the error onto the function
        if( data != null) {
            handleResponse(data);
        } else {
            System.println("Error in handleAccessResponse");
            System.println("data = " + data);
            handleError(responseCode);
        }
	}

	//! Handle a error from the server
    function handleError(code) {
    	System.println("handleError(): " +code);
    }

    //! Handle a successful response from the server
    function handleResponse(data) {
    		System.println("handleResponse(): " +data);
      	accessToken = data["access_token"];
    		refreshToken = data["refresh_token"];
        //! Store the access and refresh tokens in properties
        //! For app store apps the properties are encrypted using a randomly generated key
        App.getApp().setProperty("refresh_token", refreshToken);
        App.getApp().setProperty("access_token", accessToken);
        makeRequest(accessToken);
    }

	//! Get the current date string formatted to enable restricting the time frame for which the data is fetched.
	function getCurrDate() {
		var nowInfo = Calendar.info(Time.now(), Time.FORMAT_SHORT);
		var year = nowInfo.year;
		var month = nowInfo.month;
		var day = nowInfo.day;
		if (nowInfo.month < 10) {
			month = 0 + nowInfo.month.toString();
		}
		if (nowInfo.day < 10) {
			day = 0 + nowInfo.day.toString();
		}

		var currentDateStr = year +"-" +month +"-" +day;
		System.println("Now: " +currentDateStr);

		return currentDateStr;
	}

	//! -------------- FITBIT -------------------
	//! Send a request for the current weight (@Fitbit API).
    function makeRequest(accessToken) {
    	//! GET https://api.fitbit.com/1/user/[user-id]/body/log/weight/date/[date].json
    	//! GET https://api.fitbit.com/1/user/[user-id]/body/log/weight/date/[base-date]/[period].json
    	System.println("makeRequest() with the accessToken " +accessToken);

    	//! Get the data for the current date and the previous seven ones.
    	var currentDate = getCurrDate();
	  	var url = "https://api.fitbit.com/1/user/-/body/log/weight/date/" +currentDate +"/7d" +".json";
		var headers = {
			"Authorization" => "Bearer " +accessToken,
			"Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED,
			"Accept" => "application/json"
		};

		var options = {
		  :method => Comm.HTTP_REQUEST_METHOD_GET,
		  :headers => headers,
		  :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
		};

		Comm.makeWebRequest(url, null, options, method(:onReceive));
    }

	//! Receive the data from the web request, and send it to the UI, if response is OK and data is there.
    function onReceive(responseCode, data) {
    	System.println("onReceive(): responseCode: " +responseCode +", data: " +data);
        if (responseCode == 200) {
            notify.invoke(data);
        } else if (responseCode == 401) {
        	getNewAccessTokenByRefreshToken();
        }
    }
}
