Pod::Spec.new do |s|
  s.name         = "FXLAN"
  s.version      = "1.0.1"
  s.summary      = "FX局域网访问框架"

  s.homepage     = "https://github.com/zqw87699/FXLAN"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = {"zhangdazong" => "929013100@qq.com"}

  s.source       = { :git => "https://github.com/zqw87699/FXLAN.git", :tag => "#{s.version}"}

  s.platform     = :ios, "7.0"

  s.frameworks = "Foundation","MultipeerConnectivity"

  s.module_name = 'FXLAN' 

  s.requires_arc = true

  s.source_files = 'Classes/*'
  s.public_header_files = 'Classes/*.h'

end
