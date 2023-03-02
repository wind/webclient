import vibe.vibe;

void main()
{
	requestHTTP("http://google.com",
		(scope HTTPClientRequest req) {
			// could add headers here before sending,
			// write a POST body, or do similar things.
		},
		(scope HTTPClientResponse res) {
			logInfo("Response: %s", res.bodyReader.readAllUTF8());
		}
	);
}