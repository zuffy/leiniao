local cjson = require "cjson"
local xml = require "xml"
local zlib = require "zlib"
local common = require "common"
local tb_tostring = require "tb_tostring"
local hd_map =  common.hd_map
local gb_2_utf8 = common.gb_2_utf8
local send_err_resp = common.send_err_resp

local args = ngx.req.get_uri_args()

local site = args.site
local pageurl = args.url
local hd = args.hd
local callback = args.callback

if not site or site == "" then
        ngx.log(ngx.ERR, "site invalid")
	send_err_resp(400, "Bad Request", callback)
	return
end

if not pageurl or pageurl == "" then
        ngx.log(ngx.ERR, "url invalid")
	send_err_resp(400, "Bad Request", callback)
	return
end

local allow = common.check_validate()
if not allow then
        ngx.log(ngx.ERR, "user authentication failed")
	send_err_resp(403, "Forbidden", callback)
	return
end

local tbl_name = "media_playurl_cache"

local db, err =  common.init_media_db_conn()
if not db then
        ngx.log(ngx.ERR, "init db conn failed, err="..err)
	send_err_resp(500, "Internal Server Error", callback)
	return
end

local memc, err = common.init_memcached_conn(common.vodurl_memcached_host, common.vodurl_memcached_port)
if not memc then
	ngx.log(ngx.ERR, "init memcached conn failed, err="..err)
end


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


local function follow(html)
        --<meta http-equiv="content-type" content="text/html;charset=utf-8" /><meta http-equiv="refresh" content="0; url=/page/j/h/6/j00143rgwh6.html" />
        --<meta http-equiv="Refresh" content="5;url=http://film.qq.com/cover/v/vhilxy2artzt8a5.html?ADTAG=INNER.TXV.COVER.REDIR">                                                                                            
        
        local refresh_url = string.match(html, "<meta http%-equiv=\"[Rr]efresh.-url=(.-html)")           
        ngx.log(ngx.INFO, "refresh url:"..refresh_url)

        local jumphost, jumpuri, reg = nil, nil, nil
        if string.find(refresh_url, "qq.com") then
		jumphost = "film.qq.com"
        else
                jumphost = "v.qq.com"
        end

        jumpuri = string.match(refresh_url, "qq.com(.+)")                                       
        if not jumpuri then
                jumpuri = refresh_url
        end

        local res, err = ngx.location.capture("/agent", {method = ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri}})
        if res.status ~= ngx.HTTP_OK then                                                             
		ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url:"..jumphost..jumpuri)                     
		return nil                                                                            
        end

        local body = res.body
        if not body then
                ngx.log(ngx.ERR, "http resp data empty, refresh url:"..refresh_url)                   
                return nil                                                                            
        end
                                                                                                      
        if res.header["Content-Encoding"] then
                local stream = zlib.inflate()                                                         
                body = stream(body)                                                                   
        end

        return string.match(body, "vid:\"(%w+)")      
end


