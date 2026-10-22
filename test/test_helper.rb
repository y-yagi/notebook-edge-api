require "edgeway/test"
require "edgeway/http/auth/stub"

# Requests authenticate with tokens that a StubVerifier knows (auth_headers),
# checked against these settings like a Firebase ID token would be.
ENV["JWT_ISSUER"] = "https://securetoken.google.com/test-project"
ENV["JWT_AUDIENCE"] = "test-project"
Edgeway::Auth.verifier = Edgeway::Auth::StubVerifier.new

# The headers of a request by the user uid.
def auth_headers(uid)
  token = "token-#{uid}"
  Edgeway::Auth.verifier.allow(token, { "sub" => uid, "iss" => ENV["JWT_ISSUER"], "aud" => ENV["JWT_AUDIENCE"],
                                        "exp" => Time.now.to_i + 3600 })
  { "Authorization" => "Bearer #{token}" }
end
