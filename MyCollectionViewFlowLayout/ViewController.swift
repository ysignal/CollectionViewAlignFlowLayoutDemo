//
//  ViewController.swift
//  MyCollectionViewFlowLayout
//
//  Created by minse on 2017/2/19.
//  Copyright © 2017年 China. All rights reserved.
//

import UIKit

class CustomCollectionViewHeader: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update() {
        
    }
}

class CustomCollectionViewFooter: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

let kHeaderIdentifier: String = "header"
let kFooterIdentifier: String = "header"

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var widthData = [CGFloat]()
    var dataSource = ["made","in","China","UIView","UITableView","UICollectionView"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //初始化UICollectionViewFlowLayout.init对象
        let flowLayout = MYCollectionViewFlowLayout.init()
        //设置方向
        flowLayout.direction = .center
        //设置行间距
        flowLayout.minimumLineSpacing = 10
        //设置列间距
        flowLayout.minimumInteritemSpacing = 10
        //设置边界的填充距离
        flowLayout.sectionInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        //给collectionView设置布局属性, 也可以通过init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout)方法来创建一个UICollectionView对象
        collectionView.collectionViewLayout = flowLayout
        //设置协议代理
        collectionView.delegate = self
        collectionView.dataSource = self
        //提前计算item的宽度
        caculateSize(with: dataSource)
        //刷新collectionView
        collectionView.reloadData()
        collectionView.register(CustomCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: kHeaderIdentifier)
        collectionView.register(CustomCollectionViewFooter.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: kFooterIdentifier)
    }
    
    func caculateSize(with dataSource: [String]){
        //清空旧数据
        widthData.removeAll()
        //遍历数据源, 计算item的宽度(高度已固定)
        for string in dataSource {
            //CGFloat.greatestFiniteMagnitude是Swift 3.0语法, 相当于2.3中的CGFloat.max, 即是CGFloat的最大值
            widthData.append(string.width(with: UIFont.systemFont(ofSize: 14), size: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: 30))+30)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
//如果要添加自定义方法,可以遵守自定义协议, 使用原生的UICollectionViewDelegateFlowLayout也是可以实现基本功能的
//MARK: - MYCollectionViewDelegateFlowLayout
extension ViewController: MYCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, collectionViewHeight height: CGFloat) {
        //do something
    }
    //MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //返回每个item的size
        return CGSize.init(width: widthData[indexPath.row], height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.init(width: UIScreen.main.bounds.size.width, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        print(view)
    }
}
//MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    //返回对应组中item的个数, Demo中只有一个分组, 所以直接返回个数
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    //返回每个item
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextCell", for: indexPath) as? TextCell {
            //设置cell中展示的文字
            cell.textLabel.text = dataSource[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind ==  UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: kHeaderIdentifier, for: indexPath)
            if let customHeader = header as? CustomCollectionViewHeader {
                //do something
                customHeader.update()
            }
            return header
        }
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: kFooterIdentifier, for: indexPath)
        return footer
    }
}

//MARK: - String extension
extension String {
    /// 根据固定的size和font计算文字的rect
    ///
    /// - Parameters:
    /// - font: 文字的字体大小
    /// - size: 文字限定的宽高(计算规则:计算宽度, 传入一个实际的高度, 用于计算的宽度则取计算单位的最大值)
    /// - Returns: 返回的CGRect
    func rect(with font: UIFont, size: CGSize) -> CGRect {
        return (self as NSString).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
    }
    /// 根据固定的size和font计算文字的height
    func height(with font: UIFont, size: CGSize) -> CGFloat {
        return self.rect(with: font, size: size).height
    }
    /// 根据固定的size和font计算文字的width
    func width(with font: UIFont, size: CGSize) -> CGFloat {
        return self.rect(with: font, size: size).width
    }
    
    //获取从0到index的子字符串
    func substring(to index: Int) -> String {
        return self.substring(with: NSRange(location: 0, length: index))
    }
    //获取从index到末尾的子字符串
    func substring(from index: Int) -> String {
        return self.substring(with: NSRange.init(location: index, length: self.characters.count-index))
    }
    //根据Range获取子字符串
    func substring(with aRange: NSRange) -> String {
        return (self as NSString).substring(with: aRange)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    class func hexString(_ hexString: String) -> UIColor {
        return UIColor.hexString(hexString, alpha: 1)
    }
    
    class func hexString(_ hexString: String, alpha: CGFloat) -> UIColor {
        var cString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if cString.characters.count < 6 {
            return UIColor.black
        }else if cString.hasPrefix("#"){
            cString = cString.substring(from: 1)
        }else if cString.hasPrefix("0X"){
            cString = cString.substring(from: 2)
        }
        
        let rString = cString.substring(to: 2)
        let gString = cString.substring(from: 2).substring(to: 2)
        let bString = cString.substring(from: 4).substring(to: 2)
        //初始化指针变量
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        if #available(iOS 10.0, *) {
            return UIColor.init(displayP3Red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: alpha)
        } else {
            return UIColor.init(colorLiteralRed: Float(r)/255.0, green: Float(g)/255.0, blue: Float(b)/255.0, alpha: Float(alpha))
        }
    }
    //通过传入r,g,b值获取颜色
    static func color(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        if #available(iOS 10.0, *) {
            return UIColor.init(displayP3Red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1)
        } else {
            return UIColor.init(colorLiteralRed: Float(r)/255.0, green: Float(g)/255.0, blue: Float(b)/255.0, alpha: 1)
        }
    }
}
