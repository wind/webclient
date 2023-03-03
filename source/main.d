import proto;

import std.stdio;
import std.conv;
import std.string;
import std.array : appender, split;

import vibe.vibe;
//import asdf;

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
    OpreationResult session(@viaQuery("u") ChatUser u, @viaQuery("sid") long sid, @viaQuery("mbegin") int mbegin, @viaQuery("mend") int mend);

	@path("/end")
    OpreationResult end(@viaQuery("u") ChatUser u, @viaQuery("sid") long sid);

	@path("/say")
    OpreationResult say(@viaQuery("u") ChatUser u, @viaQuery("sid") long sid,  @viaQuery("content") string content);

	@path("/history")
    OpreationResult history(@viaQuery("u") ChatUser u, @viaQuery("from") string from, @viaQuery("to") string to, @viaQuery("stime") long stime);

	@path("/offlineSession")
    OpreationResult offlineSession(@viaQuery("u") ChatUser u, @viaQuery("sid") long sid, @viaQuery("mbegin") int mbegin, @viaQuery("mend") int mend);
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

	OpreationResult result;
	//test setting
	{
		string welcome_info1 = "welcome info1";
		string welcome_info2 = "welcome info2";
		result = api.regSetting(user, welcome_info1);
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

		result = api.reg(info1);
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

	//test pending
	{
		//clear session first
		result = api.listSessions(admin);
		assert(result.status_value == Status.OK);

		foreach( s ; result.sessions) {
			result = api.end(admin, s._id);
			assert(result.status_value == Status.OK);
		}

		result = api.list(user);
		assert(result.status_value == Status.USER_NOT_PERMISSION);

		result = api.list(admin);
		assert(result.status_value == Status.OK);

		foreach( u ; result.pendingUsers) {
			ChatUser _u = {u.id, u.name, 0};
			result = api.leave(_u);
			assert(result.status_value == Status.OK);
		}

		result = api.list(admin);
		assert(result.status_value == Status.OK);
		assert(result.pendingUsers.empty);

		result = api.join(user);
		assert(result.status_value == Status.OK);
		result = api.list(admin);
		//writeln(result);
		assert(result.status_value == Status.OK);
		assert(result.pendingUsers.length == 1);

		result = api.leave(user);
		assert(result.status_value == Status.OK);
		assert(result.pendingUsers.empty);

		result = api.leave(user); //user can leave multi times, no effect when not join
		assert(result.status_value == Status.OK);
		assert(result.pendingUsers.empty);
	}

	//test session
	{
		result = api.listSessions(user);
		assert(result.status_value == Status.USER_NOT_PERMISSION);

		result = api.listSessions(admin);
		assert(result.status_value == Status.OK);

		foreach( s ; result.sessions) {
			result = api.end(admin, s._id);
			assert(result.status_value == Status.OK);
		}

		result = api.accept(user2, user.id);
		assert(result.status_value == Status.USER_NOT_PERMISSION);

		result = api.accept(admin, user.id);
		assert(result.status_value == Status.USER_NOT_PENDING);

		result = api.join(user);
		assert(result.status_value == Status.OK);
		if (result.sessions.empty) {
			result = api.accept(admin, user.id);
			assert(result.status_value == Status.OK);
		}

		result = api.join(user);
		assert(result.status_value == Status.OK);
		assert(result.sessions.length == 1);	
		auto sid =  result.sessions[0]._id;
		result = api.say(user, -1, "say 1");
		assert(result.status_value == Status.SESSION_NOT_EXIST);

		result = api.say(user2, sid, "say 1");
		assert(result.status_value == Status.USER_NOT_PERMISSION);

		int mend = 30;
		foreach(i ; 0 .. mend) {
			result = api.say(user, sid, format!"say %s"(i));
			assert(result.status_value == Status.OK);
		}

		//result = api.session(user, sid, 0, -1);
		//writeln(result);

		int mbegin = 10;
		result = api.session(user, sid, mbegin, mend-1);
		//writeln(result);
		assert(result.status_value == Status.OK);
		assert(result.sessions.length == 1);	
		auto session = result.sessions[0];
		assert(session.messages.length == 20);
		assert(session.messages[0].from == user.id);
		foreach(i ; mbegin .. mend) {
			assert(session.messages[i - mbegin].id == i);
			assert(session.messages[i - mbegin].content == format!"say %s"(i));
		}

		mbegin = 0;
		mend = 10;
		result = api.session(user, sid, mbegin, mend-1);
		//writeln(result);
		assert(result.status_value == Status.OK);
		assert(result.sessions.length == 1);	
		session = result.sessions[0];
		assert(session.messages.length == 10);
		assert(session.messages[0].from == user.id);
		foreach(i ; mbegin .. mend) {
			assert(session.messages[i - mbegin].id == i);
			assert(session.messages[i - mbegin].content == format!"say %s"(i));
		}

		mbegin = -1 - 20;
		mend = -1;
		result = api.session(user, sid, mbegin + 1, mend);
		//writeln(result);
		assert(result.status_value == Status.OK);
		assert(result.sessions.length == 1);	
		session = result.sessions[0];
		assert(session.messages.length == 20);
		assert(session.messages[0].from == user.id);
		foreach(i ; 10 .. 30) {
			assert(session.messages[i-10].id == i);
			assert(session.messages[i-10].content == format!"say %s"(i));
		}

		result = api.end(user2, sid);
		assert(result.status_value == Status.USER_NOT_PERMISSION);

		result = api.end(user, sid);
		assert(result.status_value == Status.OK);

		result = api.end(user, -1);
		assert(result.status_value == Status.SESSION_NOT_EXIST);

		result = api.say(user, sid, "say 1");
		assert(result.status_value == Status.SESSION_NOT_EXIST);
		//writeln(result);
	}

	//test history
	{
		result = api.history(user, user.id, admin.id, 0);
		assert(result.status_value == Status.USER_NOT_PERMISSION);
		writeln(result);

		result = api.history(admin, user.id, admin.id, 0);
		writeln(result);
		assert(result.status_value == Status.OK);		
	}

}