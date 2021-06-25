r = xfun::tojson(lapply(regex_errors(), I))
xfun::write_utf8(r, 'regex.json')
tar('regex.tar.gz', 'regex.json', 'gzip')
