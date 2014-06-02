(function () {
    'use strict';
    var $ = Zepto;
    var title = util.getUriValue('title'),
        site = util.getUriValue('site') || "iqiyi.com",
        ref = util.getUriValue('refUrl') || "http://www.iqiyi.com/v_19rrgyhg0s.html" || "http://www.funshion.com/vplay/m-110964.e-9/?alliance=155085" || "http://v.youku.com/v_show/id_XNzIwMDExNzQ4.html" ||"http://www.letv.com/ptv/vplay/20117525.html",
        id = util.getUriValue('id'),
        tag = util.getUriValue('tag'),
        action = util.getUriValue('action') || 'play',
        which = util.getUriValue('which'),
        copyright = util.getUriValue('copyright');
    /*(function(t){
        var e = 0;
            for (var s = 0; s < 8; s++){
                console.log(s);
                e = 1 & t;
                console.log(e);
                t = t>>1;
                console.log(t);
                e = e * Math.pow(2,31);
                console.log(e);
                t = t + e 
                console.log('========='+t);
            }
            console.log(t);
            console.log(t|185025305);
    })(1234567890);*/

    var extract_fun_map = {
        "youku.com": vodUrl.extract_from_youku,
        "letv.com": vodUrl.extract_from_letv,
        "qq.com": vodUrl.extract_from_qq,
        "funshion.com": vodUrl.extract_from_funshion,
        "iqiyi.com": vodUrl.extract_from_iqiyi,
        "sohu.com": vodUrl.extract_from_sohu,
        "hunantv.com": vodUrl.extract_from_hunantv
    }

    var exptime_map = {
        "youku.com": 7200,
        "funshion.com": 7200,
        "iqiyi.com": 7200,
        "letv.com": 180,
        "qq.com": 180,
        "sohu.com": 7200,
        "hunantv.com": 30
    }

    var header_map = {
        "youku.com": {},
        "funshion.com": {},
        "iqiyi.com": {"User-Agent": "AppleCoreMedia/1.0.0.9A405 (iPad; U; CPU OS 5_0_1 like Mac OS X; zh_cn)"},
        "letv.com": {},
        "qq.com": {},
        "sohu.com": {},
        "hunantv.com": {"User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.146 Safari/537.36"}
    }
    var callback ="";
    var hd = "normal";
    var key = ref;
    var extract_fun = extract_fun_map[site] || extract_default_fun;
    
    extract_fun(key, hd, function(info_arr) {
        var playinfo = info_arr;
        if (typeof playinfo == "undefined") {
            console.log('playinfo is nil');
            send_err_resp(404, "Not Found", callback);
            return;
        }
        else{
            var str, ret_table = {};
            ret_table.rtn = 0
            ret_table.playinfo = playinfo
            ret_table.http_header_info = header_map[site]
            str = JSON.stringify(ret_table);
        }

        function send_err_resp(){

        }
        //回调...
    });

})();