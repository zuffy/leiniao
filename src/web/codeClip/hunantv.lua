
local function extract_from_hunantv(pageurl, hd)
	--http://www.hunantv.com/v/3/50577/c/630384.html
	--code: "DD6E9B0CF066BDD5F6530279A5C1ADE7",
	--file: "%2Fjinying%2Fg%2Fjinying%2Fbokeduanpian20140228new%2Fdianyingyugao%2Fdygsl14051006.fhv",

        local playinfo = {}
	local jumphost, jumpuri, jumpuriargs = string.match(pageurl, "http://(.-)(/[^?]*)%??(.*)")

        local res, err = ngx.location.capture("/agent", {method=ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url:"..jumphost..jumpuri..jumpuriargs)
                return nil
        end

        local body = res.body
        if not body then
		ngx.log(ngx.ERR, "http resp body is nil")
		return nil
	end

	if res.header["Content-Encoding"] then
		local stream = zlib.inflate()
                body = stream(body)
        end

	local code = string.match(body, "code: \"(.-)\"")
	local file = string.match(body, "file: \"(.-)\"")
	if not code or not file then
		ngx.log(ngx.ERR, "code or file  not found")
		return nil
	end

	math.randomseed(os.time())
	local rd = math.random(10847542, 99847542)
	
	local url = "http://pcvcr.cdn.imgo.tv/ncrs/vod.do?fid="..code.."&limitrate=1099&file="..file.."&fmt=2&pno=1&random="..rd
	local jumphost, jumpuri, jumpuriargs = string.match(url, "http://(.-)(/[^?]*)%??(.*)")

        local res, err = ngx.location.capture("/agent", {method=ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url:"..jumphost..jumpuri.."?"..jumpuriargs)
                return nil
        end

        local body = res.body
        if not body then
		ngx.log(ngx.ERR, "http resp body is nil")
		return nil
	end

	if res.header["Content-Encoding"] then
		local stream = zlib.inflate()
                body = stream(body)
        end

	local tjson = cjson.decode(body)
	if not tjson or not tjson.info then
		ngx.log(ngx.ERR, "json error")
		return nil
	end
	
	playinfo[#playinfo + 1] = {hd="high", url=tjson.info}

	return playinfo

end
