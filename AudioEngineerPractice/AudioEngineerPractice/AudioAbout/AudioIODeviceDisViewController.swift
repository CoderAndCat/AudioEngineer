//
//  AudioIODeviceDisViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/9/19.
//

import UIKit

class AudioIODeviceDisViewController: UIViewController {

    static let cellIden = "UITableViewCell.identifier"
    
    private let session = AVAudioSession.sharedInstance()
    
    
    
    @IBOutlet weak var deviceTabView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector:#selector(audioRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
        try! self.session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers, .allowBluetoothA2DP])
        try! self.session.setActive(true)
        
        setupUI()
        
        printAudioIODevices()
       
        
    }

    private func setupUI() {
//        if #available(iOS 13.0, *) {
//            self.overrideUserInterfaceStyle = .light
//        }
        self.deviceTabView.dataSource = self
        self.deviceTabView.delegate = self
        self.view.backgroundColor = .white
        self.deviceTabView.backgroundColor = .white
        self.deviceTabView.backgroundView?.backgroundColor = .white
        self.deviceTabView.allowsSelection = true
        self.deviceTabView.allowsMultipleSelection = false
    }
    
    @objc private func audioRouteChange(_ notation: Notification) {
        self.deviceTabView.reloadData()
        printAudioIODevices()
    }
    
    private func printAudioIODevices() {
        
        if let avaIpts = self.session.availableInputs {
            for ipt in avaIpts {
                debugPrint("---- 输入口 Port Descriiption :\(ipt.portName)")
                if let iptDts = ipt.dataSources {
                    for iptDt in iptDts {
                        debugPrint("输入口 ：\(ipt.portName), 中的数据源：\(iptDt.dataSourceName)")
                    }
                }
            }
        }
        debugPrint("----- 当前路由下的 输入信息：")
        let curRoteIpts = self.session.currentRoute.inputs
        for curRoteIpt in curRoteIpts {
            debugPrint("---- 当前路由下 输入口 Port Description: \(curRoteIpt.portName)")
            if let curRoteIptDts = curRoteIpt.dataSources {
                for curRoteIptDt in curRoteIptDts {
                    debugPrint("---- 当前路由 输入口 Port Descript :\(curRoteIpt.portName), dataSource: \(curRoteIptDt.dataSourceName)")
                }
            }else{
                debugPrint("---- 当前路由下 输入口 ：\(curRoteIpt.portName) 无 dataSource")
            }
        }
        
        
        let curRoteOpts = self.session.currentRoute.outputs
        for curRoteOpt in curRoteOpts {
            debugPrint("---- 当前路由下 输出口：\(curRoteOpt.portName)")
            if let curRoteOptDts = curRoteOpt.dataSources {
                for curRoteOptDt in curRoteOptDts {
                    debugPrint("----- 当前路由下 输出口:\(curRoteOpt.portName), dataSource:\(curRoteOptDt.dataSourceName)")
                }
            }else{
                debugPrint("------ 当前路由下 输出口：\(curRoteOpt.portName), 无datasource")
            }
        }
        
    }
    
    
    
}





extension AudioIODeviceDisViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let inpts = self.session.availableInputs {
//                debugPrint("---- 可用的输入Port 个数 :\(inpts.count)")
                return inpts.count
            }else{
                return 0
            }
        }else if section == 1 {
            let curRoteOutDts = self.session.currentRoute.outputs
//            debugPrint("----- 当前路由可用的输出口个数 port:\(curRoteOutDts.count)")
            return curRoteOutDts.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            let source = self.session.availableInputs![indexPath.row]
            
            var cel = tableView.dequeueReusableCell(withIdentifier: Self.cellIden)
            if cel == nil {
                cel = UITableViewCell.init(style: .default, reuseIdentifier: Self.cellIden)
            }
            guard let ipCel = cel else{
                return UITableViewCell()
            }
            ipCel.contentView.backgroundColor = .white
            ipCel.backgroundView?.backgroundColor = .white
            if #available(iOS 14.0, *) {
                var content = ipCel.defaultContentConfiguration()
                let cot = source.dataSources == nil ? 0 : source.dataSources!.count
                content.text = source.portName + "输入daSou数量：\(cot)"
                content.textProperties.color = .darkGray
                ipCel.contentConfiguration = content

                var bkConfig = UIBackgroundConfiguration.listPlainCell()
                bkConfig.backgroundColor = .white

                ipCel.backgroundConfiguration = bkConfig

            } else {
                ipCel.textLabel?.text = source.portName
                let cot = source.dataSources == nil ? 0 : source.dataSources!.count
                ipCel.detailTextLabel?.text = "输入daSou数量：\(cot)"
            }

            return ipCel
            
        }else if indexPath.section == 1 {
            let outSour = self.session.currentRoute.outputs[indexPath.row]
            
            var cel = tableView.dequeueReusableCell(withIdentifier: Self.cellIden)
            if cel == nil {
                cel = UITableViewCell.init(style: .default, reuseIdentifier: Self.cellIden)
            }
            guard let optCel = cel else{
                return UITableViewCell()
            }
            if #available(iOS 14.0, *) {
                var content = optCel.defaultContentConfiguration()
                content.text = outSour.portName
                content.textProperties.color = .darkGray
                
                optCel.contentConfiguration = content
            } else {
                optCel.contentView.backgroundColor = .white
                optCel.textLabel?.text = outSour.portName
            }

            return optCel
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            guard let iptPorts = self.session.availableInputs, !iptPorts.isEmpty else{
                debugPrint("----- availableInputs nil")
                return
            }
            let selectPort = iptPorts[indexPath.row]
            try! self.session.setPreferredInput(selectPort)
            printAudioIODevices()
            tableView.reloadData()
            
        }else{
            
        }
    }
    
}
