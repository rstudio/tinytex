r = xfun::tojson(lapply(tinytex:::regex_errors(), I))
xfun::write_utf8(r, 'regex.json')

r = xfun::tojson(as.list(tinytex:::.hyphen_map))
xfun::write_utf8(r, 'hyphen.json')

# the maps behind the babel .ini locale detection (#519), for consumers that
# port the detection (e.g. quarto-cli); kept out of hyphen.json, whose values
# are all TeX Live package names
r = xfun::tojson(list(
  hyphen_synonyms = as.list(tinytex:::.hyphen_synonyms),
  babel_hyphen_map = as.list(tinytex:::.babel_hyphen_map),
  babel_hyphen_codes = as.list(tinytex:::.babel_hyphen_codes)
))
xfun::write_utf8(r, 'babel-hyphen.json')
