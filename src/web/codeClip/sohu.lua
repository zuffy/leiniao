
local function extract_from_sohu(pageurl, hd)
	--http://tv.sohu.com/20101125/n277903720.shtml
	--http://ott.hd.sohu.com/video/playinfo/1345544.json?api_key=7ad23396564b27116418d3c03a77db45&plat=20&sver=2.3.0&partner=806&c=7&sid=5648505
	
	local playinfo = {}
	local jumphost, jumpuri, jumpuriargs = string.match(pageurl, "http://(.-)(/[^?]*)%??(.*)")
        local res, err = ngx.location.capture("/agent", {method=ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url:"..pageurl)
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

	--ngx.header['Content-Type'] = 'text/html; charset=utf-8' 
	--ngx.say(body)
	
	local vid = string.match(body, "var%s-vid%s-=%s-\"(.-)\"")
	if not vid then
		ngx.log(ngx.ERR, "vid not found")
		return nil
	end

	--var PLAYLIST_ID="1000777"
	--var playlistId="1000777"
	local sid = string.match(body, "var%s-[pP][lL][aA][yY][lL][iI][sS][tT]_?[iI][dD]%s-=%s-\"(.-)\"")
	if not sid then
		ngx.log(ngx.ERR, "sid not found")
		return nil
	end

	local cid = string.match(body, "var%s-cid%s-=%s-\"(.-)\"") or "7"

	local jumphost = "ott.hd.sohu.com"
	local jumpuri = "/video/playinfo/"..vid..".json"
	local jumpuriargs = "api_key=7ad23396564b27116418d3c03a77db45&plat=20&sver=2.3.0&partner=806&c="..cid.."&sid="..sid

        local res, err = ngx.location.capture("/agent", {method=ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url:"..jumphost..jumpuri.."?"..jumpuriargs)
                return {["hd"]="normal", ["url"]="http://hot.vrs.sohu.com/ipad"..vid..".m3u8"}
        end

        local body = res.body
        if not body then
		ngx.log(ngx.ERR, "http resp body is nil")
                return {["hd"]="normal", ["url"]="http://hot.vrs.sohu.com/ipad"..vid..".m3u8"}
	end

	if res.header["Content-Encoding"] then
		local stream = zlib.inflate()
                body = stream(body)
        end

	local tjson = cjson.decode(body)
	if not tjson or not tjson.data then
		ngx.log(ngx.ERR, "json data is nil")
                return {["hd"]="normal", ["url"]="http://hot.vrs.sohu.com/ipad"..vid..".m3u8"}
	end
	
	local data = tjson.data
	for _, name in ipairs({"url_nor", "url_high", "url_super"}) do
		local url = data[name]
		local hd = ""
		if url and url ~= "" then
			if name == "url_nor" then
				hd = "normal"
			elseif name == "url_high" then
				hd = "high"
			else
				hd = "super"
			end
			playinfo[#playinfo + 1] = {hd=hd, url=url}
		end	
	end

	return playinfo
end