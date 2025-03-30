class Dockcheck < Formula
  desc "CLI tool to automate docker image updates"
  homepage "https://github.com/mag37/dockcheck"
  url "https://github.com/mag37/dockcheck/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "1b00ab268918f2a5ee7f7836855e38bb13ed452c0fa3c5ade9ddd0a2c5589424"
  license "GPL-3.0-only"
  head "https://github.com/mag37/dockcheck.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, all: "e2bfd6f23a61930d729b915a2ff87721aa397b4793c0d7e1c6ccfba231bbaf5c"
  end

  depends_on "jq"
  depends_on "regclient"

  def install
    bin.install "dockcheck.sh" => "dockcheck"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dockcheck -v")

    output = shell_output("#{bin}/dockcheck 2>&1", 1)
    assert_match "No docker binaries available", output
  end
end
