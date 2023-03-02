import std.stdio;
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
    Status status;
	@optional
    UserInfo[] users;
	@optional
    PendingUser[] pendingUsers;
    @optional 
	ChatSession sessions;
    @optional 
	Setting setting;
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
    string id;
    string name;
    uint type; 
	uint time;
	string icon;
}

struct Setting {
    string welcome; //welcome message
}

interface ChatApi
{
	//@queryParam("user_json", "user_json")
	@path("/reg")
	OpreationResult reg(@viaQuery("u") ChatUser u);

	@path("/query")
    OpreationResult queryUsers(@viaQuery("u") ChatUser u, @viaQuery("list") string list);

	@path("regSetting")
	OpreationResult regSetting(@viaQuery("u") ChatUser u, @viaQuery("welcome") string welcome);

	@path("/querySetting")
    OpreationResult getSetting(@viaQuery("u") string u);

	@path("/join")
    OpreationResult join(@viaQuery("u") string u);

	@path("/leave")
    OpreationResult leave(@viaQuery("u") string u);

	@path("/list")
    OpreationResult list(@viaQuery("u") string u);

	@path("/sessions")
    OpreationResult listSessions(@viaQuery("u") string u);

	@path("/accept")
    OpreationResult accept(@viaQuery("u") string u, @viaQuery("target") string target);

	@path("/session")
    OpreationResult session(@viaQuery("u") string u, @viaQuery("target") string target);

	@path("/end")
    OpreationResult end(@viaQuery("u") string u, @viaQuery("target") string target);

	@path("/say")
    OpreationResult say(@viaQuery("u") string u, @viaQuery("session") string session,  @viaQuery("content") string content);

	@path("/history")
    OpreationResult history(@viaQuery("u") string u, @viaQuery("from") string from, @viaQuery("to") string to, @viaQuery("last") string last);
}

void main()
{
/*	
	auto addr = "http://127.0.0.1:8082/";

	ChatUser u = {"1", "test1", 2};
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
	auto result = api.regSetting(u, "welcome u");
	writeln(result);
	//api.reg(u);

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