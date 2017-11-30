class Tinytex < Formula
  desc "Tiny and easy-to-maintain LaTeX distribution based on TeXLive"
  homepage "https://github.com/yihui/tinytex"
  url "https://github.com/yihui/tinytex/archive/v0.0.tar.gz"
  sha256 "63fcf687035dfe1f07d0cb171ba97513a27ccd91adae5c983ba8d6a6c642a16c"
  head "https://github.com/yihui/tinytex/archive/master.tar.gz"

  def install
    cd "tools" do
      system "make && make bin"
      prefix.install Dir["texlive/", "bin/"]
    end
  end

  def post_install
    # symlink texlive/bin/*/* to bin again (may need this after `tlmgr install`)
    cd bin.to_s do
      system "rm * && ln -s ../texlive/bin/*/* ./"
    end
  end

  test do
    system "#{bin}/pdflatex", "--version"
    system "#{bin}/xelatex",  "--version"
    system "#{bin}/lualatex", "--version"

    (testpath/"test.tex").write <<~EOS
      \\nonstopmode
      \\documentclass{article}
      \\usepackage{graphics}
      \\title{Hello World}
      \\author{John Doe}
      \\begin{document}
      \\maketitle
      This is a \\emph{test} document.

      A simple math expression: $$S_n=\\sum X_{i=1}^n$$
      \\end{document}
    EOS

    system "#{bin}/pdflatex", "test.tex"
    assert_predicate testpath/"test.pdf", :exist?, "Failed to compile to PDF via pdflatex"
    system "rm test.pdf"

    system "#{bin}/xelatex",  "test.tex"
    assert_predicate testpath/"test.pdf", :exist?, "Failed to compile to PDF via xelatex"
    system "rm test.pdf"

    system "#{bin}/lualatex", "test.tex"
  end
end
