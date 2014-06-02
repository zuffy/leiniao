
local function extract_from_iqiyi(pageurl, hd)
        --example url: http://www.iqiyi.com/v_19rrgyhg0s.html
	--example url: http://cache.video.qiyi.com/m/tvid/videoid/
	--data-player-tvid="223550000"
	--data-player-videoid="8f1a0e0443d3683f918571109c005d41"
	local playinfo = {}

	local jumphost = string.match(pageurl, "(%w+%.%w+%.%w-)/")
	if not jumphost then
                ngx.log(ngx.ERR, "host not found in url:"..pageurl)                   
		return nil
	end

        local jumpuri = string.match(pageurl, "iqiyi%.com(.+%.html)")

	ngx.log(ngx.INFO, "url: "..jumphost..jumpuri)                   

        local res, err = ngx.location.capture("/agent", {method=ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status error, status:"..res.status..", url:"..jumphost..jumpuri)
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

        local tvid = string.match(body, "data%-player%-tvid=\"(.-)\"")
	local videoid = string.match(body, "data%-player%-videoid=\"(.-)\"")

	local jumphost = "cache.m.iqiyi.com"
	local jumpuri = "/m/"..tvid.."/"..videoid.."/"
        local res, err = ngx.location.capture("/agent", {method=ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status error, status:"..res.status..", url:"..jumphost..jumpuri)
                return nil
        end

	body = res.body
	if not body then
		ngx.log(ngx.ERR, "http resp body is nil")
		return nil
	end

	if res.header["Content-Encoding"] then
		local stream = zlib.inflate()
                body = stream(body)
        end


	local json = string.match(body, "({.+})")
	if not json then
		ngx.log(ngx.ERR, "json not found")
		return nil
	end

	local tjson = cjson.decode(json)
	if not tjson then
		ngx.log(ngx.ERR, "json decode failed")
		return nil
	end
	
	if not tjson.data or not tjson.data.mtl then
		ngx.log(ngx.ERR, "json invalid")
		return nil
	end
	
	local hd_map = {}
	local mtl = tjson.data.mtl
	for _, v in ipairs(mtl) do
		local vd = v.vd
		local m3u = string.gsub(v.m3u, "metal", "metan", 1)
		if vd == 96 and not hd_map["normal"] then
			hd_map["normal"] = {hd="normal", url=m3u}
		end
		if vd == 1 then
			hd_map["normal"] = {hd="normal", url=m3u}
		end
		if vd == 2 and not hd_map["high"] then
			hd_map["high"] = {hd="high", url=m3u}
		end
		if vd == 3 then
			hd_map["high"] = {hd="high", url=m3u}
		end
		if vd == 4 and not hd_map["super"] then
			hd_map["super"] = {hd="super", url=m3u}
		end
		if vd == 5 then
			hd_map["super"] = {hd="super", url=m3u}
		end
	end
	
	for _, v in pairs(hd_map) do
		playinfo[#playinfo + 1] = v
	end

	if #playinfo == 0 then
		ngx.log(ngx.ERR, "#playinfo == 0")		
		return nil
	end
	
	return playinfo
end

