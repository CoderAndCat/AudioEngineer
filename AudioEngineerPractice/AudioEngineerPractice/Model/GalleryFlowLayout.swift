//
//  GalleryFlowLayout.swift
//  AudioEngineerPractice
//
//  Created by 武文龙 on 2022/5/30.
//

import UIKit

class GalleryFlowLayout: UICollectionViewFlowLayout {

    
    let itemWidth: CGFloat
    let itemHeight: CGFloat
    
    //MARK: - override
    
    init(itemWid: CGFloat, itemHei: CGFloat) {
        self.itemWidth = itemWid
        self.itemHeight = itemHei
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// 布局刷新时自动调用
    override func prepare() {
        super.prepare()
        self.scrollDirection = .horizontal
        guard let colView = self.collectionView else{
            return
        }
        let collectionSize = colView.frame.size
        
        
        // 修改item 大小
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        // 设置头部和尾部的初始间距
        let topMargin = collectionSize.width/2 - itemWidth/2
        self.sectionInset = UIEdgeInsets(top: 0, left: topMargin, bottom: 0, right: topMargin)
        
    }
    /// 返回所有的 item 对应的属性设置
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let colView = self.collectionView else{
            return nil
        }
        // 取出 item 对应的属性
        guard let superAttriArray = super.layoutAttributesForElements(in: rect) else{
            debugPrint("------ superAttribute nil")
            return nil
        }
        // 计算中心点
        let screenCenter = colView.contentOffset.x + colView.frame.size.width/2
        
        // 循环设置 Item 的属性
        
        for attri in superAttriArray {
            // 计算差值
            let deltaMargin = fabsf(Float(screenCenter) - Float(attri.center.x))
            // 计算放大比例
            let scale = 1 - CGFloat(deltaMargin)/(colView.frame.size.width/2 + attri.size.width)
            // 设置
            attri.transform = CGAffineTransform.init(scaleX: scale, y: scale)
        }
        return superAttriArray
    }
    /// 手指离开屏幕时 调用此方法
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collView = self.collectionView else{
            debugPrint("----- targetContentOffSet Error----")
            return CGPoint(x: 0, y: 0)
        }
        
        // 取出屏幕中心的点
        let collViewCenter = proposedContentOffset.x + collView.frame.size.width/2
        
        // 取出可见范围内的 Cell
        var visibleRect = CGRect.zero
        visibleRect.size = collView.frame.size
        visibleRect.origin = proposedContentOffset
        
        guard let visibleArray = super.layoutAttributesForElements(in: visibleRect) else{
            debugPrint("---- targetContentOffSet Error2----")
            return CGPoint.zero
        }
        
        var minMargin = MAXFLOAT
        
        for attri in visibleArray {
            let deltaMargin = attri.center.x - collViewCenter
            if fabsf(Float(minMargin)) > fabsf(Float(deltaMargin)) {
                minMargin = Float(deltaMargin)
            }
        }
        return  CGPoint(x: proposedContentOffset.x + CGFloat(minMargin), y: proposedContentOffset.y)
    }
    /// 当屏幕可见范围发生变化时， 重新刷新视图
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    //MARK: -  private
    
    
    
}
