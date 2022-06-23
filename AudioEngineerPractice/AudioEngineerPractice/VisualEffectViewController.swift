//
//  VisualEffectViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/6/23.
//

import UIKit

class VisualEffectViewController: UIViewController {

    let blurView = UIVisualEffectView.init(frame: .zero)
    
    let tabvCellIden = "UITableViewCell.Identifier"
    
    @IBOutlet weak var mainTabView: UITableView!
    
    let blurEffectStyleNames = [["systemUltraThinMaterial": 6,"systemThinMaterial": 7,"systemMaterial": 8,"systemThickMaterial": 9,"systemChromeMaterial": 10],
                                ["systemUltraThinMaterialLight": 11,"systemThinMaterialLight": 12,"systemMaterialLight": 13,"systemThickMaterialLight": 14,"systemChromeMaterialLight": 15],
                                ["systemChromeMaterialDark": 20,"systemMaterialDark": 18,"systemThickMaterialDark" :19,"systemThinMaterialDark": 17,"systemUltraThinMaterialDark": 16],
                                ["extraLight": 0,"light": 1,"dark": 2,"extraDark": 3,"regular": 4,"prominent": 5]]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        setEffectView()
        
        setMainTableView()
    }

    //MARK: - private
    private func setEffectView() {
        
        let fengCheImv = UIImageView(image: UIImage(named: "fengChe"))
        self.view.addSubview(fengCheImv)
        
        let visualPackageView = UIView.init(frame: .zero)
        self.view.addSubview(visualPackageView)
        visualPackageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(200)
        }
        
        
        
        
        // 需要使 visual 的父视图 透明
        visualPackageView.backgroundColor = .clear
        let blurEfffect = UIBlurEffect.init(style: .light)
        
        blurView.effect = blurEfffect
        blurView.translatesAutoresizingMaskIntoConstraints = false
        visualPackageView.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: visualPackageView.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: visualPackageView.widthAnchor),
        ])
    }

    private func setMainTableView() {
        self.mainTabView.dataSource = self
        self.mainTabView.delegate = self
        self.view.bringSubviewToFront(self.mainTabView)
        self.mainTabView.allowsMultipleSelection = false
        self.mainTabView.register(UITableViewCell.self, forCellReuseIdentifier: tabvCellIden)
        
    }
}


extension VisualEffectViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 5
        case 1:
            return 5
        case 2:
            return 5
        case 3:
            return 6
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tabvCellIden, for: indexPath)
        let secNames = self.blurEffectStyleNames[indexPath.section]
        for ele in secNames.enumerated() {
            if ele.offset == indexPath.row {
                cell.textLabel?.text = ele.element.key
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "自适应样式"
        case 1:
            return "浅色样式"
        case 2:
            return "深色样式"
        case 3:
            return "其他样式"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let resDic = self.blurEffectStyleNames[indexPath.section]
        for res in resDic.enumerated() {
            if res.offset == indexPath.row {
                let value = res.element.value
                let blurEff = UIBlurEffect.init(style: UIBlurEffect.Style.init(rawValue: value)!)
                self.blurView.effect = blurEff
                break
            }
        }
    }
    
}
