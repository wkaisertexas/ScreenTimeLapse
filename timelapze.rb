cask "timelapze" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/wkaisertexas/ScreenTimeLapse/releases/download/v1.0.0/TimeLapze.zip"
  name "TimeLapze"
  desc "Record screen time lapses with ease in a simple, intuitive interface"
  homepage "https://github.com/wkaisertexas/ScreenTimeLapse"

  auto_updates true
  depends_on macos: ">= :ventura"

  app "TimeLapze.app"
end

