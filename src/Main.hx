import lua.Table;
import RequestHelper;
import JsonHelper;
import Moneytree;
import Storage;

var AccountTypeGiro = untyped __lua__("AccountTypeGiro") ;
var AccountTypeSavings = untyped __lua__("AccountTypeSavings") ;
var AccountTypeFixedTermDeposit = untyped __lua__("AccountTypeFixedTermDeposit") ;
var AccountTypeLoan = untyped __lua__("AccountTypeLoan") ;
var AccountTypeCreditCard = untyped __lua__("AccountTypeCreditCard") ;
var AccountTypePortfolio = untyped __lua__("AccountTypePortfolio") ;
var AccountTypeOther = untyped __lua__("AccountTypeOther") ;

typedef Account = {
    ?name:String,
    ?owner:String,
    ?accountNumber:String,
    ?subAccount:String,
    ?portfolio:Bool,
    ?bankCode:String,
    ?currency:String,
    ?iban:String,
    ?bic:String,
    ?balance:Float,
    type:Dynamic
}

typedef Transaction = {
    ?name:String,
    ?accountNumber:String,
    ?bankCode:String,
    ?amount:Float,
    ?currency:String,
    ?bookingDate:Int,
    ?valueDate:Int,
    ?purpose:String,
    ?transactionCode:Int,
    ?textKeyExtension:Int,
    ?purposeCode:String,
    ?bookingKey:String,
    ?bookingText:String,
    ?primanotaNumber:String,
    ?batchReference:String,
    ?endToEndReference:String,
    ?mandateReference:String,
    ?creditorId:String,
    ?returnReason:String,
    ?booked:Bool
}

typedef Security = {
    ?name:String,
    ?isin:String,
    ?securityNumber:String,
    ?quantity:Float,
    ?currencyOfQuantity:String,
    ?purchasePrice:Float,
    ?currencyOfPurchasePrice:String,
    ?exchangeRateOfPurchasePrice:Float,
    ?price:Float,
    ?currencyOfPrice:String,
    ?exchangeRateOfPrice:Float,
    ?amount:Float,
    ?originalAmount:Float,
    ?currencyOfOriginalAmount:String,
    ?market:String,
    ?tradeTimestamp:Int
}

class Main {
    static function parseDate(dateStr:String):Date {
        // Split the string by 'T' to separate date and time
        var dateAndTime = dateStr.split("T");
        var datePart = dateAndTime[0];
        var timePart = dateAndTime[1];

        // Split the date into year, month, day
        var dateParts = datePart.split("-");
        var year = Std.parseInt(dateParts[0]);
        var month = Std.parseInt(dateParts[1]);
        var day = Std.parseInt(dateParts[2]);

        // Split the time and timezone part
        var timeParts = timePart.split("+");
        var time = timeParts[0];
        var timeZoneOffset = timeParts.length > 1 ? timeParts[1] : "00:00";

        // Handle the time zone offset
        var tzParts = timeZoneOffset.split(":");
        var tzHour = Std.parseInt(tzParts[0]);
        var tzMinute = Std.parseInt(tzParts[1]);

        // Split the time into hour, minute, second
        var timeSegments = time.split(":");
        var hour = Std.parseInt(timeSegments[0]);
        var minute = Std.parseInt(timeSegments[1]);
        var second = Std.parseInt(timeSegments[2]);

        // Create a date object based on parsed values
        var date = Date.fromTime(new Date(year, month - 1, day, hour, minute, second).getTime());

        // Adjust the date based on timezone offset (add hours and minutes from the offset)
        // var adjustedTime = date.getTime() - (tzHour * 3600 * 1000) - (tzMinute * 60 * 1000);

        // Return the adjusted date
        return Date.fromTime(date.getTime());
    }

    @:luaDotMethod
    @:expose("SupportsBank")
    static function SupportsBank(protocol:String, bankCode:String) {
        trace("SupportsBank got called");
        trace(protocol);
        trace(bankCode);

        return bankCode == "Moneytree";
    }

    @:luaDotMethod
    @:expose("InitializeSession")
    static function InitializeSession(protocol:String, bankCode:String, username:String, reserved, password:String) {
        trace("InitializeSession got called");
        trace(protocol);
        trace(bankCode);
        trace(username);
        trace(reserved);
        trace(password);

        var getAccessTokenResponse = Moneytree.getAccessToken(username, password);
        trace(getAccessTokenResponse);

        Storage.set("access_token", getAccessTokenResponse.access_token);
        Storage.set("refresh_token", getAccessTokenResponse.refresh_token);
        Storage.set("expires_in", getAccessTokenResponse.expires_in);

        Moneytree.refreshAllCredentials(getAccessTokenResponse.access_token);
    }

