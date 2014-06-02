

local function follow(html)
        --<meta http-equiv="content-type" content="text/html;charset=utf-8" /><meta http-equiv="refresh" content="0; url=/page/j/h/6/j00143rgwh6.html" />
        --<meta http-equiv="Refresh" content="5;url=http://film.qq.com/cover/v/vhilxy2artzt8a5.html?ADTAG=INNER.TXV.COVER.REDIR">                                                                                            
        --vid:"n00141q4hky"
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
