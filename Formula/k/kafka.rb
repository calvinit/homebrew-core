class Kafka < Formula
  desc "Open-source distributed event streaming platform"
  homepage "https://kafka.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=kafka/4.0.0/kafka_2.13-4.0.0.tgz"
  mirror "https://archive.apache.org/dist/kafka/4.0.0/kafka_2.13-4.0.0.tgz"
  sha256 "7b852e938bc09de10cd96eca3755258c7d25fb89dbdd76305717607e1835e2aa"
  license "Apache-2.0"

  livecheck do
    url "https://kafka.apache.org/downloads"
    regex(/href=.*?kafka[._-]v?\d+(?:\.\d+)+-(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0d5693294afbccfda699c56b8a15c6fcc71bdc357dff246b9bf24b23862fcef8"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "0d5693294afbccfda699c56b8a15c6fcc71bdc357dff246b9bf24b23862fcef8"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "0d5693294afbccfda699c56b8a15c6fcc71bdc357dff246b9bf24b23862fcef8"
    sha256 cellar: :any_skip_relocation, sonoma:        "5fe61e9a6222ad4275cdc96c03776d660bca0aed2c7816f90fbea90777db38c4"
    sha256 cellar: :any_skip_relocation, ventura:       "5fe61e9a6222ad4275cdc96c03776d660bca0aed2c7816f90fbea90777db38c4"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "0d5693294afbccfda699c56b8a15c6fcc71bdc357dff246b9bf24b23862fcef8"
  end

  depends_on "openjdk"

  def install
    data = var/"lib/kafka"

    inreplace "config/server.properties",
              "log.dirs=/tmp/kraft-combined-logs", "log.dirs=#{data}/kraft-combined-logs"

    inreplace "config/controller.properties",
              "log.dirs=/tmp/kraft-controller-logs", "log.dirs=#{data}/kraft-controller-logs"

    inreplace "config/connect-standalone.properties",
              "offset.storage.file.filename=/tmp/connect.offsets",
              "offset.storage.file.filename=#{data}/connect.offsets"

    inreplace "config/broker.properties",
              "log.dirs=/tmp/kraft-broker-logs", "log.dirs=#{data}/kraft-broker-logs"

    # remove Windows scripts
    rm_r("bin/windows")

    libexec.install "libs"

    prefix.install "bin"
    bin.env_script_all_files(libexec/"bin", Language::Java.overridable_java_home_env)
    Dir["#{bin}/*.sh"].each { |f| mv f, f.to_s.gsub(/.sh$/, "") }

    mv "config", "kafka"
    etc.install "kafka"
    libexec.install_symlink etc/"kafka" => "config"

    # create directory for kafka stdout+stderr output logs when run by launchd
    (var+"log/kafka").mkpath
  end

  service do
    storage = opt_bin/"kafka-storage"
    server_config = etc/"kafka/server.properties"
    meta_file = var/"lib/kafka/kraft-combined-logs/meta.properties"

    unless File.exist?(meta_file)
      cluster_id = `#{storage} random-uuid`
      system storage, "format", "--standalone", "-c", server_config, "-t", cluster_id
      ohai "Kafka storage formatted with KAFKA_CLUSTER_ID=#{cluster_id}"
    end

    run [opt_bin/"kafka-server-start", server_config]

    keep_alive true
    working_dir HOMEBREW_PREFIX
    log_path var/"log/kafka/kafka_output.log"
    error_log_path var/"log/kafka/kafka_output.log"
  end

  test do
    ENV["LOG_DIR"] = "#{testpath}/kafkalog"

    (testpath/"kafka").mkpath
    cp "#{etc}/kafka/server.properties", testpath/"kafka"
    inreplace "#{testpath}/kafka/server.properties", "#{var}/lib/kafka", testpath

    kafka_port, controller_port = free_port, free_port
    inreplace "#{testpath}/kafka/server.properties" do |s|
      s.gsub! "controller.quorum.bootstrap.servers=localhost:9093",
              "controller.quorum.bootstrap.servers=localhost:#{controller_port}"
      s.gsub! "listeners=PLAINTEXT://:9092,CONTROLLER://:9093",
              "listeners=PLAINTEXT://:#{kafka_port},CONTROLLER://:#{controller_port}"
      s.gsub! "advertised.listeners=PLAINTEXT://localhost:9092,CONTROLLER://localhost:9093",
              "advertised.listeners=PLAINTEXT://localhost:#{kafka_port},CONTROLLER://localhost:#{controller_port}"
    end

    begin
      cluster_id = `#{bin}/kafka-storage random-uuid`

      system "#{bin}/kafka-storage format --standalone -c #{testpath}/kafka/server.properties -t #{cluster_id} "\
             "> #{testpath}/test.kafka-storage.log 2>&1"

      fork do
        exec "#{bin}/kafka-server-start #{testpath}/kafka/server.properties " \
             "> #{testpath}/test.kafka-server-start.log 2>&1"
      end

      sleep 30

      system "#{bin}/kafka-topics --bootstrap-server localhost:#{kafka_port} --create --if-not-exists " \
             "--replication-factor 1 --partitions 1 --topic test > #{testpath}/kafka/demo.out " \
             "2>/dev/null"
      pipe_output "#{bin}/kafka-console-producer --bootstrap-server localhost:#{kafka_port} --topic test 2>/dev/null",
                  "test message"
      system "#{bin}/kafka-console-consumer --bootstrap-server localhost:#{kafka_port} --topic test " \
             "--from-beginning --max-messages 1 >> #{testpath}/kafka/demo.out 2>/dev/null"
      system "#{bin}/kafka-topics --bootstrap-server localhost:#{kafka_port} --delete --topic test " \
             ">> #{testpath}/kafka/demo.out 2>/dev/null"
    ensure
      system bin/"kafka-server-stop"
      sleep 10
    end

    assert_match(/test message/, File.read("#{testpath}/kafka/demo.out"))
  end
end
