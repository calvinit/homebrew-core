class Openjdk < Formula
  desc "Development kit for the Java programming language"
  homepage "https://openjdk.java.net/"
  url "https://github.com/openjdk/jdk24u/archive/refs/tags/jdk-24-ga.tar.gz"
  sha256 "62cfe6846267a31edb1a4f451b1b1c6fddd25b7ec8522d32387f5450963b9996"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }

  livecheck do
    url :stable
    regex(/^jdk[._-]v?(\d+(?:\.\d+)*)-ga$/i)
  end

  bottle do
    sha256 cellar: :any, arm64_sequoia: "1285eadf2b5998cda49e4470ee3875e855b0be199765401ad77dc38aea573f49"
    sha256 cellar: :any, arm64_sonoma:  "1cccc8bb39130612a61ff9d18a208ec232b86a21d646748a7af3f3f693eab804"
    sha256 cellar: :any, arm64_ventura: "bb9bc5a4c4128b4c61a99d419026811f7f5fcf3ac243b1e393449aa680715d36"
    sha256 cellar: :any, sonoma:        "e0999137182b5abc4e0738330f4d9cb2f45b4d9642deffed420c0e7be4f337e8"
    sha256 cellar: :any, ventura:       "f5effdfcbab956c20d0f65bdc504ac27723d81d9fe940abadf81764782881650"
    sha256               x86_64_linux:  "a7bd3a62568d49149d566ed5cf98ec8a5cd2ab130019918ce42c8eaeb268b45b"
  end

  keg_only :shadowed_by_macos

  depends_on "autoconf" => :build
  depends_on "pkgconf" => :build
  depends_on xcode: :build # for metal
  depends_on "freetype"
  depends_on "giflib"
  depends_on "harfbuzz"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "little-cms2"
  depends_on macos: :catalina

  uses_from_macos "cups"
  uses_from_macos "unzip"
  uses_from_macos "zip"
  uses_from_macos "zlib"

  on_linux do
    depends_on "alsa-lib"
    depends_on "fontconfig"
    depends_on "libx11"
    depends_on "libxext"
    depends_on "libxi"
    depends_on "libxrandr"
    depends_on "libxrender"
    depends_on "libxt"
    depends_on "libxtst"
  end

  # From https://jdk.java.net/archive/
  resource "boot-jdk" do
    on_macos do
      on_arm do
        url "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_macos-aarch64_bin.tar.gz"
        sha256 "bff699bb27455c2bb51d6e8f2467b77a4833388412aa2d95ec1970ddfb0e7b6c"
      end
      on_intel do
        url "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_macos-x64_bin.tar.gz"
        sha256 "b4cc7d7b51520e99308e1b4d3f8467790072c42319b9d3838ec8cfd4f69f0bc1"
      end
    end
    on_linux do
      on_arm do
        url "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_linux-aarch64_bin.tar.gz"
        sha256 "8e9b2c7e0f138de785dc754ad1dfa067671de66672b5e84bb7f6f6c219a6b02b"
      end
      on_intel do
        url "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_linux-x64_bin.tar.gz"
        sha256 "017f4ed8e8234d85e5bc1e490bb86f23599eadb6cfc9937ee87007b977a7d762"
      end
    end
  end

  def install
    boot_jdk = buildpath/"boot-jdk"
    resource("boot-jdk").stage boot_jdk
    boot_jdk /= "Contents/Home" if OS.mac?
    java_options = ENV.delete("_JAVA_OPTIONS")

    args = %W[
      --disable-warnings-as-errors
      --with-boot-jdk-jvmargs=#{java_options}
      --with-boot-jdk=#{boot_jdk}
      --with-debug-level=release
      --with-jvm-variants=server
      --with-native-debug-symbols=none
      --with-vendor-bug-url=#{tap.issues_url}
      --with-vendor-name=#{tap.user}
      --with-vendor-url=#{tap.issues_url}
      --with-vendor-version-string=#{tap.user}
      --with-vendor-vm-bug-url=#{tap.issues_url}
      --with-version-build=#{revision}
      --without-version-opt
      --without-version-pre
      --with-freetype=system
      --with-giflib=system
      --with-harfbuzz=system
      --with-lcms=system
      --with-libjpeg=system
      --with-libpng=system
      --with-zlib=system
    ]

    ldflags = %W[
      -Wl,-rpath,#{loader_path.gsub("$", "\\$$")}
      -Wl,-rpath,#{loader_path.gsub("$", "\\$$")}/server
    ]
    args += if OS.mac?
      ldflags << "-headerpad_max_install_names"

      # Allow unbundling `freetype` on macOS
      inreplace "make/autoconf/lib-freetype.m4", '= "xmacosx"', '= ""'

      %W[
        --enable-dtrace
        --with-freetype-include=#{Formula["freetype"].opt_include}
        --with-freetype-lib=#{Formula["freetype"].opt_lib}
        --with-sysroot=#{MacOS.sdk_path}
      ]
    else
      %W[
        --with-x=#{HOMEBREW_PREFIX}
        --with-cups=#{HOMEBREW_PREFIX}
        --with-fontconfig=#{HOMEBREW_PREFIX}
        --with-stdc++lib=dynamic
      ]
    end
    args << "--with-extra-ldflags=#{ldflags.join(" ")}"

    if DevelopmentTools.clang_build_version == 1600
      args << "--with-extra-cflags=-mllvm -enable-constraint-elimination=0"
    end

    system "bash", "configure", *args

    ENV["MAKEFLAGS"] = "JOBS=#{ENV.make_jobs}"
    system "make", "images"

    jdk = libexec
    if OS.mac?
      libexec.install Dir["build/*/images/jdk-bundle/*"].first => "openjdk.jdk"
      jdk /= "openjdk.jdk/Contents/Home"
    else
      libexec.install Dir["build/linux-*-server-release/images/jdk/*"]
    end

    bin.install_symlink Dir[jdk/"bin/*"]
    include.install_symlink Dir[jdk/"include/*.h"]
    include.install_symlink Dir[jdk/"include"/OS.kernel_name.downcase/"*.h"]
    man1.install_symlink Dir[jdk/"man/man1/*"]
  end

  def caveats
    on_macos do
      <<~EOS
        For the system Java wrappers to find this JDK, symlink it with
          sudo ln -sfn #{opt_libexec}/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
      EOS
    end
  end

  test do
    (testpath/"HelloWorld.java").write <<~JAVA
      class HelloWorld {
        public static void main(String args[]) {
          System.out.println("Hello, world!");
        }
      }
    JAVA

    system bin/"javac", "HelloWorld.java"

    assert_match "Hello, world!", shell_output("#{bin}/java HelloWorld")
  end
end
