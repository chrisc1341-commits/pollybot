class Bullpen < Formula
  desc "Bullpen CLI"
  homepage "https://github.com/BullpenFi/bullpen-cli-releases"
  version "0.1.83"

  on_macos do
    on_arm do
      url "https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v0.1.83/bullpen-0.1.83-aarch64-apple-darwin.tar.gz"
      sha256 "ff63bf67e840ca2def890fab7e4bba36560bfbfdadc320ddedfbb2cd519ad7eb"
    end
    on_intel do
      url "https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v0.1.83/bullpen-0.1.83-x86_64-apple-darwin.tar.gz"
      sha256 "44c999eb89b8c61c48df3d7db05cb9d4f805802d757f03decec3fcc2fdf47ea0"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v0.1.83/bullpen-0.1.83-aarch64-unknown-linux-musl.tar.gz"
      sha256 "cc1c426a5e96673a0c85eec618625269794cde4f9c24e3a9d0c44bc64ffc385f"
    end
    on_intel do
      url "https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v0.1.83/bullpen-0.1.83-x86_64-unknown-linux-musl.tar.gz"
      sha256 "7f724fe6886d774826c8a265daa28a090468aa37c88c9a22b4d2a058284dd8f2"
    end
  end

  def install
    bin.install "bullpen"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bullpen --version")
  end
end
