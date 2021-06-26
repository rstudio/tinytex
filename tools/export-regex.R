r = xfun::tojson(lapply(tinytex:::regex_errors(), I))
xfun::write_utf8(r, 'regex.json')
