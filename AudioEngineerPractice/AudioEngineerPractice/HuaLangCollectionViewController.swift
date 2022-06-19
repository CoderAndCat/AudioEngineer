//
//  HuaLangCollectionViewController.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/5/30.
//

import UIKit
import SnapKit

class HuaLangCollectionViewController: UIViewController {

    private let galleryLayout = GalleryFlowLayout(itemWid: 100, itemHei: 55)
    lazy private var mainCollectionView = UICollectionView.init(frame: .zero, collectionViewLayout: self.galleryLayout)
    
    
    private let collCellIdentifier = "collectionViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainCollectionView.dataSource = self
        self.mainCollectionView.delegate = self
        /// 水平滚动时，行间距 指列间距，itemSpace 值的是 上下两个 item 的间距
        self.galleryLayout.minimumLineSpacing = 23
        self.galleryLayout.minimumInteritemSpacing = 800
        self.mainCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: collCellIdentifier)
        
        self.view.addSubview(mainCollectionView)
        makeConstraints()
        // Do any additional setup after loading the view.
    }

    //MARK: - private
    
    private func makeConstraints() {
        self.mainCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.layoutMarginsGuide.snp.top)
            make.left.equalTo(self.view.layoutMarginsGuide.snp.left)
            make.right.equalTo(self.view.layoutMarginsGuide.snp.right)
            make.bottom.equalTo(self.view.layoutMarginsGuide.snp.bottom)
        }
    }


}

//MARK: -
extension HuaLangCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = mainCollectionView.dequeueReusableCell(withReuseIdentifier: self.collCellIdentifier, for: indexPath)
        cell.backgroundColor = UIColor.gray
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}
