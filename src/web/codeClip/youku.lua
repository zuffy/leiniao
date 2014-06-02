
local function extract_from_youku(pageurl, hd)
        --example url: http://v.youku.com/v_show/id_XMTA1OTAxMjI4.html
	--example url: http://hz.youku.com/red/redir.php?tp=1&cp=4003494&cpp=1000328&url=http%3A%2F%2Fv.youku.com%2Fv_show%2Fid_XMTk3NTQzMjk2.html
        --example url: http://v.youku.com/player/getPlayList/VideoIDS/XNjcyNDY5NzMy

        local playinfo = {}
        local id = string.match(pageurl, "id_(.+)%.html")
        if not id then
                ngx.log(ngx.ERR, "id not found in url, url:"..pageurl)
                return nil
        end

	local jumphost = "v.youku.com"
        local jumpuri = "/player/getPlayList/VideoIDS/"..id
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
	
        local tjson = cjson.decode(body)
	if not tjson or #tjson.data == 0 then
		ngx.log(ngx.ERR, "json decode err or data empty")
		return nil
	end

	local streamsizes = tjson.data[1].streamsizes 
	if not streamsizes then
		ngx.log(ngx.WARN, "streamsizes not found")
		return nil
	end
	
	for key in pairs(streamsizes) do                                                                    
		local hd = nil
		if key == "flv" then
			hd = "normal"
		elseif key == "mp4" then                                                                      
			hd = "high" 
		elseif key == "hd2" then                                                                      
			hd = "super"                                                                          
		else
			hd = key	
		end

		playinfo[#playinfo + 1] = {hd=hd, url="http://v.youku.com/player/getRealM3U8/vid/"..id.."/type/"..key.."/v.m3u8"}       
	end  
	
	if #playinfo == 0 then
		ngx.log(ngx.ERR, "#playinfo == 0")
		return nil
	end

	return playinfo
end
