class WindowHolder < Formula
  desc "Menu bar app that restores window positions after macOS sleep/wake on multi-monitor setups"
  homepage "https://github.com/owlhyxxn/window-holder"
  url "https://github.com/owlhyxxn/window-holder/archive/refs/tags/1.0.0.tar.gz"
  sha256 "ca25f00a97b6a6ee1b65f3ab51c5e66bd80cd17972a28c7c0b681a611ec045ec"
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

      To make it show up in Spotlight and Launchpad, copy it into
      ~/Applications (Spotlight does not reliably index a symlink into
      the Homebrew prefix, so a real copy is needed — repeat this after
      each `brew upgrade`):
        mkdir -p ~/Applications && cp -R #{opt_prefix}/WindowHolder.app ~/Applications/

      Or just open it directly, without copying:
        open #{opt_prefix}/WindowHolder.app

      On first launch, macOS will ask for Accessibility permission
      (System Settings > Privacy & Security > Accessibility).

      To launch it automatically at login, open the menu bar icon's
      menu and check "Launch at Login".
    EOS
  end

  test do
    assert_predicate prefix/"WindowHolder.app/Contents/MacOS/WindowHolder", :exist?
  end
end
