local function get_key(t)
    local e = 0 
    for s = 0, 7 do
        e = bit.band(1, t)
        t = bit.rshift(t, 1)
        e = e * 2 ^ 31
        t = t + e 
    end 
    return tonumber("0x"..bit.tohex(bit.bxor(t, 185025305)))
end

local function tbl_has_key(tbl, key)
        for k, v in pairs(tbl) do
                if v.hd == key then
                        return true
                end
        end
        return false
end

local function extract_from_letv(pageurl, hd)
        --example url: http://www.letv.com/ptv/vplay/1560759.html
        --example url: api.letv.com/mms/out/video/play?id=1560759&platid=1&splatid=101&format=1&nextvid=2208955&tkey=307522201&domain=http%3A%2F%2Fwww.letv.com

        local playinfo = {}
	local id = string.match(pageurl, "letv.com/.+/(%w+)%.html")
        if not id then
                ngx.log(ngx.ERR, "video id not found in url, url:"..pageurl)
                return nil
        end

        local tkey = get_key(os.time())

	local jumphost = "api.letv.com"
	local jumpuri = "/mms/out/video/play"
	local jumpuriargs = "id="..id.."&platid=1&splatid=101&format=1&nextvid=2208955&tkey="..tkey.."&domain=http%3A%2F%2Fwww.letv.com"

        local res, err = ngx.location.capture("/agent", {method = ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status error, status:"..res.status..", url:"..jumphost..jumpuri.."?"..jumpuriargs)
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

        local xml_table = xml.eval(body)
        local node = xml_table:find("playurl")
	if not node then
                ngx.log(ngx.ERR, "playurl not found in xml")
                return nil
	end
	
	local playurl = node[1]

        local tjson = cjson.decode(playurl)
        if not tjson or not tjson.dispatch then
                ngx.log(ngx.WARN, "json invalid")
                return nil
        end

        local dispatch = tjson.dispatch
        for rateid, v in pairs(dispatch) do
		local hd = nil
                if rateid == "350" or rateid == "1000" then
			hd = "normal"
                elseif rateid == "1300" or rateid == "720p" then
			hd="high"
                elseif rateid == "1080p" then
			hd="super"
		else
			hd = rateid
                end
		
		local url = v[1].."&ctv=pc&m3v=1&termid=1&format=1&hwtype=un&ostype=Windows7&tag=letv&sign=letv&expect=3&tn=0.953955331351608&pay=0&rateid="..rateid

		local jumphost, jumpuri, jumpuriargs = string.match(url, "http://(.-)(/[^?]*)%??(.*)")
		local res, err = ngx.location.capture("/agent", {method = ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
		if res.status ~= ngx.HTTP_OK then
			ngx.log(ngx.ERR, "http resp status error, status:"..res.status..", url:"..jumphost..jumpuri.."?"..jumpuriargs)
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
		if not tjson then
			ngx.log(ngx.WARN, "json invalid")
			return nil
		end
		
		url = tjson.location
		if not tbl_has_key(playinfo, hd) then
			playinfo[#playinfo + 1] = {hd=hd, url=url}
		end	
        end

        return playinfo
end
