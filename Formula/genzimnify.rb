class Genzimnify < Formula
  desc "Native, Python-free programming language with Gen Z syntax"
  homepage "https://github.com/Obliv1onis/Genzimnify"
  head "https://github.com/Obliv1onis/Genzimnify.git", branch: "master"
  license "MIT"

  depends_on arch: :arm64
  depends_on "nim" => :build

  def install
    system "nim", "c", "-d:release", "--out:#{bin}/gzim", "src/gzim.nim"
    system "nim", "c", "-d:release", "--out:#{bin}/gzim-lsp", "src/gzimlsp.nim"
  end

  test do
    assert_match "native Nim (Python-free)", shell_output("#{bin}/gzim doctor")
    (testpath/"hello.gzim").write <<~EOS
      yap("no cap")
    EOS
    assert_equal "no cap\n", shell_output("#{bin}/gzim hello.gzim")
  end
end
