import JsonHelper;
import lua.Table;

// ADD MONEYTREE API KEY HERE
var API_KEY = "";

typedef GetAccessTokenResponse = {
	access_token:String,
	token_type:String,
	expires_in:Int,
	refresh_token:String,
	scope:String,
	created_at:Int,
	resource_server:String
}

typedef MTAccount = {
	id:Int,
	guest_id:Int,
	nickname:String,
	currency:String,
	credential_id:Int,
	account_type:String,
	institution_account_number:String,
	institution_account_name:String,
	branch_name:Null<String>,
	status:String,
	last_success_at:String,
	group:String,
	detail_type:String,
	sub_type:String,
	current_balance:Float,
	current_balance_in_base:Float,
	balance_components:{
		available:Null<Float>, unclosed:Null<Float>, closed:Null<Float>, revolving:Null<Float>
	}
}

typedef GetAccountsResponse = {
	accounts:Array<MTAccount>
}

typedef MTTransaction = {
	id:Int,
	amount:Float,
	date:String,
	description_guest:Null<String>,
	description_pretty:String,
	description_raw:String,
	raw_transaction_id:Int,
	account_id:Int,
	claim_id:Null<Int>,
	category_id:Int,
	expense_type:Int,
	predicted_expense_type:Int,
	created_at:String,
	updated_at:String,
	transaction_attachments:Array<Dynamic>
}

typedef GetTransactionsResponse = {
	transactions:Array<MTTransaction>
}

typedef MTPosition = {
	id:Int,
	date:String,
	name_raw:String,
	name_clean:String,
	quantity:Float,
	market_value:Float,
	acquisition_value:Float,
	ticker:String,
	currency:String,
	acct_currency_value:Null<Float>,
	profit:Float,
	account_id:Int,
	value:Float,
	cost_basis:Float
}

class Moneytree {
	public static function getAccessToken(guestLogin:String, password:String):GetAccessTokenResponse {
		var url = "https://myaccount.getmoneytree.com/oauth/token";
		var method = "POST";
		var headers = [
			"Accept" => "application/json",
			"Host" => "myaccount.getmoneytree.com",
			"Connection" => "Keep-Alive",
			"User-Agent" => "Moneytree/1.16.3 (Android 12; en_AU; Pixel 3)",
			"Accept-Language" => "en-US-POSIX",
			"locale" => "en-US-POSIX",
			"Content-Type" => "application/json; charset=utf-8"
		];

		var body = JsonHelper.stringify({
			client_id: API_KEY,
			grant_type: "password",
			guest_login: guestLogin,
			password: password
		});

		var response = RequestHelper.makeRequest(url, method, headers, body);
		return JsonHelper.parse(response.content);
	}

	public static function getAccounts(accessToken:String):Array<MTAccount> {
		var url = "https://jp-api.getmoneytree.com/v8/api/accounts.json";
		var method = "GET";
		var headers = [
			"Accept-Language" => "en_AU",
			"locale" => "en_AU",
			"X-Api-Key" => API_KEY,
			"X-Api-Version" => "20180814",
			"Accept" => "application/json",
			"User-Agent" => "Moneytree/1.16.3 (Android 12; en_AU; Pixel 3)",
			"Authorization" => "Bearer " + accessToken,
			"Host" => "jp-api.getmoneytree.com",
			"Connection" => "Keep-Alive",
			"Content-Type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, method, headers, null);
		var parsed = JsonHelper.parse(response.content);
		return Table.toArray(parsed.accounts);
	}

	// GetTransactions
	// since = 1970-01-01
	// page = page=1
	// per_page=500
	public static function getTransactions(accessToken:String, accountId:String, since:String, page:Int, perPage:Int):Array<MTTransaction> {
		var url = 'https://jp-api.getmoneytree.com/v8/api/accounts/${accountId}/transactions.json?since=${since}&page=${page}&per_page=${perPage}';
		var method = "GET";
		var headers = [
			"Accept-Language" => "en_AU",
			"locale" => "en_AU",
			"X-Api-Key" => API_KEY,
			"X-Api-Version" => "20180814",
			"Accept" => "application/json",
			"User-Agent" => "Moneytree/1.16.3 (Android 12; en_AU; Pixel 3)",
			"Authorization" => "Bearer " + accessToken,
			"Host" => "jp-api.getmoneytree.com",
			"Connection" => "Keep-Alive",
			"Content-Type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, method, headers, null);
		var parsed = JsonHelper.parse(response.content);
		return Table.toArray(parsed.transactions);
	}

	public static function getPositions(accessToken:String, accountId:String):Array<MTPosition> {
		var url = 'https://jp-api.getmoneytree.com/v8/api/accounts/${accountId}/positions.json';
		var method = "GET";
		var headers = [
			"Accept-Language" => "en_AU",
			"locale" => "en_AU",
			"X-Api-Key" => API_KEY,
			"X-Api-Version" => "20180814",
			"Accept" => "application/json",
			"User-Agent" => "Moneytree/1.16.3 (Android 12; en_AU; Pixel 3)",
			"Authorization" => "Bearer " + accessToken,
			"Host" => "jp-api.getmoneytree.com",
			"Connection" => "Keep-Alive",
			"Content-Type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, method, headers, null);
		var parsed = JsonHelper.parse(response.content);
		return Table.toArray(parsed);
	}

	public static function refreshAllCredentials(accessToken:String):Dynamic {
		var url = 'https://jp-api.getmoneytree.com/v8/api/credentials/refresh.json';
		var method = "PUT";
		var headers = [
			"Accept-Language" => "en_AU",
			"locale" => "en_AU",
			"X-Api-Key" => API_KEY,
			"X-Api-Version" => "20180814",
			"Accept" => "application/json",
			"User-Agent" => "Moneytree/1.16.3 (Android 12; en_AU; Pixel 3)",
			"Authorization" => "Bearer " + accessToken,
			"Host" => "jp-api.getmoneytree.com",
			"Connection" => "Keep-Alive",
			"Content-Type" => "application/json"
		];

		var response = RequestHelper.makeRequest(url, method, headers, null);
		return JsonHelper.parse(response.content);
	}
}
