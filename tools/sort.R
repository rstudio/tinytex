local({
  f1 = 'tools/pkgs-custom.txt'
  x1 = sort(scan(f1, 'character'))
  writeLines(x1, f1)

  f2 = 'tools/pkgs-yihui.txt'
  x2 = setdiff(scan(f2, 'character'), scan(f1, 'character'))
  writeLines(sort(x2), f2)
})
