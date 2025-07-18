class Libebur128 < Formula
  desc "Library implementing the EBU R128 loudness standard"
  homepage "https://github.com/jiixyj/libebur128"
  url "https://github.com/jiixyj/libebur128/archive/refs/tags/v1.2.6.tar.gz"
  sha256 "baa7fc293a3d4651e244d8022ad03ab797ca3c2ad8442c43199afe8059faa613"
  license "MIT"

  no_autobump! because: :requires_manual_review

  bottle do
    sha256 cellar: :any,                 arm64_sequoia:  "2112e1314f1796a63c7a5477ef24fbdeb91ca32b4d8ff57d5e6527e69a829d9f"
    sha256 cellar: :any,                 arm64_sonoma:   "91ca5b466a5bf36b1f9d9a1d7cd3f870d1d519fbce52b790192e3f5998976193"
    sha256 cellar: :any,                 arm64_ventura:  "c0253f875a0adcd097d523191b855d597d602731e73dc039d4ce707373674d5f"
    sha256 cellar: :any,                 arm64_monterey: "d77d92a90aa8dfcb7642efe678d02804a0a9d0c172e43e005499120ead01b3b8"
    sha256 cellar: :any,                 arm64_big_sur:  "99450597a660d645800d8d0488b657efee8d7ff9b886a80f964fe3394c8a2552"
    sha256 cellar: :any,                 sonoma:         "63d0d10ecbffeab12456962728b12b62d36645536f3255885b18a879cecf3310"
    sha256 cellar: :any,                 ventura:        "e6b85bc2e07ac3e7b4d3ab8a9a05f7a2cde5e6377b5f2898e454acb598a82ff0"
    sha256 cellar: :any,                 monterey:       "6a1d7c49352c44807fbddff035842984a6d2e320d4d0625fd2271752246bcdfb"
    sha256 cellar: :any,                 big_sur:        "43567ee920b45921fb0d7787f40d3274ff42360c3048df470aee33be902694e7"
    sha256 cellar: :any,                 catalina:       "a9612342890303e8859ee23c7ce8d154f1d3eb134158322aa4ca0968d471281a"
    sha256 cellar: :any,                 mojave:         "ebe29eb9b5918eabf720410feb2ac711f5b062458e1d3129ffd29fb7da0f66b5"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "a6a0b3d33651d9c7352b6178c3d98ab9ac932ae9d2a10242a1267feb513f2838"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "9f9bf1bedd635dce44252d8abf9ab008d53275ff1fc35ae7522685e403b5cdac"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "speex"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <ebur128.h>
      int main() {
        ebur128_init(5, 44100, EBUR128_MODE_I);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lebur128", "-o", "test"
    system "./test"
  end
end