local function get_qq_vid(pageurl)
        --example url: http://v.qq.com/cover/g/dk6z4x5v536r3fz.html

	local jumphost = string.match(pageurl, "(%w+%.%w+%.%w-)/")
	if not jumphost then
                ngx.log(ngx.ERR, "host not found in url:"..pageurl)                   
                return nil                                                                            
	end

        local jumpuri = string.match(pageurl, "qq.com(.+%.html)")

        local res, err = ngx.location.capture("/agent", {method = ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url: "..jumphost..jumpuri)
                return nil
        end

        local body = res.body
        if not body then
                ngx.log(ngx.ERR, "http resp data empty, url:"..pageurl)
                return nil
        end

	if res.header["Content-Encoding"] then
		local stream = zlib.inflate()
		body = stream(body)
	end

        local id = string.match(body, "vid:\"(%w+)")
	if not id then
		id = follow(body)
	end
	return id
end


local function extract_from_qq(pageurl, hd)
        --example url: http://vv.video.qq.com/geturl?vid=s0013bxbbd0&otype=xml&platform=1&ran=0.9652906153351068

        local playinfo = {}
        local id = get_qq_vid(pageurl)
        if not id then
                ngx.log(ngx.ERR, "id not found, url:"..pageurl)
                return nil
        end

        local url = "http://vv.video.qq.com/geturl?vid="..id.."&otype=xml&platform=1&ran=0.9652906153351068"
	local jumphost = "vv.video.qq.com"
	local jumpuri = "/geturl"
	local jumpuriargs = "vid="..id.."&otype=xml&platform=1&ran=0.9652906153351068"

	ngx.log(ngx.INFO, "url: "..jumphost..jumpuri.."?"..jumpuriargs)
        local res, err = ngx.location.capture("/agent", {method = ngx.HTTP_GET, vars={jumphost=jumphost, jumpuri=jumpuri, jumpuriargs=jumpuriargs}})
        if res.status ~= ngx.HTTP_OK then
                ngx.log(ngx.ERR, "http resp status not ok, status:"..res.status..", url: "..jumphost..jumpuri.."?"..jumpuriargs)
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

        local urlinfo = xml_table:find("url")
	if not urlinfo then	
		ngx.log(ngx.ERR, "url not found in xml")
		return nil
	end

	local url = urlinfo[1]
        playinfo[#playinfo + 1] = {hd="normal", url=url}
        return playinfo
end


local function extract_from_iqiyi(pageurl, hd)
        --example url: http://www.iqiyi.com/v_19rrgyhg0s.html
	--example url: http://cache.video.qiyi.com/m/tvid/videoid/

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


local function extract_from_db(pageurl, hd)
	local playinfo = {}

        local sql = "SELECT url, spec_id FROM "..tbl_name.." WHERE pageurl="..ngx.quote_sql_str(pageurl).." AND video_type='ts' ".." GROUP BY spec_id"
        ngx.log(ngx.INFO, "sql:"..sql)
        local res, err = db:query(sql)
        if not res then
		ngx.log(ngx.ERR, "db:query failed, err="..err)
		return nil
        elseif #res == 0 then
                ngx.log(ngx.INFO, "#res == 0")
                return nil
        else
                for _, v in ipairs(res) do
                        playinfo[#playinfo + 1] = {hd=hd_map[v.spec_id], url=v.url}
                end
        end

        return playinfo
end


local function strip(s)
	local lstrip = string.gsub(s, "^[%s\"]*", "")
	local rstrip = string.gsub(lstrip, "[%s\"]*$" , "")
	return rstrip
end


local function extract_from_sohu(pageurl, hd)
	--http://tv.sohu.com/20101125/n277903720.shtml
	--http://ott.hd.sohu.com/video/playinfo/1345544.json?api_key=7ad23396564b27116418d3c03a77db45&plat=20&sver=2.3.0&partner=806&c=7&sid=5648505

        local playinfo = extract_from_db(pageurl, hd)
	if playinfo then
		return playinfo
	end
	
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


local function extract_from_hunantv(pageurl, hd)
	--http://www.hunantv.com/v/3/50577/c/630384.html
	--

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
        local playinfo = extract_from_db(pageurl, hd)
	if playinfo then
		return playinfo
	end

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




local function extract_default_fun(pageurl, hd)
	ngx.log(ngx.ERR, "site invalid, pageurl:"..pageurl)
	return nil
end
	

local extract_fun_map = {
	["youku.com"] = extract_from_youku,
	["letv.com"] = extract_from_letv,
	["qq.com"] = extract_from_qq,
	["funshion.com"] = extract_from_funshion,
	["iqiyi.com"] = extract_from_iqiyi,
	["sohu.com"] = extract_from_sohu,
	["hunantv.com"] = extract_from_hunantv
}

local exptime_map = {
	["youku.com"] = 7200,
	["funshion.com"] = 7200,
	["iqiyi.com"] = 7200,
	["letv.com"] = 180,
	["qq.com"] = 180,
	["sohu.com"] = 7200,
	["hunantv.com"] = 30
}

local header_map = {
	["youku.com"] = {},
	["funshion.com"] = {},
	["iqiyi.com"] = {["User-Agent"] = "AppleCoreMedia/1.0.0.9A405 (iPad; U; CPU OS 5_0_1 like Mac OS X; zh_cn)"},
	["letv.com"] = {},
	["qq.com"] = {},
	["sohu.com"] = {},
	["hunantv.com"] = {["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.146 Safari/537.36"}
}


local str = nil
local ret_table = {}
local key = pageurl


if memc then
	local res, flags, err = memc:get(key)
	if err then
		ngx.log(ngx.ERR, "memcached get error, key: "..key..", err: "..err)
	elseif res then
		ngx.log(ngx.INFO, "memcached find key:"..key)
		str = res	
	else
		ngx.log(ngx.INFO, "memcached not find key: "..key)
	end
else
	ngx.log(ngx.ERR, "memcached server error")
end

if not str then
	local extract_fun = extract_fun_map[site] or extract_default_fun
	local playinfo = extract_fun(key, hd)
	if not playinfo then
		ngx.log(ngx.ERR, "playinfo is nil") 
		send_err_resp(404, "Not Found", callback)
		return 
	else
		ret_table.rtn = 0
		ret_table.playinfo = playinfo
		ret_table.http_header_info = header_map[site]
		str = cjson.encode(ret_table)
		if str and memc then
			ngx.log(ngx.INFO, "memcached set key: "..key)
			local exptime = exptime_map[site]
			local ok, err = memc:set(key, str, exptime)
			if not ok then
				ngx.log(ngx.ERR, "memcached set key failed, key:"..key..", err:"..err)
			end
		end
	end
end

if db then
        common.finalize_media_db_conn(db, true)
end

if memc then
	common.finalize_memcached_conn(memc, true)
end

local callback_begin, callback_end = "", ""
if callback and callback ~= "" then
	callback_begin = callback.."("
	callback_end = ")"
end

local resp_str = callback_begin..str..callback_end

common.say_back(resp_str)
