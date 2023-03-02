import std.stdio;
import std.array : appender, split;

import vibe.vibe;
//import asdf;

struct ChatUser {
    string id;
    string name;
    uint type; 
}

void main()
{
	auto addr = "http://127.0.0.1:8082/";

	ChatUser u = {"1", "test1", 2};
	auto json = serializeToJson(u);
	writeln(json);
	//writeln(toRestString(json));

	auto query = appender!string();
	query.put("u=");
	query.filterURLEncode(json.toString);
	query.put("&welcome=welcome");
	writeln(query.data);

	requestHTTP("http://127.0.0.1:8082/regSetting?" ~ query.data,
		(scope HTTPClientRequest req) {
			// could add headers here before sending,
			// write a POST body, or do similar things.
		},
		(scope HTTPClientResponse res) {
			logInfo("Response: %s", res.bodyReader.readAllUTF8());
		}
	);

}