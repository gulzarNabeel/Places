//
//  imagePickerModel.swift
//  Qoot Inventory
//
//  Created by Mohammed on 18/04/19.
//  Copyright © 2017 Mohammed. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import AssetsLibrary

protocol ImagePickerModelDelegate {
    
    /// this method asks the delegate to set the selected Image
    ///
    /// - Parameters:
    ///   - selectedImage: UIImage Type
    ///   - tag: tag is integerType
    func didPickImage(selectedImage: UIImage , tag:Int)
}

class ImagePickerModel: NSObject {
    
    //variables
    var pickerController:UIViewController = UIViewController()
    var delegate:ImagePickerModelDelegate? = nil
    var removed = 0
    
    private static var pickerObj: ImagePickerModel? = nil
    
    //Create Shared Instance
    static var sharedImagePicker: ImagePickerModel {
        if pickerObj == nil {
            pickerObj = ImagePickerModel()
        }
        return pickerObj!
    }
    
    
    /// this method adds actions for image picker that is takePhoto,pickFromLibrary,Cancel and Remove Action
    ///Remove Action Enabled based on tag if tag 1 - RemoveAction enabled,tag 0 - RemoveAction disabled
    /// - Parameters:
    ///   - controller: this parameter is of type UIViewController
    ///   - tag: tag is of type Integer, it will be having 0 0r 1
    func setProfilePic(controller:UIViewController ,tag:Int) {
        pickerController = controller
        let imagePicker = UIImagePickerController()
        imagePicker.isEditing = true
        imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .fullScreen
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        let alert = UIAlertController(title: StringConstants.ChoosePhoto(), message: nil, preferredStyle:.actionSheet)
        let takePhoto = UIAlertAction(title: StringConstants.TakePhoto(), style: UIAlertAction.Style.default, handler: { (take) in
            if AVCaptureDevice.authorizationStatus(for: .video) !=  .denied {
                if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
                    
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    
                    controller.present(imagePicker, animated: true, completion: nil)
                }
                else {
                    self.noCamera(controller: controller)
                }
            }else{
                Helper.showAlertReturn(message: StringConstants.AllowCameraBody(), head: String(format:StringConstants.AllowCameraHead(),Utility.AppName), type: StringConstants.Done(), closeHide: false, responce: Helper.ResponseTypes.CameraAvailability)
                Helper.hidePI()
            }
        })
        
        let pickFromLibrary = UIAlertAction(title: StringConstants.PickFromLibrary(), style: UIAlertAction.Style.default, handler:{(pickFrom) in
            if PHPhotoLibrary.authorizationStatus() != .denied {
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                controller.present(imagePicker, animated: true, completion: nil)
            }else{
                Helper.showAlertReturn(message: StringConstants.AllowCameraBody(), head: String(format:StringConstants.AllowCameraHead(),Utility.AppName), type: StringConstants.Done(), closeHide: false, responce: Helper.ResponseTypes.MediaAvailability)
            }
        })
        
        let cancelAction = UIAlertAction(title: StringConstants.Cancel(), style: UIAlertAction.Style.cancel, handler:{(cancel) in })
        if tag == 1 {
            let removePhoto: UIAlertAction = UIAlertAction(title: StringConstants.Remove(),
                                                           style: .default ,handler:{ action -> Void in
                                                            self.removePhoto(controller: controller ,tag: tag)
            })
            alert.addAction(removePhoto)
        }
        alert.addAction(takePhoto)
        alert.addAction(pickFromLibrary)
        alert.addAction(cancelAction)
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = controller.view
                popoverController.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
        controller.present(alert, animated: true, completion: nil)
        
    }
    
    
    /// this method is to handle the crash if device is not having camera
    ///
    /// - Parameter controller: controller parmeter is of type UIViewController
    func noCamera(controller:UIViewController){
        let alertVC = UIAlertController(
            title: StringConstants.NoCamera(),
            message: StringConstants.NoCameraMsg(),
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: StringConstants.OK(),
            style:.default,
            handler: nil)
        alertVC.addAction(okAction)
        controller.present(
            alertVC,
            animated: true,
            completion: nil)
    }
    
    
    /// this method gets called if the tag value is 1
    /// this sets default image as selected Image and reset the tag as 0
    /// - Parameters:
    ///   - controller: it is of type UIViewController
    ///   - tag: tag is of type Integer
    func removePhoto(controller:UIViewController ,tag:Int)
    {
        // var pickedImage = UIImage()
        removed = 0
        // delegate?.didPickImage(selectedImage: pickedImage ,tag: removed)
        delegate?.didPickImage(selectedImage: #imageLiteral(resourceName: "SingleShowDefault") ,tag: removed)
        
    }
}


extension ImagePickerModel: UIImagePickerControllerDelegate,UINavigationControllerDelegate  {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        
        let chosen = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as! UIImage
        removed = 1
        delegate?.didPickImage(selectedImage: chosen, tag: removed)
        pickerController.dismiss(animated: true, completion: nil)
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
