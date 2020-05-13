local({
  f1 = 'tools/pkgs-custom.txt'
  x1 = sort(readLines(f1))
  writeLines(x1, f1)

  f2 = 'tools/pkgs-yihui.txt'
  x2 = setdiff(readLines(f2), readLines(f1))
  writeLines(sort(x2), f2)
})
