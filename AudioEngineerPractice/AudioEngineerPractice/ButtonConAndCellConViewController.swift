//
//  ButtonConAndCellConViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/9/21.
//

import UIKit

class ButtonConAndCellConViewController: UIViewController {
    
    
    
    @IBOutlet weak var titleAndImgBtn: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpButton()
    }


    private func setUpButton() {
          
        let btn = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            let newConfig = UIButton.Configuration.gray()
            
            
        } else {
            btn.setTitle("btnConfig", for: [.normal,.highlighted,.selected])
            btn.setTitleColor(.blue, for: .normal)
            btn.setTitleColor(.brown, for: [.highlighted, .selected])
            
        }
        
        
        
        self.view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(100)
        }
        
    }
    

}
