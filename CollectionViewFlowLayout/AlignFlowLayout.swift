//
//  AlignFlowLayout.swift
//  CollectionViewFlowLayout
//
//  Created by user on 2021/2/5.
//

import UIKit

enum AlignDirection {
    case start,
    end,
    dataEnd,
    center,
    auto
}

protocol AlignDelegateFlowLayout: UICollectionViewDelegateFlowLayout {
    //代理方法, 返回collectionView内容的尺寸
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, collectionViewContentSize contentSize: CGSize)
}

class AlignFlowLayout: UICollectionViewFlowLayout {
    
    /// 默认自动对齐
    var direction: AlignDirection = .auto
    
    /// 是否靠边对齐
    var isFollow: Bool = false
    
    /// 所有cell的布局属性
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    
    /// 每一行cell的布局属性
    private var layoutLine: [UICollectionViewLayoutAttributes] = []
    
    /// 滚动范围
    private var contentSize: CGSize = CGSize.zero

    override var collectionViewContentSize: CGSize {
        return contentSize
    }
 
    override func prepare() {
        super.prepare()
        
        // 清空之前的布局属性
        layoutAttributes.removeAll()
        layoutLine.removeAll()
        
        if let collection = collectionView {
            // 获取分组个数
            let sections = collection.numberOfSections
            // 遍历分组
            for i in 0..<sections {
                // 获取组内元素个数
                let rows = collection.numberOfItems(inSection: i)
                // 获取Header的布局属性，‘UICollectionView.elementKindSectionHeader’ 是注册头部视图的字符串，可以替换成自己注册的
                if let layoutAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath.init(row: 0, section: i)) {
                    layoutAttributes.append(layoutAttr)
                }
                // 遍历获取组内每个元素的布局属性
                for j in 0..<rows {
                    if let layoutAttr = layoutAttributesForItem(at: IndexPath(row: j, section: i)) {
                        layoutAttributes.append(layoutAttr)
                    }
                }
                // 获取Footer的布局属性，‘UICollectionView.elementKindSectionFooter’ 是注册脚部视图的字符串，可以替换成自己注册的
                if let layoutAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: IndexPath(row: 0, section: i)) {
                    layoutAttributes.append(layoutAttr)
                }
                // 添加装饰视图支持，内容需要自定义
                // MARK: DecorationView Example
                if let layoutAttr = layoutAttributesForDecorationView(ofKind: kCustomDecorationViewKind, at: IndexPath(row: 0, section: i)) {
                    layoutAttributes.append(layoutAttr)
                }
            }
        }
        
        if let collection = self.collectionView {
            var contentWidth: CGFloat = 0, contentHeight: CGFloat = 0
            // 逆向遍历
            for item in layoutAttributes.reversed() {
                // 判断最后一个元素是Footer还是Item, 忽略DecorationView
                if item.representedElementCategory == .cell {
                    contentWidth = item.frame.maxX + sectionInset.right
                    contentHeight = item.frame.maxY + sectionInset.bottom
                    break
                } else if item.representedElementCategory == .supplementaryView {
                    contentWidth = item.frame.maxX
                    contentHeight = item.frame.maxY
                    break
                }
            }
            // 设置内容尺寸
            switch scrollDirection {
            case .horizontal:
                contentSize = CGSize(width: contentWidth, height: collection.bounds.height)
            case .vertical:
                contentSize = CGSize(width: collection.bounds.width, height: contentHeight)
            default:
                contentSize = collection.bounds.size
            }
            
            if let alignDelegate = collection.delegate as? AlignDelegateFlowLayout {
                alignDelegate.collectionView(collection, layout: self, collectionViewContentSize: contentSize)
            }
        }
        
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let attribute = super.layoutAttributesForItem(at: indexPath) {
            // 判断滚动方向
            switch scrollDirection {
            case .vertical:
                // 竖直滚动，判断对齐方向
                switch direction {
                case .start, .end, .center:
                    // 左对齐、右对齐、中间对齐有部分相同的计算步骤
                    if let last = layoutAttributes.last, let collection = self.collectionView {
                        if last.representedElementCategory == .cell {
                            if last.frame.maxX + minimumInteritemSpacing + attribute.frame.width + sectionInset.right < collection.bounds.width {
                                // 同一行显示
                                attribute.ex_x = last.frame.maxX + minimumInteritemSpacing
                            } else {
                                // 下一行显示
                                attribute.ex_x = sectionInset.left
                            }
                            // 判断是否处于跟随状态
                            if isFollow {
                                // 获取同组的布局属性
                                let filter = layoutAttributes.filter { (item) -> Bool in
                                    return item.indexPath.section == attribute.indexPath.section && item.representedElementCategory == .cell
                                }
                                if filter.isEmpty {
                                    // 如果没有同组布局属性，则现有布局属性为该组的第一个布局属性
                                    attribute.ex_y = last.frame.maxY + self.sectionInset.top
                                } else {
                                    // 如果有同组布局属性，遍历同组cell，获取cell的最小maxY，记录该cell的minX值，获取同组cell的maxX值
                                    var minY: CGFloat = -1, minX: CGFloat = 0, maxX: CGFloat = 0
                                    _ = filter.map({ (item) in
                                        if item.frame.maxY < minY || minY == -1 {
                                            let sameX = filter.filter { (sameItem) -> Bool in
                                                return sameItem != item && sameItem.frame.minX == item.frame.minX && sameItem.frame.maxY > item.frame.maxY
                                            }
                                            if sameX.isEmpty {
                                                minY = item.frame.maxY
                                                minX = item.frame.minX
                                            }
                                        }
                                        if item.frame.maxX > maxX {
                                            maxX = item.frame.maxX
                                        }
                                    })
                                    // 判断直接添加此cell到collectionView的下方是否越界
                                    if maxX + minimumInteritemSpacing + attribute.frame.width + sectionInset.right > collection.bounds.width {
                                        // 越界，采用跟随坐标
                                        attribute.ex_x = minX
                                        attribute.ex_y = minY + minimumLineSpacing
                                    } else {
                                        // 不越界，右方直接添加
                                        attribute.ex_x = last.frame.maxX + minimumInteritemSpacing
                                        attribute.ex_y = last.frame.minY
                                    }
                                }
                            } else {
                                // 不处于跟随状态下，切换行时会调整上一列的布局属性
                                if attribute.frame.minX < last.frame.minX {
                                    reloadlayoutAttributes()
                                }
                            }
                        } else if last.representedElementCategory == .supplementaryView {
                            attribute.ex_x = self.sectionInset.left
                            // 如果上一个布局属性是属于头部或者尾部的，当前布局属性需要增加组内填充距离
                            if isFollow {
                                attribute.ex_y = last.frame.maxY + self.sectionInset.top
                            }
                        }
                    } else if isFollow {
                        // 没有上一个布局属性，当前是第一个cell，直接设置x坐标
                        attribute.ex_y = self.sectionInset.top
                    }
                    // 添加进当前行
                    layoutLine.append(attribute)
                    // 判断当前元素是当前组的最后一个元素，重置当前行的布局属性
                    if let items = collectionView?.numberOfItems(inSection: indexPath.section), indexPath.row == items - 1 {
                        reloadlayoutAttributes()
                    }
                case .dataEnd:
                    // 右起显示需要获取collectionView显示区域的宽度
                    if let collection = collectionView {
                        if isFollow {
                            if let last = layoutAttributes.last {
                                if last.representedElementCategory == .cell {
                                    var minY: CGFloat = -1, minX: CGFloat = 0, leftX: CGFloat = -1
                                    _ = layoutAttributes.map { (item) in
                                        if item.frame.maxY < minY || minY == -1 {
                                            let sameX = layoutAttributes.filter { (sameItem) -> Bool in
                                                return sameItem != item && sameItem.frame.minX == item.frame.minX && sameItem.frame.maxY > item.frame.maxY
                                            }
                                            if sameX.isEmpty {
                                                minX = item.frame.minX
                                                minY = item.frame.maxY
                                            }
                                        }
                                        if item.frame.minX < leftX || leftX == -1 {
                                            leftX = item.frame.minX
                                        }
                                    }
                                    if leftX - minimumInteritemSpacing - attribute.frame.width - sectionInset.left < 0 {
                                        // 越界，切换行显示
                                        attribute.ex_x = minX
                                        attribute.ex_y = minY + minimumInteritemSpacing
                                    } else {
                                        // 不越界，左边方直接添加
                                        attribute.ex_x = last.frame.minX - minimumInteritemSpacing - attribute.frame.width
                                        attribute.ex_y = last.frame.minY
                                    }
                                } else if last.representedElementCategory == .supplementaryView {
                                    attribute.ex_x = collection.bounds.width - sectionInset.right - attribute.frame.width
                                    attribute.ex_y = last.frame.maxY + sectionInset.top
                                }
                            } else {
                                attribute.ex_x = collection.bounds.width - sectionInset.right - attribute.frame.width
                                attribute.ex_y = sectionInset.top
                            }
                        } else {
                            if let last = layoutAttributes.last, attribute.frame.minY == last.frame.minY {
                                // 同行显示，向左逐步显示
                                attribute.ex_x = last.frame.minX - minimumInteritemSpacing - attribute.frame.width
                            } else {
                                // 下一行显示
                                attribute.ex_x = collection.bounds.width - sectionInset.right - attribute.frame.width
                            }
                        }
                    }
                default:
                    break
                }
            case .horizontal:
                switch direction {
                case .start, .center, .end:
                    // 获取上一个布局属性
                    if let last = layoutAttributes.last, let collection = self.collectionView {
                        // 判断是不是cell
                        if last.representedElementCategory == .cell {
                            if last.frame.maxY + minimumInteritemSpacing + attribute.frame.height + sectionInset.bottom < collection.bounds.height {
                                // 同一列显示
                                attribute.ex_y = last.frame.maxY + minimumInteritemSpacing
                            } else {
                                // 下一列显示
                                attribute.ex_y = sectionInset.top
                            }
                            // 判断是否处于跟随状态
                            if isFollow {
                                // 获取同组的布局属性
                                let filter = layoutAttributes.filter { (item) -> Bool in
                                    return item.indexPath.section == attribute.indexPath.section && item.representedElementCategory == .cell
                                }
                                if filter.isEmpty {
                                    // 如果没有同组布局属性，则现有布局属性为该组的第一个布局属性
                                    attribute.ex_x = last.frame.maxX + self.sectionInset.left
                                } else {
                                    // 如果有同组布局属性，遍历同组cell，获取cell的最小maxX，记录该cell的minY值，获取同组cell的maxY值
                                    var minX: CGFloat = -1, minY: CGFloat = 0, maxY: CGFloat = 0
                                    _ = filter.map({ (item) in
                                        if item.frame.maxX < minX || minX == -1 {
                                            let sameY = filter.filter { (sameItem) -> Bool in
                                                return sameItem != item && sameItem.frame.minY == item.frame.minY && sameItem.frame.maxX > item.frame.maxX
                                            }
                                            if sameY.isEmpty {
                                                minX = item.frame.maxX
                                                minY = item.frame.minY
                                            }
                                        }
                                        if item.frame.maxY > maxY {
                                            maxY = item.frame.maxY
                                        }
                                    })
                                    // 判断直接添加此cell到collectionView的下方是否越界
                                    if maxY + minimumInteritemSpacing + attribute.frame.height + sectionInset.bottom > collection.bounds.height {
                                        // 越界，采用跟随坐标
                                        attribute.ex_x = minX + minimumLineSpacing
                                        attribute.ex_y = minY
                                    } else {
                                        // 不越界，下方直接添加
                                        attribute.ex_x = last.frame.minX
                                        attribute.ex_y = last.frame.maxY + minimumInteritemSpacing
                                    }
                                }
                            } else {
                                // 不处于跟随状态下，切换列时会调整上一列的布局属性
                                if attribute.frame.minX <= last.frame.minX {
                                    reloadlayoutAttributes()
                                }
                            }
                        } else if last.representedElementCategory == .supplementaryView {
                            attribute.ex_y = self.sectionInset.top
                            // 如果上一个布局属性是属于头部或者尾部的，当前布局属性需要增加组内填充距离
                            if isFollow {
                                attribute.ex_x = last.frame.maxX + self.sectionInset.left
                            }
                        }
                    } else if isFollow {
                        // 没有上一个布局属性，当前是第一个cell，直接设置x坐标
                        attribute.ex_x = self.sectionInset.left
                    }
                    // 添加进当前列
                    layoutLine.append(attribute)
                    // 判断当前元素是当前组的最后一个元素，重置当前列的布局属性
                    if let items = collectionView?.numberOfItems(inSection: indexPath.section), indexPath.row == items - 1 {
                        reloadlayoutAttributes()
                    }
                case .dataEnd:
                    // 下起显示需要获取collectionView显示区域的高度
                    if let collection = collectionView {
                        if isFollow {
                            if let last = layoutAttributes.last {
                                if last.representedElementCategory == .cell {
                                    var minX: CGFloat = -1, minY: CGFloat = 0, topY: CGFloat = -1
                                    _ = layoutAttributes.map { (item) in
                                        if item.frame.maxX < minX || minX == -1 {
                                            let sameY = layoutAttributes.filter { (sameItem) -> Bool in
                                                return sameItem != item && sameItem.frame.minY == item.frame.minY && sameItem.frame.maxX > item.frame.maxX
                                            }
                                            if sameY.isEmpty {
                                                minX = item.frame.maxX
                                                minY = item.frame.minY
                                            }
                                        }
                                        if item.frame.minY < topY || topY == -1 {
                                            topY = item.frame.minY
                                        }
                                    }
                                    if topY - minimumInteritemSpacing - attribute.frame.height - sectionInset.top < 0 {
                                        // 越界，切换列显示
                                        attribute.ex_x = minX + minimumLineSpacing
                                        attribute.ex_y = minY
                                    } else {
                                        // 不越界，上方直接添加
                                        attribute.ex_x = last.frame.minX
                                        attribute.ex_y = last.frame.minY - minimumInteritemSpacing - attribute.frame.height
                                    }
                                } else if last.representedElementCategory == .supplementaryView {
                                    attribute.ex_x = last.frame.maxX + sectionInset.left
                                    attribute.ex_y = collection.bounds.height - sectionInset.bottom - attribute.frame.height
                                }
                            } else {
                                attribute.ex_x = sectionInset.left
                                attribute.ex_y = collection.bounds.height - sectionInset.bottom - attribute.frame.height
                            }
                        } else {
                            
                            if let last = layoutAttributes.last, last.representedElementCategory == .cell, attribute.frame.minX < last.frame.maxX {
                                // 同列显示，向上逐步显示
                                attribute.ex_y = last.frame.minY - minimumInteritemSpacing - attribute.frame.height
                            } else {
                                // 下一行显示
                                attribute.ex_y = collection.bounds.height - sectionInset.bottom - attribute.frame.height
                            }
                        }
                    }
                default:
                    break
                }
            default:
                break
            }
            // 返回新的布局属性
            return attribute
        }
        // 默认布局，返回原始布局属性
        return super.layoutAttributesForItem(at: indexPath)
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // 获取头部或尾部视图的布局属性
        let attribute = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        if elementKind == UICollectionView.elementKindSectionHeader {
            //TODO: 第一组的头部暂时用不到修改属性，有需要可以自己修改
            if indexPath.section > 0 {
                var max: CGFloat = 0
                // 获取上一组的布局属性
                let filter = layoutAttributes.filter { (item) -> Bool in
                    return item.indexPath.section == indexPath.section - 1
                }
                // 判断上一组布局属性是否为空，如果为空暂时不需要修改
                if !filter.isEmpty {
                    // 如果上一组的布局属性不为空，获取新坐标
                    if scrollDirection == .horizontal {
                        _ = filter.map({ (item) in
                            if item.frame.maxX > max {
                                max = item.frame.maxX
                            }
                        })
                        attribute?.ex_x = max
                    } else if scrollDirection == .vertical {
                        _ = filter.map({ (item) in
                            if item.frame.maxY > max {
                                max = item.frame.maxY
                            }
                        })
                        attribute?.ex_y = max
                    }
                    return attribute
                }
            }
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            var max: CGFloat = 0
            // 获取同一组cell的布局属性
            let filter = layoutAttributes.filter { (item) -> Bool in
                return item.indexPath.section == indexPath.section && item.representedElementCategory == .cell
            }
            if !filter.isEmpty {
                // 根据同一组cell的边距来修改footer的位置
                if scrollDirection == .horizontal {
                    _ = filter.map({ (item) in
                        if item.frame.maxX > max {
                            max = item.frame.maxX
                        }
                    })
                    attribute?.ex_x = max + sectionInset.right
                } else if scrollDirection == .vertical {
                    _ = filter.map({ (item) in
                        if item.frame.maxY > max {
                            max = item.frame.maxY
                        }
                    })
                    attribute?.ex_y = max + sectionInset.bottom
                }
                return attribute
            }
        }
        return attribute
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        let filter = layoutAttributes.filter { (item) -> Bool in
            return item.representedElementCategory == .cell && item.indexPath.section == indexPath.section
        }
        
        if !filter.isEmpty {
            var minX: CGFloat = -1, maxX: CGFloat = 0, minY: CGFloat = -1, maxY: CGFloat = 0
            _ = filter.map({ (item) in
                if item.frame.minX < minX || minX < 0 {
                    minX = item.frame.minX
                }
                if item.frame.maxX > maxX {
                    maxX = item.frame.maxX
                }
                if item.frame.minY < minY || minY < 0 {
                    minY = item.frame.minY
                }
                if item.frame.maxY > maxY {
                    maxY = item.frame.maxY
                }
            })
            
            attribute.frame = CGRect(x: minX - 5, y: minY - 5, width: maxX - minX + 10, height: maxY - minY + 10)
            attribute.zIndex = -1
        }
        
        return attribute
    }
    
    //重新绘制布局
    func reloadlayoutAttributes() {
        if layoutLine.count == 0 {return} //防止越界
        if direction == .end || direction == .center, let collection = collectionView {
            //计算填充比例, rightFlow为1, center为0.5
            let scale: CGFloat = direction == .end ? 1 : 0.5
            
            if isFollow, let first = layoutLine.first {
                switch scrollDirection {
                case .vertical:
                    let firstArr = layoutLine.filter { (item) -> Bool in
                        return item.frame.minY == first.frame.minY
                    }
                    var width = CGFloat(firstArr.count - 1) * minimumInteritemSpacing
                    for item in firstArr {
                        width += item.frame.width
                    }
                    let space = (collection.bounds.width - width - sectionInset.left - sectionInset.right) * scale
                    for item in firstArr {
                        let sameArr = layoutLine.filter { (sameItem) -> Bool in
                            return sameItem.frame.minX == item.frame.minX
                        }
                        for sameItem in sameArr {
                            sameItem.ex_x += space
                        }
                    }
                case .horizontal:
                    let firstArr = layoutLine.filter { (item) -> Bool in
                        return item.frame.minX == first.frame.minX
                    }
                    var height = CGFloat(firstArr.count - 1) * minimumInteritemSpacing
                    for item in firstArr {
                        height += item.frame.height
                    }
                    let space = (collection.bounds.height - height - sectionInset.top - sectionInset.bottom) * scale
                    for item in firstArr {
                        let sameArr = layoutLine.filter { (sameItem) -> Bool in
                            return sameItem.frame.minY == item.frame.minY
                        }
                        for sameItem in sameArr {
                            sameItem.ex_y += space
                        }
                    }
                default:
                    break
                }
            } else {
                if let last = layoutLine.last {
                    //重新绘制布局有右对齐和居中对齐两种
                    switch scrollDirection {
                    case .vertical:
                        let space = (collection.bounds.width - last.frame.maxX - sectionInset.right) * scale
                        for layout in layoutLine {
                            layout.ex_x += space
                        }
                    case .horizontal:
                        let space = (collection.bounds.height - last.frame.maxY - sectionInset.bottom) * scale
                        for layout in layoutLine {
                            layout.ex_y += space
                        }
                    default:
                        break
                    }
                }
            }
        }

        layoutLine.removeAll()
    }
    
    override func layoutAttributesForElements(in rect:CGRect) -> [UICollectionViewLayoutAttributes]{
        return layoutAttributes
    }
}

extension UICollectionViewLayoutAttributes {
    var ex_x: CGFloat {
        set {
            var newFrame = frame
            newFrame.origin.x = newValue
            frame = newFrame
        } get {
            return frame.origin.x
        }
    }
    
    var ex_y: CGFloat {
        set {
            var newFrame = frame
            newFrame.origin.y = newValue
            frame = newFrame
        } get {
            return frame.origin.y
        }
    }
}
