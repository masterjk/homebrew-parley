class Parley < Formula
  desc "Two AI agents debate at a tmux table and return a joint recommendation"
  homepage "https://github.com/masterjk/parley"
  url "https://github.com/masterjk/parley/archive/refs/tags/0.9.2.tar.gz"
  sha256 "bff79b635762175813988d1d3d5b0b794ae5c835772c1a1137ce5b7f9c1cb8b3"
  license "MIT"

  depends_on "tmux"
  depends_on "python@3"

  resource "prompt_toolkit" do
    url "https://files.pythonhosted.org/packages/source/p/prompt_toolkit/prompt_toolkit-3.0.52.tar.gz"
    sha256 "28cde192929c8e7321de85de1ddbe736f1375148b02f2e17edd840042b1be855"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/source/w/wcwidth/wcwidth-0.2.13.tar.gz"
    sha256 "72ea0c06399eb286d978fdedb6923a9eb47e1c486ce63e9b4e64fc18303972b5"
  end

  def install
    venv = libexec/"venv"
    system "python3", "-m", "venv", venv

    # Install vendored Python deps into the venv so users don't need them
    # on their system Python.
    resources.each do |r|
      r.stage do
        system venv/"bin/pip", "install", "--no-deps", "."
      end
    end

    # Place every script under libexec; the brew-managed `bin/parley` shim
    # below puts the venv's python on PATH so start.sh's `python3 ...` lines
    # resolve to the vendored interpreter.
    # Sync the wrapper's hardcoded VERSION="dev" with the tag brew is
    # installing. Without this, `parley --version` reports "dev" forever
    # regardless of which tag was published.
    inreplace "parley", /^VERSION=".*"$/, %Q(VERSION="#{version}")

    libexec.install "parley"
    libexec.install "bin"

    (bin/"parley").write <<~SH
      #!/bin/bash
      exec env PATH="#{venv}/bin:$PATH" "#{libexec}/parley" "$@"
    SH
    chmod 0755, bin/"parley"
  end

  test do
    assert_match "parley #{version}", shell_output("#{bin}/parley --version")
    # `parley doctor` is allowed to exit non-zero (claude/codex may be absent
    # in the build sandbox); we only care that it runs and reports a verdict.
    output = shell_output("#{bin}/parley doctor 2>&1", 1)
    assert_match(/tmux:|python3:|claude:|codex:/, output)
  end
end
