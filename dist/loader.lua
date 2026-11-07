--!nonstrict
-- ShadowScan loader  v0.4.3  build 318b5e6ecaf9
-- GENERATED from loader/loader.template.lua by tools/build.py (version, build id and bundle hash are pinned below).
--
-- What this file does:
--   1. checks the executor has what it needs (loadstring + readfile OR a pinned URL source + http for a localhost companion)
--   2. reads the bundle from the executor workspace (default) -- no network needed
--   3. verifies the bundle's SHA-256 against EXPECTED_BUNDLE_SHA256 and REFUSES to run on any mismatch
--   4. runs the bundle and returns the ShadowScan API object
--
-- What it never does: ask for credentials/cookies/tokens, embed private keys, follow a moving branch (main/master),
-- run code that failed the hash check, or send anything anywhere.
--
-- TRUST NOTE: this loader is the trust anchor. Verify the sha256 of THIS file against RELEASE.json / the signed
-- release tag you received out-of-band before you run it. See docs/RELEASE.md.
--
-- Usage:   local ss = loadstring(readfile("ShadowScan/loader.lua"))({ audit_mode = "passive" })

local config = ... or {}

local VERSION = "0.4.3"
local BUILD_ID = "318b5e6ecaf9"
local EXPECTED_BUNDLE_SHA256 = "00cfa2ec192ec4236c6a33df9243745e7711b81fb297e553047fb61d5064bcf4"

-- Source of the bundle. "workspace" (default) reads BUNDLE_PATH with readfile.
-- "url" downloads BUNDLE_URL, which MUST be pinned to a 40-hex commit or a vX.Y.Z tag; branches are rejected.
local BUNDLE_SOURCE = config.bundle_source or "workspace"
local BUNDLE_PATH = config.bundle_path or "ShadowScan/shadowscan.bundle.lua"
local BUNDLE_URL = config.bundle_url -- shape: https://<host>/<org>/<repo>/<40-hex-commit>/dist/shadowscan.bundle.lua

local function log(msg) print("[ShadowScan loader] " .. msg) end

local function fail(msg)
	log("REFUSING TO START: " .. msg)
	error("ShadowScan loader: " .. msg, 0)
end

local sha256 = (function()
-- Pure-Luau SHA-256 (FIPS 180-4). Used for bundle integrity and plan fingerprints.
-- No dependency on executor crypto APIs (their semantics differ between executors).
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

local M = {}

function M.hex(msg)
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

return M

end)()

local function genv()
	local ok, g = pcall(function() return getgenv and getgenv() end)
	return (ok and g) or _G
end
local G = genv()

-- Capture the DataModel from the loader's own execution environment. Some executors expose
-- `game` as a script global but omit it from getgenv() and _G; Main must not infer it only
-- from those tables. This is a read-only reference to the current Roblox DataModel.
local runtime_game
do
	local ok, value = pcall(function() return game end)
	if ok and value ~= nil then runtime_game = value end
end

local function cap(name)
	local v = rawget(G, name)
	if v == nil then
		local ok, r = pcall(function() return _G[name] end)
		v = ok and r or nil
	end
	return v
end

-- ---------------------------------------------------------------- environment compatibility
local loadstring_fn = cap("loadstring") or loadstring
if type(loadstring_fn) ~= "function" then
	fail("this executor does not provide loadstring; ShadowScan cannot run here (not verified on any executor yet)")
end

local function is_pinned_url(url)
	if type(url) ~= "string" then return false end
	if not string.match(url, "^https://") then return false end
	if string.match(url, "/refs/heads/") then return false end
	if string.match(url, "/main/") or string.match(url, "/master/") or string.match(url, "/HEAD/") then return false end
	return string.match(url, "/%x+/") ~= nil and (string.match(url, "/" .. string.rep("%x", 40) .. "/") ~= nil)
		or string.match(url, "/v%d+%.%d+%.%d+/") ~= nil
end

local source_text
if BUNDLE_SOURCE == "workspace" then
	local readfile_fn = cap("readfile")
	if type(readfile_fn) ~= "function" then
		fail("readfile is unavailable. Use bundle_source='url' with a pinned URL, or an executor with a workspace folder.")
	end
	local ok, data = pcall(readfile_fn, BUNDLE_PATH)
	if not ok or type(data) ~= "string" or #data == 0 then
		fail("cannot read " .. BUNDLE_PATH .. " from the executor workspace. Copy dist/shadowscan.bundle.lua there (see README).")
	end
	source_text = data
elseif BUNDLE_SOURCE == "url" then
	if not is_pinned_url(BUNDLE_URL) then
		fail("bundle_url must be https and pinned to a 40-hex commit or a vX.Y.Z tag (branches like main are rejected)")
	end
	local req = cap("request") or cap("http_request")
	if type(req) ~= "function" then fail("no HTTP request function available for bundle_source='url'") end
	local ok, res = pcall(req, { Url = BUNDLE_URL, Method = "GET" })
	local body = ok and type(res) == "table" and (res.Body or res.body)
	local status = ok and type(res) == "table" and (res.StatusCode or res.status_code)
	if not body or status ~= 200 then fail("download failed (status " .. tostring(status) .. ")") end
	source_text = body
else
	fail("unknown bundle_source '" .. tostring(BUNDLE_SOURCE) .. "'")
end

-- ---------------------------------------------------------------- integrity gate
local actual = sha256.hex(source_text)
if actual ~= EXPECTED_BUNDLE_SHA256 then
	fail(string.format("integrity check FAILED (expected %s..., got %s...). The bundle was modified or is a different version.",
		string.sub(EXPECTED_BUNDLE_SHA256, 1, 12), string.sub(actual, 1, 12)))
end
log(string.format("bundle integrity OK (sha256 %s...)", string.sub(actual, 1, 12)))

local chunk, err = loadstring_fn(source_text, "=ShadowScan")
if not chunk then fail("bundle failed to compile: " .. tostring(err)) end
local ok_run, ss_require = pcall(chunk)
if not ok_run or type(ss_require) ~= "function" then fail("bundle failed to initialise: " .. tostring(ss_require)) end

local Main = ss_require("client.main")
local session = Main.new({
	globals = G,
	deps = { game = runtime_game },
	loader_info = { version = VERSION, build_id = BUILD_ID, bundle_sha256 = actual, source = BUNDLE_SOURCE },
	config = config,
})
pcall(function() G.ShadowScan = session end)
if config.ui ~= false then
	-- the GUI is the default front end; pass { ui = false } for the console-only API
	local ok_ui, err_ui = pcall(function() return session:open_ui(config.ui_options) end)
	if not ok_ui then log("GUI could not start (" .. tostring(err_ui) .. "); the console API still works") end
end
return session
