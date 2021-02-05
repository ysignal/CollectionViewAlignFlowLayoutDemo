//
//  ViewController.swift
//  CollectionViewFlowLayout
//
//  Created by user on 2021/2/5.
//

import UIKit

let kCustomDecorationViewKind = "CustomDecorationView"

class CustomDecorationView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.lightGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataSource = ["made","in","China","UIView","UITableView","UICollectionView"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //初始化一个AlignFlowLayout实例
        let flowLayout = AlignFlowLayout()
        //设置方向
        flowLayout.direction = .center
        //设置行间距
        flowLayout.minimumLineSpacing = 10
        //设置列间距
        flowLayout.minimumInteritemSpacing = 10
        //设置边界的填充距离
        flowLayout.sectionInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        //注册DecorationView
        flowLayout.register(CustomDecorationView.self, forDecorationViewOfKind: kCustomDecorationViewKind)
        
        //给collectionView设置布局属性, 也可以通过init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout)方法来创建一个UICollectionView对象
        collectionView.collectionViewLayout = flowLayout
        //设置代理
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = dataSource[indexPath.row]
        let width = text.width(with: .systemFont(ofSize: 14), size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)) + 30
        return CGSize(width: width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: 50)
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextCell", for: indexPath) as? TextCell {
            //设置cell中展示的文字
            cell.textLabel.text = dataSource[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
}

//MARK: String extension 文字宽高计算
extension String {
    
    /// 根据固定的size和font计算文字的rect
    ///
    /// - Parameters:
    /// - font: 文字的字体大小
    /// - size: 文字限定的宽高(计算规则:计算宽度, 传入一个实际的高度, 用于计算的宽度则取计算单位的最大值)
    /// - Returns: 返回的CGRect
    func rect(with font: UIFont, size: CGSize) -> CGRect {
        return (self as NSString).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    }
    
    /// 根据固定的size和font计算文字的height
    func height(with font: UIFont, size: CGSize) -> CGFloat {
        return self.rect(with: font, size: size).height
    }
    
    /// 根据固定的size和font计算文字的width
    func width(with font: UIFont, size: CGSize) -> CGFloat {
        return self.rect(with: font, size: size).width
    }
}

//MARK: String extension 文字截取
extension String {
    //获取从0到index的子字符串
    func substring(to index: Int) -> String {
        return String(self.prefix(index))
    }
    
    //获取从index到末尾的子字符串
    func substring(from index: Int) -> String {
        return String(self.suffix(self.count - index))
    }
    
    //根据Range获取子字符串
    func substring(with aRange: NSRange) -> String {
        return String(self.suffix(self.count - aRange.location).prefix(aRange.length))
    }
}

// MARK: UIColor Extension
extension UIColor {
    class func hexString(_ hexString: String, alpha: CGFloat = 1) -> UIColor {
        var cString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if cString.count < 6 {
            return .black
        } else if cString.hasPrefix("#") {
            cString = cString.substring(from: 1)
        } else if cString.lowercased().hasPrefix("0x") {
            cString = cString.substring(from: 2)
        }
        
        // 获取颜色值对应的字符串
        let rString = cString.substring(to: 2)
        let gString = cString.substring(from: 2).substring(to: 2)
        let bString = cString.substring(from: 4).substring(to: 2)
        
        // 将十六进制转换为十进制的颜色值
        if let r = Int(rString, radix: 16), let g = Int(gString, radix: 16), let b = Int(bString, radix: 16) {
            if #available(iOS 10.0, *) {
                return UIColor(displayP3Red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: alpha)
            } else {
                return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: alpha)
            }
        } else {
            return .black
        }
    }
    
    //通过传入r,g,b值获取颜色
    static func color(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        if #available(iOS 10.0, *) {
            return UIColor(displayP3Red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
        } else {
            return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
        }
    }
}
