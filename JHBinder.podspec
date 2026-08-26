Pod::Spec.new do |s|

  s.name         = "JHBinder"
  s.version      = "1.0.1"
  s.summary      = "轻量级 KVO + UIControl 数据绑定库，链式 DSL，支持双向/单向绑定、值转换等。"

  s.description  = <<~DESC
    JHBinder 是一个轻量级 iOS 数据绑定库，基于 KVO 和 UIControl Target-Action 实现。

    核心特性：
    - 链式 DSL：twoWay / listen / receive / observe
    - 值转换：twoWayMap / receiveMap（接收时转换，广播原始值）
    - 全局过滤：filter（链级广播拦截器）
    - 自动生命周期：通过 .store(self.bindings) 绑定 VC 生命周期，无需手动解绑
    - 线程安全：并发队列 + barrier 读写分离，主线程广播保证 UI 安全
  DESC

  s.homepage     = "https://github.com/xjh093/JHBinder"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Haomissyou" => "xjh093@126.com" }

  s.platform     = :ios, "14.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/xjh093/JHBinder.git", :tag => s.version.to_s }

  # 公开头文件（使用方 #import <JHBinder/JHBinderKit.h>）
  s.public_header_files = "JHBinder/JHBinderKit.h",
                          "JHBinder/JHBinder.h",
                          "JHBinder/Define/JHBinderDefine.h",
                          "JHBinder/Category/NSObject+JHBind.h"

  s.source_files = "JHBinder/**/*.{h,m}"

  s.frameworks   = "UIKit", "Foundation"

end
