
local function get_funshion_id(pageurl)
	--http://www.funshion.com/subject/play/102078/7
	--http://www.funshion.com/subject/play/96120/3/737280/20111226 
	--http://www.funshion.com/vplay/m-106602.e-30
	--http://www.funshion.com/vplay/m-110964.e-9/?alliance=155085

	local mid, sub = nil, nil
	local pos = string.find(pageurl, "vplay")
	if pos then
		mid, sub = string.match(pageurl, "vplay/m%-(%d-)%.e%-(%d+)")
	else
		mid, sub = string.match(pageurl, "subject/play/(%d-)/.-(%d+)$")
	end

	return mid, sub
end


local function extract_from_funshion(pageurl, hd)

    local playinfo = {}
	local mid, sub = get_funshion_id(pageurl)
	if not mid or not sub then
		ngx.log(ngx.ERR, "mid or sub not found in pageurl:"..pageurl)
		return nil
	end

	local url = "http://jsonfe.funshion.com/media/?cli=ipad&&ta=4&ver=1.2.11.13&jk=0&mid="..mid
	local jumphost, jumpuri, jumpuriargs = string.match(url, "http://(.-)(/[^?]*)%??(.*)")
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


	local tjson = cjson.decode(body)	
	if not tjson or not tjson.data or not tjson.data.pinfos then
		ngx.log(ngx.ERR, "json error")
		return nil
	end
	local pinfos = tjson.data.pinfos

	--data.pinfos
	--data.pinfos.fsps
	--data.pinfos.content.gylang.fsps
	--data.pinfos.content.yslang.fsps
	
	local fsps = nil
	if pinfos.content then
		if pinfos.content.gylang then
			fsps = pinfos.content.gylang.fsps
		elseif pinfos.content.yslang then
			fsps = pinfos.content.yslang.fsps
		else
			ngx.log(ngx.ERR, "content.gylang and content.yslang is nil")
			return nil
		end
	elseif pinfos.fsps then
		fsps = pinfos.fsps
	elseif pinfos.mpurls then
		pinfos.number = sub
		fsps = {pinfos}
	else
		ngx.log(ngx.ERR, "fsps is nil")
		return nil
	end
			
	if #fsps == 0 then
		ngx.log(ngx.ERR, "#fsps == 0")
		return nil
	end	

	for _, v in ipairs(fsps)
	do
		local number = v.number or "1"
		if number == sub then
			local mpurls = v.mpurls	
			if mpurls then
				for k, v in pairs(mpurls)
				do
					local hd = nil
					if k == "tv" then
						hd = "normal"
					elseif k == "dvd" then
						hd = "high"
					elseif k == "highdvd" then
						hd = "super"
					else
						hd = k
					end
					
					local url = v.url
					playinfo[#playinfo + 1] = {hd=hd, url=url}
				end
			else
				ngx.log(ngx.ERR, "mpurls is nil")
				return nil
			end
			return playinfo
		end
	end	

	return playinfo
end