    @:luaDotMethod
    @:expose("ListAccounts")
    static function ListAccounts(knownAccounts) {
        trace("ListAccounts got called");
        trace(knownAccounts);
        var accessToken = Storage.get("access_token");
        var refreshToken = Storage.get("refresh_token");

        trace("accessToken---");
        trace(accessToken);
        trace("refreshToken---");
        trace(refreshToken);

        var accountsResponse = Moneytree.getAccounts(accessToken);
        trace("accountsResponse---");
        trace(accountsResponse);

        var current_hour = Date.now().getHours();

        // Storage.set("get_accounts_response", Table.fromArray(accountsResponse));
        Storage.set("get_accounts_response", accountsResponse);
        Storage.set("get_accounts_response_hour", current_hour);

        var convertedAccounts:Array<Account> = [];

        for (account in accountsResponse) {
            if (account.status == "closed") {
                continue;
            }

            if (account.account_type != "credit_card"
            && account.account_type != "stock"
            && account.account_type != "bank"
            && account.account_type != "stored_value") {
                continue;
            }

            var accountType = switch (account.account_type) {
                case "bank_account": untyped __lua__("AccountTypeGiro");
                case "credit_card": untyped __lua__("AccountTypeCreditCard");
                case "loan": untyped __lua__("AccountTypeLoan");
                case "stock": untyped __lua__("AccountTypePortfolio");
                case _: untyped __lua__("AccountTypeOther");
            }

            var isPortfolio = account.account_type == "stock";

            trace("account type ??? ");
            trace(accountType);

            var convertedAccount:Account = {
                accountNumber: Std.string(account.id),
                name: account.nickname,
                iban: account.institution_account_number,
                currency: account.currency,
                balance: account.current_balance,
                type: accountType,
                portfolio: isPortfolio,
            };

            trace(convertedAccount);

            convertedAccounts.push(convertedAccount);
        }

        var results = Table.fromArray(convertedAccounts);

        trace(results);

        return results;
    }

