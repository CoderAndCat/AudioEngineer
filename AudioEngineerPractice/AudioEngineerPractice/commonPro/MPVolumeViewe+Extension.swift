//
//  MPVolumeViewe+Extension.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/9/27.
//

import Foundation
import MediaPlayer

extension MPVolumeView {
  static func setVolume(_ volume: Float) {
    let volumeView = MPVolumeView()
    for view in volumeView.subviews {
        if view.isKind(of: UISlider.self) {
            let slider = view as! UISlider
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                slider.setValue(volume, animated: false)
                slider.sendActions(for: .touchUpInside)
            }
            break
        }
    }
//    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
//
//    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
//      slider?.value = volume
//    }
  }
}
