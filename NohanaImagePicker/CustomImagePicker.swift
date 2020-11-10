//
//  CustomImagePicker.swift
//  Synchron
//
//  Created by Helen Anders on 19.11.18.
//  Copyright © 2018 Stollberg. All rights reserved.
//

import Foundation
import UIKit
import Photos

public protocol CustomImagePickerDelegate {
    func selectFotos(pickedImages: [UIImage])
    func didCancel()
}

open class CustomImagePicker: NohanaImagePickerController {
    
    public var maxSelection = 5
    public var allowedSelection = 0
    public var selectedCount = 0
    public var customDelegate: CustomImagePickerDelegate?
    public var momentActive: Bool = false
    var loadingScreen: UIView?
    var images: [UIImage] = []

    public override init() {
        super.init()
        
        self.addLoadingScreen()
        self.delegate = self
        self.numberOfColumnsInPortrait = 4
        self.numberOfColumnsInLandscape = 4
        self.shouldShowMoment = true
        self.shouldShowEmptyAlbum = false
        self.toolbarHidden = false
        self.canPickAsset = { (asset: Asset) -> Bool in
            return true
        }
        
        self.config.color.separator = UIColor.green
        self.config.strings.albumListMomentTitle = "Momente"
        self.config.image.droppedSmall = UIImage.init(named: "btn_select_m")
        self.config.image.pickedSmall = UIImage.init(named: "btn_selected_m")
        self.config.image.pickedLarge = UIImage.init(named: "btn_selected_m")
        self.config.image.droppedLarge = UIImage.init(named: "btn_select_m")
        self.config.strings.albumListTitle = "Fotos"
        self.config.strings.albumListEmptyMessage = "Album besitzt keine Fotos"
        self.config.strings.albumListEmptyDescription = "keine Fotos"
    }
    
    public func setCountToUserSettings() {
        self.config.strings.toolbarTitleHasLimit = "\(selectedCount) von \(allowedSelection) Fotos gewählt"
        self.maximumNumberOfSelection = maxSelection
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

extension CustomImagePicker : NohanaImagePickerControllerDelegate {
    public func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        customDelegate?.didCancel()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, willPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        return true
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, didPickPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        selectedCount += 1
        self.config.strings.toolbarTitleHasLimit = "\(selectedCount) von \(allowedSelection) Fotos gewählt"
        if selectedCount == allowedSelection {
            let alert = UIAlertController.init(title: "Fotos", message: "Du hast deine maximale Anzahl an Fotos erreicht.", preferredStyle: .alert)
            let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) in }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, willDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) -> Bool {
        return true
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, didDropPhotoKitAsset asset: PHAsset, pickedAssetsCount: Int) {
        selectedCount -= 1
        self.config.strings.toolbarTitleHasLimit = "\(selectedCount) von \(allowedSelection) Fotos gewählt"
    }
    
    public func nohanaImagePickerDidSelectMoment(_ picker: NohanaImagePickerController) {
//        picker.title = "Momente"
//        self.navigationController?.navigationItem.title = "Momente"
        momentActive = true
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, didSelectPhotoKitAssetList assetList: PHAssetCollection) {
        momentActive = false
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, assetListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: IndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        if momentActive {
            if indexPath.section == assetListViewController.collectionView!.numberOfSections - 1 {
                if indexPath.row == assetListViewController.collectionView!.numberOfItems(inSection: indexPath.section) - 1 {
                    assetListViewController.navigationItem.title = "Momente"
                    let section = assetListViewController.collectionView!.numberOfSections - 1
                    assetListViewController.collectionView?.scrollToItem(at: IndexPath(row: assetListViewController.collectionView!.numberOfItems(inSection: section) - 1, section: section), at: .bottom, animated: false)
                }
            }
        }
        
        return cell
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, assetDetailListViewController: UICollectionViewController, cell: UICollectionViewCell, indexPath: IndexPath, photoKitAsset: PHAsset) -> UICollectionViewCell {
        // bild in großansicht
        if momentActive {
            assetDetailListViewController.navigationItem.title = "Momente"
        }
        return cell
    }
    
    public func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts: [PHAsset]) {
        self.showLoadingScreen(show: true)
        if let asset = pickedAssts.first {
            self.downloadImage(asset: asset, pickedAssts: pickedAssts)
        } else {
            self.showLoadingScreen(show: false)
            self.customDelegate?.selectFotos(pickedImages: self.images)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func downloadImage(asset: PHAsset, pickedAssts: [PHAsset]) {
        var pAssets = pickedAssts
        pAssets.remove(at: 0)
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = true
        
        let manager = PHImageManager.default()
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: requestOptions) { (image, info) in
            let img: UIImage? = image
            if img != nil {
                self.images.append(img!)
            }
            if pAssets.count > 0 {
                let nextAsset = pAssets.first
                self.downloadImage(asset: nextAsset!, pickedAssts: pAssets)
            } else {
//                 tried to load all images
                self.showLoadingScreen(show: false)
                self.customDelegate?.selectFotos(pickedImages: self.images)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func addLoadingScreen() {
        self.loadingScreen = UIView.init(frame: self.view.bounds)
        self.loadingScreen?.backgroundColor = UIColor.init(red: 18.0/255.0, green: 104.0/255.0, blue: 146.0/255.0, alpha: 0.5)
        self.loadingScreen?.alpha = 0.0
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.white)
        self.loadingScreen?.addSubview(ai)
        ai.center = (self.loadingScreen?.center)!
        ai.isHidden = false
        ai.startAnimating()
        self.view.addSubview(self.loadingScreen!)
    }
    
    func showLoadingScreen(show: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.loadingScreen?.alpha = show ? 1.0 : 0.0
        }
    }
}
