# generate R/hyphen.R with three maps:
# - .hyphen_map: names of hyphenation languages -> TeX Live packages, for the
#   names that are not simply hyphen-<name>; from `execute AddHyphen` in
#   texlive.tlpdb
# - .hyphen_synonyms: language.dat synonyms -> canonical names; from the
#   synonyms= field of the same AddHyphen lines (a name and its synonyms are
#   the same set of patterns, e.g. ngerman-x-latest -> ngerman-x-2024-02-28)
# - .babel_hyphen_map: babel locale names -> expected hyphenation language;
#   from the name.babel aliases and the hyphenrules value of the babel-*.ini
#   files in the local TeX installation (used to detect babel falling back to
#   the current \language when patterns are missing, rstudio/tinytex#519)
# run this script from the root directory of the package, and optionally pass
# a local copy of texlive.tlpdb as the argument

f = commandArgs(TRUE)[1]
if (is.na(f)) {
  f = tempfile(fileext = '.tlpdb')
  on.exit(unlink(f), add = TRUE)
  download.file('https://tlnet.yihui.org/tlpkg/texlive.tlpdb', f, mode = 'wb')
}
x = readLines(f, warn = FALSE)

# the package of each line is the last `name <pkg>` line before it (this
# includes packages that are not hyphen-*, e.g., dehyph-exptl)
i = grep('^name ', x)
pkg = sub('^name ', '', x[i])[findInterval(seq_along(x), i)]
k = grep('^execute AddHyphen ', x)
if (length(k) < 50) stop('Too few AddHyphen lines found: ', length(k))
a = x[k]
# a language name and all its synonyms point to the same package
nm = sub('.*\\bname=([^[:space:]]+).*', '\\1', a, perl = TRUE)
syn = ifelse(
  grepl('synonyms=', a),
  sub('.*synonyms=([^[:space:]]+).*', '\\1', a, perl = TRUE), ''
)
nms = mapply(
  function(n, s) c(n, if (nzchar(s)) strsplit(s, ',')[[1]]), nm, syn,
  SIMPLIFY = FALSE
)
d = unique(data.frame(
  name = tolower(unlist(nms)), pkg = rep(pkg[k], lengths(nms))
))

# names are later passed to tlmgr, so make sure they look like package names
r = '^[a-z0-9-]+$'
if (any(b <- !grepl(r, d$name))) stop('Invalid language names: ', toString(d$name[b]))
if (any(b <- duplicated(d$name))) stop('Names defined by multiple packages: ', toString(d$name[b]))

# synonyms -> canonical name (the name= of their AddHyphen line)
s = do.call(c, unname(mapply(function(n, s0) {
  if (nzchar(s0)) {
    g = strsplit(s0, ',')[[1]]
    stats::setNames(rep(n, length(g)), g)
  }
}, nm, syn, SIMPLIFY = FALSE)))
s = stats::setNames(tolower(s), tolower(names(s)))
# case-variant synonyms of the canonical name itself (UKenglish -> ukenglish)
s = s[names(s) != s]
if (any(b <- names(s) %in% tolower(nm))) stop(
  'Names that are both synonyms and canonical names: ', toString(names(s)[b])
)

# babel locale names -> hyphenrules value, from the local TeX installation
texmfdist = system2('kpsewhich', '-var-value=TEXMFDIST', stdout = TRUE)
inis = list.files(
  file.path(texmfdist, 'tex/generic/babel/locale'),
  'babel-.*[.]ini$', recursive = TRUE, full.names = TRUE
)
if (length(inis) < 300) stop('Too few babel .ini files found: ', length(inis))
get_key = function(x, key) {
  v = grep(sprintf('^%s\\s*=\\s*', key), x, value = TRUE)
  if (length(v) == 0) return(NA_character_)
  trimws(sub(sprintf('^%s\\s*=\\s*', key), '', v[1]))
}
# parse each .ini file: base name (as written in the log messages),
# hyphenrules value, and babel locale name aliases
ini = lapply(inis, function(f) {
  x = readLines(f, warn = FALSE)
  hr = tolower(get_key(x, 'hyphenrules'))
  nb = get_key(x, 'name.babel')
  # 'unhyphenated' means the language is not hyphenated: like an empty value
  if (is.na(hr) || hr %in% c('', 'unhyphenated')) hr = NA
  list(
    code = tolower(sub('^babel-(.*)[.]ini$', '\\1', basename(f))),
    hyphen = hr, file = basename(f),
    locale = if (!is.na(nb) && nb != '') tolower(strsplit(nb, '\\s+')[[1]])
  )
})
# valid hyphenation language names: tlpdb names plus 'english', which is
# hardcoded in language.dat (english hyphen.tex) without an AddHyphen line
valid = c(d$name, 'english')
# a hyphenrules value that is not a language.dat name cannot resolve to
# installed patterns (e.g., 'assaseme' in babel-as.ini), so babel would always
# fall back; ignore it instead of installing a package that does not exist
unk = unlist(lapply(ini, function(z) {
  if (!is.na(z$hyphen) && !z$hyphen %in% valid)
    sprintf('%s (%s)', z$hyphen, toString(z$locale))
}))
if (length(unk)) warning('Ignoring unknown hyphenrules values: ', toString(unique(unk)))
ini = lapply(ini, function(z) {
  if (!is.na(z$hyphen) && !z$hyphen %in% valid) z$hyphen = NA
  z
})

