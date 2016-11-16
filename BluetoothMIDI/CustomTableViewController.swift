//
//  PrefsTableViewController.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 27-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//  *** Don't forget to call super.willdisplaycell etc if you override the method! ***
//

import UIKit
import QuartzCore

class CustomTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    let margin = CGFloat(30)
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard UIDevice.isPad else { return }
        
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: margin*2+20, bottom: 0, right: margin*2+20)
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.separatorStyle = .none
        
        NotificationCenter.default.addObserver(tableView, selector: #selector(UITableView.reloadData), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(tableView)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // !! Don't forget to call super.willdisplaycell etc if you override this method !!
        // credits of this code go to 'jvanmetre' on http://stackoverflow.com/questions/18822619
        // though I modified it a bit; it no longer just modifies the background, but it actually resizes the cell (which makes it easier concerning IB stuff)
        guard UIDevice.isPad else { return }
        
        if (cell.responds(to: #selector(getter: UIView.tintColor))){
            if (tableView == self.tableView) {
                cell.layoutMargins = UIEdgeInsets(top: 0, left: margin*2+20, bottom: 0, right: margin*2+20)
                cell.contentView.preservesSuperviewLayoutMargins = true
                cell.backgroundColor = UIColor.clear
                
                let cornerRadius: CGFloat = 5.0,
                    path: CGMutablePath = CGMutablePath(),
                    bounds: CGRect = cell.bounds.insetBy(dx: margin * 2, dy: 0)
                
                var addLine: Bool = false
                
                if indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
                    path.addRoundedRect(in: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
                } else if indexPath.row == 0 {
                    path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
                    path.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.minY), tangent2End: CGPoint(x: bounds.midX, y: bounds.minY), radius: cornerRadius)
                    path.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.minY), tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY), radius: cornerRadius)
                    path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
                    addLine = true
                } else if indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
                    path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
                    path.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.maxY), tangent2End: CGPoint(x: bounds.midX, y: bounds.maxY), radius: cornerRadius)
                    path.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.maxY), tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY), radius: cornerRadius)
                    path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
                } else {
                    path.addRect(bounds)
                    addLine = true
                }
                
                let layer = CAShapeLayer()
                layer.path = path
                layer.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8).cgColor
                
                if (addLine == true) {
                    let lineLayer: CALayer = CALayer(),
                        lineHeight: CGFloat = (1.0 / UIScreen.main.scale)
                    lineLayer.frame = CGRect(x: bounds.minX+10, y: bounds.size.height-lineHeight, width: bounds.size.width-10, height: lineHeight)
                    lineLayer.backgroundColor = tableView.separatorColor!.cgColor
                    layer.addSublayer(lineLayer)
                }
                
                let backGroundView: UIView = UIView(frame: bounds)
                backGroundView.layer.insertSublayer(layer, at: 0)
                backGroundView.backgroundColor = UIColor.clear
                cell.backgroundView = backGroundView
                
                let selectionLayer = CAShapeLayer()
                selectionLayer.path = path
                selectionLayer.fillColor = UIColor(white: 217/256, alpha: 1.0).cgColor
                
                let selectionView: UIView = UIView(frame: bounds)
                selectionView.layer.insertSublayer(selectionLayer, at: 0)
                selectionView.backgroundColor = UIColor.clear
                cell.selectedBackgroundView = selectionView
            }
        }
    }
}



/*//
//  PrefsTableViewController.swift
//  Cleanflight Mobile Configurator
//
//  Created by Alex on 27-08-15.
//  Copyright (c) 2015 Hangar42. All rights reserved.
//
//  *** Don't forget to call super.willdisplaycell etc if you override the method! ***
//

import UIKit
import QuartzCore

class CustomTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    let margin = CGFloat(12)
    
    
    // MARK: - Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard UIDevice.isPad else { return }
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: margin*2+20, bottom: 0, right: margin*2+20)
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.separatorStyle = .none
    }
    
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // !! Don't forget to call super.willdisplaycell etc if you override this method !!
        // credits of this code go to 'jvanmetre' on http://stackoverflow.com/questions/18822619
        // though I modified it a bit; it no longer just modifies the background, but it actually resizes the cell (which makes it easier concerning IB stuff)
        guard UIDevice.isPad else { return }
        
        if (cell.responds(to: #selector(getter: UIView.tintColor))){
            if (tableView == self.tableView) {
                cell.layoutMargins = UIEdgeInsets(top: 0, left: margin*2+20, bottom: 0, right: margin*2+20)
                cell.contentView.preservesSuperviewLayoutMargins = true
                cell.backgroundColor = UIColor.clear
                
                let cornerRadius : CGFloat = 5.0,
                pathRef:CGMutablePath = CGMutablePath(),
                bounds: CGRect = cell.bounds.insetBy(dx: margin * 2, dy: 0)
                
                var addLine: Bool = false
                
                if (indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
                    pathRef.__addRoundedRect(transform: nil, rect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
                } else if (indexPath.row == 0) {
                    pathRef.move(to: CGPoint(x: bounds.minX, y: CGFloat)
                    CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds))
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius)
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius)
                    CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))
                    addLine = true
                } else if (indexPath.row == tableView.numberOfRowsInSection(indexPath.section)-1) {
                    CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds))
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius)
                    CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius)
                    CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds))
                } else {
                    CGPathAddRect(pathRef, nil, bounds)
                    addLine = true
                }
                
                let layer: CAShapeLayer = CAShapeLayer()
                layer.path = pathRef
                layer.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8).CGColor
                
                if (addLine == true) {
                    let lineLayer: CALayer = CALayer(),
                    lineHeight: CGFloat = (1.0 / UIScreen.mainScreen().scale)
                    lineLayer.frame = CGRectMake(CGRectGetMinX(bounds)+10, bounds.size.height-lineHeight, bounds.size.width-10, lineHeight)
                    lineLayer.backgroundColor = tableView.separatorColor!.CGColor
                    layer.addSublayer(lineLayer)
                }
                
                let backGroundView: UIView = UIView(frame: bounds)
                backGroundView.layer.insertSublayer(layer, atIndex: 0)
                backGroundView.backgroundColor = UIColor.clearColor()
                cell.backgroundView = backGroundView
                
                let selectionLayer = CAShapeLayer()
                selectionLayer.path = pathRef
                selectionLayer.fillColor = UIColor(hex: 0xD0D0D0).CGColor
                
                let selectionView: UIView = UIView(frame: bounds)
                selectionView.layer.insertSublayer(selectionLayer, atIndex: 0)
                selectionView.backgroundColor = UIColor.clearColor()
                cell.selectedBackgroundView = selectionView
            }
        }
    }
}
*/
extension UIDevice {
    class var isPad: Bool {
        return current.userInterfaceIdiom == .pad
    }
    
    class var isPhone: Bool {
        return current.userInterfaceIdiom == .phone
    }
}
