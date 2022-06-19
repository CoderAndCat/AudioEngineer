//
//  GradienetTestViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/5/31.
//

import UIKit

class GradienetTestViewController: UIViewController {

    
    private let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        addGradientLayer()
        addGradientText()
        // Do any additional setup after loading the view.
    }
    

    //MARK: - private
    private func addGradientLayer() {
        self.gradientLayer.frame = self.view.bounds
        
        self.gradientLayer.colors = [UIColor.gray.cgColor, UIColor.yellow.cgColor]
        self.gradientLayer.locations = [NSNumber(value: 0),NSNumber(value: 1)]
        self.gradientLayer.startPoint = CGPoint(x: 0.2, y: 1)
        self.gradientLayer.endPoint = CGPoint(x: 0.2, y: 1)
        
        self.view.layer.addSublayer(self.gradientLayer)
        
        
    }
    
    private func addGradientText() {
        let gradientLab = UILabel(frame: CGRect(x: 100, y: 100, width: 500, height: 31))
        gradientLab.backgroundColor = UIColor.clear
        gradientLab.text = "我是一个渐变色的 lab"
        gradientLab.font = UIFont.systemFont(ofSize: 30)
        
        gradientLab.textColor = getGradientColor(size: CGSize(width: 500, height: 31))
        
        self.view.addSubview(gradientLab)
        
    }

    /// 获取渐变色的 UIColro
    private func getGradientColor(size: CGSize) ->UIColor{
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        gradientLayer.colors = [UIColor.red.cgColor, UIColor.green.cgColor]
        
        UIGraphicsBeginImageContext(size)
        
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return UIColor.init(patternImage: img!)
        
    }
    
}
