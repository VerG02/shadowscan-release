--!nonstrict
-- ShadowScan v0.6.1 production loader for VerG02/shadowscan-release.
-- Release ref is version-pinned. Artifact SHA-256 is mandatory and checked BEFORE loadstring.
-- The embedded digest protects the downloaded artifact bytes; it does not authenticate this loader
-- itself. Verify this loader from the repository URL or compare its published SHA-256 out of band.
-- No runtime network activity occurs after the standalone artifact has been loaded.

local CONFIG = {
	REPO_OWNER = "VerG02",
	REPO_NAME = "shadowscan-release",
	RELEASE_REF = "release-v0.6.1",
	ARTIFACT_PATH = "dist/ShadowScan_v0.6.1_Standalone.lua",
	EXPECTED_SHA256 = "da46c8fd2e305a877b58f26519eeb46ed0fbecc7cbd959cd30d6fe98f8174c7b",
}

-- Duplicate-execution guard: use the executor environment where available, then the chunk/global
-- environment. If the previous app was explicitly destroyed, the loader permits a fresh instance.
local function resolve_global_env()
	local candidates = {}
	pcall(function() if type(getgenv) == "function" then candidates[#candidates + 1] = getgenv() end end)
	pcall(function() if type(getfenv) == "function" then candidates[#candidates + 1] = getfenv(0) end end)
	pcall(function() if type(_G) == "table" then candidates[#candidates + 1] = _G end end)
	for _, candidate in ipairs(candidates) do
		if type(candidate) == "table" then return candidate end
	end
	return nil
end

local GLOBAL_ENV = resolve_global_env()
local GUARD_KEY = "__SHADOWSCAN_STANDALONE_V061__"
if GLOBAL_ENV then
	local ok_existing, existing = pcall(function() return GLOBAL_ENV[GUARD_KEY] end)
	if ok_existing and type(existing) == "table" and existing.VERSION == "0.6.1"
		and type(existing.instance) == "table" and existing.instance.destroyed ~= true then
		print("[ShadowScan loader] v0.6.1 is already running; returning the existing instance")
		return existing
	end
end

-- ---------------------------------------------------------------- integrity check
-- SHA-256 inlined VERBATIM from src/sha256.lua (the implementation the Luau test suite runs) so the
-- loader cannot drift from the proven digest code. Only the module wrapper is adapted.
local sha256
do
	local band, bxor, bnot, rshift, rrotate = bit32.band, bit32.bxor, bit32.bnot, bit32.rshift, bit32.rrotate

	local K = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
	}

	local MOD = 4294967296

	local function be32(n)
		return string.char(band(rshift(n, 24), 255), band(rshift(n, 16), 255), band(rshift(n, 8), 255), band(n, 255))
	end

	sha256 = function(msg)
		msg = tostring(msg)
		local len = #msg
		local h0, h1, h2, h3 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
		local h4, h5, h6, h7 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

		local padlen = (55 - len) % 64
		local bits_hi = math.floor(len / 536870912) -- len * 8 / 2^32
		local bits_lo = (len * 8) % MOD
		local data = msg .. "\128" .. string.rep("\0", padlen) .. be32(bits_hi) .. be32(bits_lo)

		local w = {}
		for p = 1, #data, 64 do
			local b = { string.byte(data, p, p + 63) }
			for i = 1, 16 do
				local j = (i - 1) * 4
				w[i] = b[j + 1] * 16777216 + b[j + 2] * 65536 + b[j + 3] * 256 + b[j + 4]
			end
			for i = 17, 64 do
				local w15, w2 = w[i - 15], w[i - 2]
				local s0 = bxor(rrotate(w15, 7), rrotate(w15, 18), rshift(w15, 3))
				local s1 = bxor(rrotate(w2, 17), rrotate(w2, 19), rshift(w2, 10))
				w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % MOD
			end
			local a, bb, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
			for i = 1, 64 do
				local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
				local ch = bxor(band(e, f), band(bnot(e), g))
				local t1 = (h + S1 + ch + K[i] + w[i]) % MOD
				local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
				local maj = bxor(band(a, bb), band(a, c), band(bb, c))
				local t2 = (S0 + maj) % MOD
				h, g, f, e, d, c, bb, a = g, f, e, (d + t1) % MOD, c, bb, a, (t1 + t2) % MOD
			end
			h0, h1, h2, h3 = (h0 + a) % MOD, (h1 + bb) % MOD, (h2 + c) % MOD, (h3 + d) % MOD
			h4, h5, h6, h7 = (h4 + e) % MOD, (h5 + f) % MOD, (h6 + g) % MOD, (h7 + h) % MOD
		end
		return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
	end
end

local function fail(msg)
	print("[ShadowScan loader] ERROR: " .. msg)
	error("ShadowScan loader: " .. msg, 0)
end

local function valid_sha256(s)
	return type(s) == "string" and #s == 64 and string.match(s, "^[0-9a-fA-F]+$") ~= nil
end

if type(CONFIG.REPO_OWNER) ~= "string" or CONFIG.REPO_OWNER == "" then fail("repository owner is not configured") end
if type(CONFIG.REPO_NAME) ~= "string" or CONFIG.REPO_NAME == "" then fail("repository name is not configured") end
if type(CONFIG.RELEASE_REF) ~= "string" or CONFIG.RELEASE_REF == "" then fail("release ref is not configured") end
if type(CONFIG.ARTIFACT_PATH) ~= "string" or CONFIG.ARTIFACT_PATH == "" then fail("artifact path is not configured") end
if not valid_sha256(CONFIG.EXPECTED_SHA256) then fail("embedded artifact SHA-256 is missing or malformed; refusing to download") end

local url = string.format("https://raw.githubusercontent.com/%s/%s/%s/%s",
	CONFIG.REPO_OWNER, CONFIG.REPO_NAME, CONFIG.RELEASE_REF, CONFIG.ARTIFACT_PATH)
print("[ShadowScan loader] fetching pinned artifact: " .. url)

local function request_artifact(target_url)
	local candidates = {}
	pcall(function() if type(http_request) == "function" then candidates[#candidates + 1] = http_request end end)
	pcall(function() if type(syn) == "table" and type(syn.request) == "function" then candidates[#candidates + 1] = syn.request end end)
	pcall(function() if type(http) == "table" and type(http.request) == "function" then candidates[#candidates + 1] = http.request end end)
	pcall(function() if type(request) == "function" then candidates[#candidates + 1] = request end end)
	local last_error = nil
	for _, fn in ipairs(candidates) do
		local ok, response = pcall(fn, { Url = target_url, Method = "GET" })
		if ok and (type(response) == "table" or type(response) == "string") then return response end
		last_error = ok and "HTTP function returned an unsupported response" or tostring(response)
	end
	-- Some executors expose game:HttpGet but not request-style functions.
	local ok_game, game_obj = pcall(function() return game end)
	if ok_game and game_obj ~= nil then
		local ok_get, body = pcall(function() return game_obj:HttpGet(target_url) end)
		if ok_get and type(body) == "string" then return { StatusCode = 200, Body = body } end
		last_error = tostring(body)
	end
	fail("no supported HTTP method succeeded. " .. tostring(last_error or "No request API is available."))
end

local response = request_artifact(url)
local status, body
if type(response) == "string" then
	body = response
else
	if response.Success == false then fail("HTTP request reported failure for the pinned artifact") end
	status = response.StatusCode or response.statusCode or response.Status or response.code
	body = response.Body or response.body
end
if status ~= nil then
	local numeric_status = tonumber(status)
	if numeric_status == nil or numeric_status ~= 200 then fail("HTTP response status is not 200: " .. tostring(status)) end
end
if type(body) ~= "string" or #body < 100 then
	fail("fetched artifact is empty or too short; check the pinned release path")
end
if not string.find(body, "SHADOWSCAN", 1, true) then fail("downloaded file is not a recognized ShadowScan artifact") end

local actual_hash = sha256(body)
local expected_hash = string.lower(CONFIG.EXPECTED_SHA256)
if actual_hash ~= expected_hash then
	fail(string.format("artifact integrity FAILED (expected %s..., received %s...). Execution refused.",
		string.sub(expected_hash, 1, 16), string.sub(actual_hash, 1, 16)))
end
print(string.format("[ShadowScan loader] integrity verified: %s...", string.sub(actual_hash, 1, 16)))

local compiler = loadstring
if type(compiler) ~= "function" then fail("loadstring is unavailable in this runtime; execute the standalone file directly") end
local chunk, compile_error = compiler(body, "=ShadowScan_v0.6.1")
if not chunk then fail("standalone artifact failed compilation: " .. tostring(compile_error)) end
local ok_run, result = pcall(chunk)
if not ok_run then fail("ShadowScan failed during initialization: " .. tostring(result)) end
if type(result) ~= "table" then fail("standalone artifact did not return its application API") end

-- Store the successful instance to prevent duplicate GUI/application creation on repeated execution.
if GLOBAL_ENV then
	pcall(function() GLOBAL_ENV[GUARD_KEY] = result end)
end
local original_destroy = result.destroy
if type(original_destroy) == "function" then
	result.destroy = function(...)
		local values = { pcall(original_destroy, ...) }
		if GLOBAL_ENV then
			pcall(function() if GLOBAL_ENV[GUARD_KEY] == result then GLOBAL_ENV[GUARD_KEY] = nil end end)
		end
		if not values[1] then error(values[2], 0) end
		return table.unpack(values, 2)
	end
end

local description = "unknown version"
if type(result.describe) == "function" then
	local ok_desc, desc = pcall(result.describe)
	if ok_desc and type(desc) == "string" then description = desc end
end
print("[ShadowScan loader] loaded: " .. description)
return result