    @:luaDotMethod
    @:expose("RefreshAccount")
    static function RefreshAccount(account:{
        iban:String,
        bic:String,
        comment:String,
        bankCode:String,
        owner:String,
        attributes:Dynamic,
        subAccount:String,
        currency:String,
        name:String,
        balance:Float,
        portfolio:Bool,
        type:String,
        balanceDate:Float,
        accountNumber:String
    }, since:Float):Dynamic {
        trace("RefreshAccount got called");
        trace(account);
        trace(since);

        var date = Date.fromTime(since * 1000);
        var sinceStr = DateTools.format(date, "%Y-%m-%d");
        trace(sinceStr);

        var accessToken = Storage.get("access_token");
        var refreshToken = Storage.get("refresh_token");
        // var getAccountsResponse:Array<MTAccount> = cast Table.toArray(Storage.get("get_accounts_response"));
        var current_hour = Date.now().getHours();

        var getAccountsResponse:Array<MTAccount> = Storage.get("get_accounts_response");
        var getAccountsResponseHour:Int = Storage.get("get_accounts_response_hour");

        trace("existing get_accounts_response ");
        trace(getAccountsResponse);

        if (getAccountsResponse == null || getAccountsResponseHour == null || getAccountsResponseHour != current_hour) {
            getAccountsResponse = Moneytree.getAccounts(accessToken);
            Storage.set("get_accounts_response", getAccountsResponse);
            Storage.set("get_accounts_response_hour", current_hour);
        }


        // find the correct account based on accountNumber
        var account = getAccountsResponse.filter(function(a) {
            trace("checking: " + Std.string(a.id) + " == " + account.accountNumber);
            return Std.string(a.id) == account.accountNumber;
        })[0];

        trace("found following account");
        trace(account);

        var positions = [];
        var convertedTransactions:Array<Transaction> = [];
        if (account.account_type == "stock") {
            trace("----------------------------------");
            trace("----------------------------------");
            trace("----------------------------------");
            trace("is stock!!!");

            var mtPositions = Moneytree.getPositions(accessToken, Std.string(account.id));

            trace("mtPositions");
            trace(mtPositions);

            for (position in mtPositions) {
                trace("parsing position");
                trace(position);

                // var purchasePrice = position.cost_basis / position.quantity;

                var purchasePrice = 0.0;
                if (position.acquisition_value != null && position.quantity != null && position.quantity != 0) {
                    purchasePrice = position.acquisition_value / position.quantity;
                }

                // adjust price if profit is available
                //           1> Main.hx:272: { date : 2024-09-21, name_raw : アップル, id : 1653394884, value : 3423, acquisition_value : 1780.65, account_id : 29876986, profit : 303477, quantity : 15, currency : USD, name_clean : アップル 旧NISA, acct_currency_value : 492603, ticker : AAPL, market_value : 3423, cost_basis : 1780.65 }
                //           1> Main.hx:272: { name_raw : ハブ, id : 1653394882, date : 2024-09-21, acquisition_value : 121400, account_id : 29876988, profit : 30200, quantity : 200, currency : JPY, name_clean : ハブ 旧NISA, value : 151600, ticker : 3030, market_value : 151600, cost_basis : 121400 }
                //           1> Main.hx:272: { name_raw : 三菱ＵＦＪ－ｅＭＡＸＩＳ　Ｓｌｉｍ　新興国株式インデックス, id : 1653393816, date : 2024-09-21, acquisition_value : 86134, account_id : 29928954, profit : 20135, quantity : 69312, currency : JPY, name_clean : 三菱UFJ-eMAXIS Slim 新興国株式インデックス, value : 106269, ticker : 20331C177, market_value : 106269, cost_basis : 86134 }
                //           1> Main.hx:314: [{ purchasePrice : 1.5992, price : 2.459, tradeTimestamp : 1726844400, quantity : 50000, name : 三菱ＵＦＪ－ｅＭＡＸＩＳ　Ｓｌｉｍ　全世界株式（オール・カントリー）, currencyOfOriginalAmount : JPY, currencyOfPrice : JPY, currencyOfPurchasePrice : JPY, originalAmount : 122950, isin : 10331418A }]
                //           1> Main.hx:314: [{ purchasePrice : 2601.03, price : 46.03, tradeTimestamp : 1726844400, quantity : 1, name : ロブロックス A RBLX NYSE, currencyOfOriginalAmount : USD, currencyOfPrice : USD, currencyOfPurchasePrice : USD, originalAmount : 46.03, isin : RBLX }]

                // var initialValue = positionPrice;
                // trace("initialValue");
                // trace(initialValue);
                if (position.profit != null && position.currency == "JPY") {
                    purchasePrice = position.value - position.profit;
                }
                // trace("adjusted initialValue");
                // trace(initialValue);

                var security:Security = {
                    name: position.name_raw,
                    isin: position.ticker,
                    quantity: position.quantity,
                    // securityNumber: Std.string(position.id),
                    purchasePrice: purchasePrice,
                    currencyOfPurchasePrice: position.currency,
                    // currencyOfQuantity: position.currency,
                    // exchangeRateOfPurchasePrice: null,
                    price: position.value / position.quantity,
                    currencyOfPrice: position.currency,
                    // exchangeRateOfPrice: null,
                    // amount: position.value,
                    originalAmount: position.value,
                    currencyOfOriginalAmount: position.currency,
                    // market: null,
                    tradeTimestamp: Std.parseInt(DateTools.format(Date.fromString(position.date), "%s")),
                };
                positions.push(security);
            }

            trace("positions");
            trace(positions);
            trace(JsonHelper.stringify(positions));

            return {
                balance: account.current_balance,
                securities: Table.fromArray(positions),
            }
        } else {
            var transactions = Moneytree.getTransactions(accessToken, Std.string(account.id), sinceStr, 1, 500);

            trace("transactions");
            trace(transactions);

            for (transaction in transactions) {
                var convertedTransaction:Transaction = {
                    name: transaction.description_pretty,
                    accountNumber: Std.string(transaction.account_id),
                    amount: transaction.amount,
                    currency: account.currency,
                    bookingDate: Std.parseInt(DateTools.format(parseDate(transaction.date), "%s")),
                    // bookingDate: Std.int(Date.fromString(transaction.date).getTime() / 1000),
                    // valueDate: Std.int(Date.fromString(transaction.date).getTime() / 1000),
                    purpose: transaction.description_pretty,
                    booked: true
                };

                convertedTransactions.push(convertedTransaction);
            }

            return {
                balance: account.current_balance,
                transactions: Table.fromArray(convertedTransactions),
            }
        }
    }

    @:luaDotMethod
    @:expose("EndSession")
    static function EndSession() {
        trace("EndSession got called");
    }

    function nonstatic() {
        trace("ooooo");
    }

    static function main() {
        trace("hello world");
        untyped __lua__("
        WebBanking {
            version = 1.0,
            url = 'https://ana.co.jp',
            description = 'Moneytree',
            services = { 'Moneytree' },
        }
        ");

        untyped __lua__("
        function SupportsBank(protocol, bankCode)
            return _hx_exports.SupportsBank(protocol, bankCode)
        end
        ");

        untyped __lua__("
        function InitializeSession(protocol, bankCode, username, reserved, password)
            return _hx_exports.InitializeSession(protocol, bankCode, username, reserved, password)
        end
        ");

        untyped __lua__("
        function RefreshAccount(account, since)
            return _hx_exports.RefreshAccount(account, since)
        end
        ");

        untyped __lua__("
        function ListAccounts(knownAccounts)
            return _hx_exports.ListAccounts(knownAccounts)
        end
        ");

        untyped __lua__("
        function EndSession()
            return _hx_exports.EndSession()
        end
        ");
    }
}
