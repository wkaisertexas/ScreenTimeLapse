cask "timelapze" do
  version "1.2.2"
  sha256 :no_check

  url "https://github.com/wkaisertexas/ScreenTimeLapse/releases/download/v1.2.2/TimeLapze.zip"
  name "TimeLapze"
  desc "Record screen time lapses with ease in a simple, intuitive interface"
  homepage "https://github.com/wkaisertexas/ScreenTimeLapse"

  auto_updates true
  depends_on macos: ">= :Sonoma"

  app "TimeLapze.app"
end

