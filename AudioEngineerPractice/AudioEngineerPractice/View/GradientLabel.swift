//
//  GradientLabel.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/6/2.
//

import UIKit

class GradientLabel: UIView {

   
    //MARK: - Private Property
    private var text: String = ""
    private var colors: [CGColor] = []
    private var font: UIFont = UIFont.systemFont(ofSize: 24)
    private var textAlignment: NSTextAlignment = .left
    private var startPoint: CGPoint = .zero
    private var endPoint: CGPoint = .zero
    
    private var lab: UILabel?
    
    lazy private var gradientLayer: CAGradientLayer = {
        let gradl = CAGradientLayer()
        gradl.startPoint = self.startPoint
        gradl.endPoint = self.endPoint
        gradl.frame = self.lab!.frame
        gradl.colors = self.colors
        gradl.locations = [NSNumber(value: 0), NSNumber(value: 1)]
        
        return gradl
    }()
    
    //MARK: - API Property
    
    
    //MARK: - override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.lab?.frame = self.bounds
        self.layer.addSublayer(self.gradientLayer)
        
        self.gradientLayer.mask = self.lab!.layer
        
    }
    
    //MARK: - API
    init(frame: CGRect, text: String, font: UIFont, textAlig: NSTextAlignment = .left, colors: [CGColor]) {
        super.init(frame: frame)
        self.colors = colors
        self.textAlignment = textAlig
        self.text = text
        self.font = font
        
        self.lab = UILabel()
        lab?.text = self.text
        lab?.font = self.font
        lab?.textAlignment = self.textAlignment
        self.addSubview(self.lab!)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - private
    
    

}
