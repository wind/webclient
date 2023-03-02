import std.stdio;
import std.conv;
import std.array : appender, split;

import vibe.vibe;
//import asdf;

enum Status 
{
    OK,
    UNKNOWN_ERROR,
    USER_NOT_EXIST,
    USER_NOT_AUTHED,
    USER_NOT_PERMISSION,
    USER_NOT_PENDING,
    SESSION_NOT_EXIST,
    SESSION_ENDED,
}

struct PendingUser 
{
    string id;
    string name;
}

struct OpreationResult 
{
	@optional
    string status;
	@optional
    UserInfo[] users;
	@optional
    PendingUser[] pendingUsers;
    @optional 
	ChatSession sessions;
    @optional 
	Setting setting;

	Status status_value() {
		return status.empty?Status.OK:std.conv.to!Status(status);
	}
}

struct ChatMessage {
    uint _id; //name _id for compatable with mongodb
    string from;
    //string to = 3;
    string content;
    @optional 
	string sessionId; //only used for intenal purpose, assigned when save to mongodb
}

struct ChatSession {
    long _id; //name _id for compatable with mongodb
    string from;
    string to;
	@optional
    ChatMessage[] messages;
    ulong beginTime;
    ulong endTime;
    string endUser;
 }

struct ChatUser {
    string id;
    string name;
    uint type; 
}

struct UserInfo {
    @optional string id;
   	@optional string name;
    @optional uint type; 
	@optional uint time;
	@optional string icon;
}

struct Setting {
    string welcome; //welcome message
}

interface ChatApi
{
	//@queryParam("user_json", "user_json")
	@path("/reg")
	OpreationResult reg(@viaQuery("u") UserInfo u);

	@path("/query")
    OpreationResult queryUsers(@viaQuery("u") ChatUser u, @viaQuery("list") string list);

	@path("regSetting")
	OpreationResult regSetting(@viaQuery("u") ChatUser u, @viaQuery("welcome") string welcome);

	@path("/querySetting")
    OpreationResult querySetting(@viaQuery("u") ChatUser u);

	@path("/join")
    OpreationResult join(@viaQuery("u") ChatUser u);

	@path("/leave")
    OpreationResult leave(@viaQuery("u") ChatUser u);

	@path("/list")
    OpreationResult list(@viaQuery("u") ChatUser u);

	@path("/sessions")
    OpreationResult listSessions(@viaQuery("u") ChatUser u);

	@path("/accept")
    OpreationResult accept(@viaQuery("u") ChatUser u, @viaQuery("target") string target);

	@path("/session")
    OpreationResult session(@viaQuery("u") ChatUser u, @viaQuery("target") string target);

	@path("/end")
    OpreationResult end(@viaQuery("u") ChatUser u, @viaQuery("target") string target);

	@path("/say")
    OpreationResult say(@viaQuery("u") ChatUser u, @viaQuery("session") string session,  @viaQuery("content") string content);

	@path("/history")
    OpreationResult history(@viaQuery("u") ChatUser u, @viaQuery("from") string from, @viaQuery("to") string to, @viaQuery("last") string last);
}

void main()
{
	//auto addr = "http://127.0.0.1:8082/";

	ChatUser user = {"1", "user1", 0};
	ChatUser user2 = {"2", "user2", 0};

	ChatUser admin = {"1001", "admin", 2};
/*
	auto json = serializeToJson(u);
	writeln(json);
	//writeln(toReststring(json));

	auto query = appender!string();
	//query.put("u=");
	query.filterURLEncode(json.tostring);
	//query.put("&welcome=welcome");
	writeln(query.data);
*/

	auto api = new RestInterfaceClient!ChatApi("http://127.0.0.1:8082");

	//test setting
	{
		string welcome_info1 = "welcome info1";
		string welcome_info2 = "welcome info2";
		auto result = api.regSetting(user, welcome_info1);
		assert(result.status_value == Status.USER_NOT_PERMISSION);

		result = api.regSetting(admin, welcome_info1);
		assert(result.status_value == Status.OK);

		result = api.querySetting(user);
		assert(result.status_value == Status.OK);
		assert(result.setting.welcome == welcome_info1);

		result = api.regSetting(admin, welcome_info2);
		assert(result.status_value == Status.OK);

		result = api.querySetting(user);
		assert(result.status_value == Status.OK);
		assert(result.setting.welcome == welcome_info2);

		//writeln(result);
	}

	//test reg
	{
		UserInfo info1 = {"1", "user1", 0, 0, "icon1"};
		UserInfo info2 = {"2", "user2", 0, 0, "icon2"};

		auto result = api.reg(info1);
		assert(result.status_value == Status.OK);
		result = api.reg(info2);
		assert(result.status_value == Status.OK);

		result = api.queryUsers(user, info1.id);
		//writeln(result);
		assert(result.status_value == Status.OK);
		assert(result.users.length == 1);
		assert(result.users[0].id == info1.id);

		result = api.queryUsers(user, info1.id ~ "," ~ info2.id);
		assert(result.status_value == Status.OK);
		assert(result.users.length == 2);
		assert(result.users[0].id == info1.id);
		assert(result.users[1].id == info2.id);
		
		//writeln(result);
	}

	//test session
	{

		auto result = api.join(user);
		assert(result.status_value == Status.OK);
		result = api.accept(admin, user.id);
		assert(result.status_value == Status.OK);
		result = api.end(user, user.id);
		writeln(result);
		assert(result.status_value == Status.OK);

		//writeln(result);
	}

/*
	requestHTTP("http://127.0.0.1:8082/regSetting?" ~ query.data,
		(scope HTTPClientRequest req) {
			// could add headers here before sending,
			// write a POST body, or do similar things.
		},
		(scope HTTPClientResponse res) {
			logInfo("Response: %s", res.bodyReader.readAllUTF8());
		}
	);
*/
}