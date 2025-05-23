class Nb < Formula
  desc "Command-line and local web note-taking, bookmarking, and archiving"
  homepage "https://xwmx.github.io/nb"
  url "https://github.com/xwmx/nb/archive/refs/tags/7.18.2.tar.gz"
  sha256 "ea7353e57e83b3211a98b5e865997ccbc3b185641f98be57c789835245b505d0"
  license "AGPL-3.0-or-later"
  head "https://github.com/xwmx/nb.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "c9a26190af79c77a3b72abb535679bcf90886bed3fd6ce01bd4bfcf6c14e71db"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "c9a26190af79c77a3b72abb535679bcf90886bed3fd6ce01bd4bfcf6c14e71db"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "c9a26190af79c77a3b72abb535679bcf90886bed3fd6ce01bd4bfcf6c14e71db"
    sha256 cellar: :any_skip_relocation, sonoma:        "58e063ee568394ca01a0cb8537f48e2b85a56b0668123938e943ec229b9bccc4"
    sha256 cellar: :any_skip_relocation, ventura:       "58e063ee568394ca01a0cb8537f48e2b85a56b0668123938e943ec229b9bccc4"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "c9a26190af79c77a3b72abb535679bcf90886bed3fd6ce01bd4bfcf6c14e71db"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "c9a26190af79c77a3b72abb535679bcf90886bed3fd6ce01bd4bfcf6c14e71db"
  end

  depends_on "bat"
  depends_on "nmap"
  depends_on "pandoc"
  depends_on "ripgrep"
  depends_on "tig"
  depends_on "w3m"

  uses_from_macos "bash"

  def install
    bin.install "nb", "bin/bookmark"

    bash_completion.install "etc/nb-completion.bash" => "nb"
    zsh_completion.install "etc/nb-completion.zsh" => "_nb"
    fish_completion.install "etc/nb-completion.fish" => "nb.fish"
  end

  test do
    # EDITOR must be set to a non-empty value for ubuntu-latest to pass tests!
    ENV["EDITOR"] = "placeholder"

    assert_match version.to_s, shell_output("#{bin}/nb version")

    system "yes | #{bin}/nb notebooks init"
    system bin/"nb", "add", "test", "note"
    assert_match "test note", shell_output("#{bin}/nb ls")
    assert_match "test note", shell_output("#{bin}/nb show 1")
    assert_match "1", shell_output("#{bin}/nb search test")
  end
end