# .ini file base name -> hyphenrules value; used when the document language
# has a custom name (\babelprovide[import=es]{myspanish}), in which case the
# locale name in the log is the custom name and only the .ini file name
# points to the expected patterns
m3 = stats::setNames(sapply(ini, '[[', 'hyphen'), sapply(ini, '[[', 'code'))
m3 = m3[!is.na(m3)]
if (any(i <- !grepl('^[a-z0-9-]+$', names(m3)))) {
  warning('Ignoring invalid .ini base names: ', toString(names(m3)[i]))
  m3 = m3[!i]
}
m3 = m3[order(names(m3), method = 'radix')]

b = do.call(rbind, lapply(ini, function(z) {
  if (is.null(z$locale)) return(NULL)  # e.g. locale/shared/babel-Arab.ini
  data.frame(
    locale = z$locale, file = z$file,
    # with an empty hyphenrules, babel has no other name to look up, so the
    # locale name itself is the expected pattern if it is a valid
    # hyphenation language name (e.g., swissgerman); otherwise no patterns
    # are expected for this locale (e.g., chinese)
    hyphen = if (!is.na(z$hyphen)) z$hyphen else z$locale
  )
}))
b = b[b$hyphen %in% valid, ]
r2 = '^[a-z0-9.-]+$'  # babel locale names may contain dots (serbianc.ijekav)
if (any(i <- !grepl(r2, b$locale))) {
  warning('Ignoring invalid babel locale names: ', toString(b$locale[i]))
  b = b[!i, ]
}
# locale names shared by several .ini files (e.g., 'austrian' in babel-de-AT,
# babel-de-AT-1901, and babel-de-AT-1996) are resolved by babel to the file
# with the shortest name (verified against logs of \babelprovide[import])
b = b[order(b$locale, nchar(b$file), b$file, method = 'radix'), ]
if (any(i <- duplicated(b$locale))) {
  warning(
    'Babel locale names defined by multiple .ini files (keeping ',
    'the shortest file name): ', toString(b$locale[i])
  )
  b = b[!i, ]
}
b = b[order(b$locale, method = 'radix'), ]
m2 = stats::setNames(b$hyphen, b$locale)

# only keep the exceptions to the rule that language xxx is in hyphen-xxx
d = d[paste0('hyphen-', d$name) != d$pkg, ]
d = d[order(d$name, method = 'radix'), ]

format_map = function(m) {
  # use ~ as a placeholder so that strwrap() doesn't break lines inside entries
  x = strwrap(
    paste0(sprintf("'%s'~=~'%s'", names(m), m), collapse = ', '), 78,
    indent = 2, exdent = 2
  )
  gsub('~', ' ', x, fixed = TRUE)
}
xfun::write_utf8(c(
  '# maps related to hyphenation patterns; generated by tools/update-hyphen.R,',
  '# do not edit',
  '',
  '# from the names of hyphenation languages to the TeX Live packages that',
  '# provide them, for the names that are not simply hyphen-<name>; from',
  '# `execute AddHyphen` in texlive.tlpdb',
  '.hyphen_map = c(', format_map(stats::setNames(d$pkg, d$name)), ')',
  '',
  '# from language.dat synonyms to canonical names (a name and its synonyms',
  '# are the same set of patterns); from the synonyms= field of `execute',
  '# AddHyphen` in texlive.tlpdb',
  '.hyphen_synonyms = c(', format_map(s), ')',
  '',
  '# from babel locale names to the hyphenation language they expect (the',
  '# hyphenrules value of their babel-*.ini file)',
  '.babel_hyphen_map = c(', format_map(m2), ')',
  '',
  '# from babel-*.ini file base names (as written in the log messages) to',
  '# their hyphenrules value; used when the document language has a custom',
  '# name (e.g., \\babelprovide[import=es]{myspanish})',
  '.babel_hyphen_codes = c(', format_map(m3), ')'
), 'R/hyphen.R')
