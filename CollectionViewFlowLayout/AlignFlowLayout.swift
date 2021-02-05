//
//  AlignFlowLayout.swift
//  CollectionViewFlowLayout
//
//  Created by user on 2021/2/5.
//

import UIKit

enum AlignDirection {
    case left,
    rightData,
    rightFlow,
    center,
    auto
}

protocol AlignDelegateFlowLayout: UICollectionViewDelegateFlowLayout {
    //代理方法, 返回collectionView内容的高度
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, collectionViewHeight height: CGFloat)
}

class AlignFlowLayout: UICollectionViewFlowLayout {
    
    /// 默认自动对齐
    var direction: AlignDirection = .auto
    
    /// 所有cell的布局属性
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    
    /// 每一行cell的布局属性
    private var layoutLine: [UICollectionViewLayoutAttributes] = []
    
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
//                if let layoutAttr = layoutAttributesForDecorationView(ofKind: kCustomDecorationViewKind, at: IndexPath(row: 0, section: i)) {
//                    layoutAttributes.append(layoutAttr)
//                }
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
                case .left, .rightFlow, .center:
                    // 左对齐、右对齐、中间对齐有部分相同的计算步骤
                    if let last = layoutAttributes.last, attribute.frame.minY == last.frame.minY {
                        // 同一行显示
                        attribute.ex_x = last.frame.maxX + minimumInteritemSpacing
                    } else {
                        // 下一行显示
                        attribute.ex_x = sectionInset.left
                    }
                    // 判断当前正在换行时重置当前行的布局属性
                    if direction == .rightFlow || direction == .center, let last = layoutLine.last, attribute.frame.minY != last.frame.minY {                        reloadlayoutAttributes()
                    }
                    // 添加进当前行
                    layoutLine.append(attribute)
                    // 判断当前元素是当前组的最后一个元素，重置当前行的布局属性
                    if let items = collectionView?.numberOfItems(inSection: indexPath.section), indexPath.row == items - 1 {
                        reloadlayoutAttributes()
                    }
                case .rightData:
                    // 右起显示需要获取collectionView显示区域的宽度
                    if let collection = collectionView {
                        if let last = layoutAttributes.last, attribute.frame.minY == last.frame.minY {
                            // 同行显示，向左逐步显示
                            attribute.ex_x = last.frame.minX - minimumInteritemSpacing - attribute.frame.width
                        } else {
                            // 下一行显示
                            attribute.ex_x = collection.bounds.width - sectionInset.right - attribute.frame.width
                        }
                    }
                default:
                    break
                }
            case .horizontal:
                //TODO: 水平方向滚动的计算方式类似，可拓展对齐方向进行适配
                break
            default:
                break
            }
            // 返回新的布局属性
            return attribute
        }
        // 默认布局，返回原始布局属性
        return super.layoutAttributesForItem(at: indexPath)
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        
        if let item = layoutAttributesForItem(at: indexPath) {
            attribute.frame = CGRect(x: 10, y: item.frame.minY - 5, width: UIScreen.main.bounds.width - 20, height: item.frame.height * 2 + minimumLineSpacing + 10)
            attribute.zIndex = -1
        }
        
        return attribute
    }
    
    //重新绘制布局
    func reloadlayoutAttributes() {
        if layoutLine.count == 0 {return} //防止越界
        //重新绘制布局有右对齐和居中对齐两种
        if direction == .rightFlow || direction == .center {
            //计算填充比例, rightFlow为1, center为0.5
            let scale: CGFloat = direction == .rightFlow ? 1 : 0.5
            //先获取空白部分的宽度(即是填充宽度的大小)
            if let collection = collectionView, let last = layoutLine.last {
                let space = (collection.bounds.width - last.frame.maxX - sectionInset.right) * scale
                for layout in layoutLine {
                    layout.ex_x += space
                }
            }
        }
        layoutLine.removeAll()
    }
    
    override func layoutAttributesForElements(in rect:CGRect) -> [UICollectionViewLayoutAttributes]{
        // 逆向遍历
        for item in layoutAttributes.reversed() {
            // 判断最后一个元素是Footer还是Item, 忽略DecorationView
            if item.representedElementKind == UICollectionView.elementKindSectionFooter || item.representedElementKind == nil {
                if let collection = collectionView, let alignDelegate = collection.delegate as? AlignDelegateFlowLayout {
                    alignDelegate.collectionView(collection, layout: self, collectionViewHeight: item.frame.maxY)
                }
                break
            }
        }
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
}
