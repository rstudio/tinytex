r = xfun::tojson(lapply(tinytex:::regex_errors(), I))
xfun::write_utf8(r, 'regex.json')

r = xfun::tojson(as.list(tinytex:::.hyphen_map))
xfun::write_utf8(r, 'hyphen.json')
