class WindowHolder < Formula
  desc "Menu bar app that restores window positions after macOS sleep/wake on multi-monitor setups"
  homepage "https://github.com/owlhyxxn/window-holder"
  url "https://github.com/owlhyxxn/window-holder/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "6d2dd33f58a5a5057b8acbf7c5108ddcf8b13f5ccd33dd8c82244eb9f4eacafc"
  license "MIT"
  head "https://github.com/owlhyxxn/window-holder.git", branch: "main"

  depends_on macos: :ventura

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"

    app = prefix/"WindowHolder.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    cp ".build/release/WindowHolder", app/"Contents/MacOS/WindowHolder"
    cp "Resources/Info.plist", app/"Contents/Info.plist"
    system "codesign", "--force", "--deep", "--sign", "-", app
  end

  def caveats
    <<~EOS
      WindowHolder.app was installed to:
        #{opt_prefix}/WindowHolder.app

      Open it once to get started:
        open #{opt_prefix}/WindowHolder.app

      On first launch it copies itself into ~/Applications (Spotlight
      does not reliably index a symlink into the Homebrew prefix), so
      after that you can also launch it from Spotlight or Launchpad.
      It re-copies itself automatically after a `brew upgrade` too.

      On first launch, macOS will also ask for Accessibility permission
      (System Settings > Privacy & Security > Accessibility).

      To launch it automatically at login, open the menu bar icon's
      menu and check "Launch at Login".
    EOS
  end

  test do
    assert_predicate prefix/"WindowHolder.app/Contents/MacOS/WindowHolder", :exist?
  end
end
