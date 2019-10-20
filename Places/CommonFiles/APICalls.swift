//
//  APICalls.swift
//  Qoot Inventory
//
//  Created by Mohammed on 17/09/19.
//  Copyright © 2018 Mohammed. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAlamofire
import Alamofire
import Messages
import Firebase

class APICalls: NSObject {
    
    static var Reachable            = true
    static let disposeBag           = DisposeBag()
    enum ErrorCode: Int {
        case success                = 200
        case created                = 201
        case deleted                = 202
        case updated                = 203
        case NoUser                 = 204
        case badRequest             = 400
        case Unauthorized           = 401
        case Required               = 402
        case Forbidden              = 403
        case NotFound               = 404
        case MethodNotAllowed       = 405
        case NotAcceptable          = 406
        case Banned1                = 408
        case Banned                 = 415
        case ExpiredOtp             = 410
        case PreconditionFailed     = 412
        case RequestEntityTooLarge  = 413
        case TooManyAttemt          = 429
        case ExpiredToken           = 440
        case InvalidToken           = 498
        case InternalServerError    = 500
        case InternalServerError2   = 502
    }
    
    
    //Operation ZOne API
    class func operationZoneAPI(location:Location) -> Observable<Location> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        let header = Utility.getHeader()
        let params : [String : Any] = [
            APIParams.Latitude                :Double(location.Latitude),
            APIParams.Longitude               :Double(location.Longitude)
        ]
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.LocationZoneAPI, parameters: Helper.urlEncoding(params), headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Data] as? [String : Any] {
                        location.addData(dataGot)
                    }
                    observer.onNext(location)
                    observer.onCompleted()
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    
    //Signup API
    class func signUp(_ methord:HTTPMethod,_ data: [String:Any]) -> Observable<Bool> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        let header:[String:String] = [:]//Utility.getHeader()
        return Observable.create { observer in
            RxAlamofire.requestJSON(methord, APITailEnds.Store, parameters: data,encoding: JSONEncoding.default ,headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    observer.onNext(true)
                    observer.onCompleted()
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    
    //Signup API
    class func signIn(_ data: [String:Any]) -> Observable<Bool> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        let header:[String:String] = Utility.getHeaderWithoutAuth()
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.Login, parameters: data,headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            if let dataGot2 = bodyIn[APIParams.Data] as? [String:Any] {
                                Utility.setUserData(value: dataGot2)
//                                Messaging.messaging().subscribe(toTopic: Utility.userData.sessionData)
                                Messaging.messaging().subscribe(toTopic: Utility.userData.fcmTopic, completion: { data in
                                    print(data as Any)
                                })
                                observer.onNext(true)
                                return
                            }
                        }
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    
    //Send Email After Signup API
    class func EmailTo(_ data: [String:Any]){
        if !Reachable {
            return
        }
        Helper.showPI(string: "")
        let header = Utility.getHeader()
        RxAlamofire.requestJSON(.post, APITailEnds.EmailTo, parameters: data, headers: header).debug().subscribe(onNext: { (head, body) in
            let bodyIn = body as! [String:Any]
            Helper.hidePI()
            let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
            if errNum == .success {
            }else{
                APICalls.basicParsing(data:bodyIn,status: head.statusCode)
            }
            
        }, onError: { (Error) in
            Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
            Helper.hidePI()
        }).disposed(by: disposeBag)
    }
    
    
    //Create User After Signup API
    class func CreateUserComment(_ data: [String:Any]) -> Observable<Bool> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        let header:[String:String] = [:]//Utility.getHeader()
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.AddUsers, parameters: data ,headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                    if errNum == .success {
                        observer.onNext(true)
                    }else{
                        APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                    }
                    observer.onCompleted()
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    
    //Store categories API
    class func storeCategories() {
        Helper.showPI(string: "")
        RxAlamofire.requestJSON(.post, APITailEnds.StoreCategories, parameters: [:], headers: [:]).debug().subscribe(onNext: { (head, body) in
            let bodyIn = body as! [String:Any]
            Helper.hidePI()
            let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
            if errNum == .success {
                if let dataGot = bodyIn[APIParams.Status] as? Bool {
                    if dataGot {
                        if let dataGot2 = bodyIn[APIParams.Data] as? [Any] {
                            Utility.saveStoreCategories(dataGot2)
                            return
                        }
                    }
                }
                if let dataGot = bodyIn[APIParams.Message] as? String {
                    Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                    return
                }
                Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
            }else{
                APICalls.basicParsing(data:bodyIn,status: head.statusCode)
            }
            
        }, onError: { (Error) in
            Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
            Helper.hidePI()
        }).disposed(by: disposeBag)
    }
    
    
    //product categories/brands/manufacturers API
    class func filterData() {
        Helper.showPI(string: "")
        RxAlamofire.requestJSON(.post, APITailEnds.FilterData, parameters: [:], headers: [:]).debug().subscribe(onNext: { (head, body) in
            let bodyIn = body as! [String:Any]
            Helper.hidePI()
            let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
            if errNum == .success {
                if let dataGot = bodyIn[APIParams.Status] as? Bool {
                    if dataGot {
                        if let dataGot2 = bodyIn[APIParams.Data] as? [String:Any] {
                            Utility.saveFilterData(dataGot2)
                            return
                        }
                    }
                }
                if let dataGot = bodyIn[APIParams.Message] as? String {
                    Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                    return
                }
                Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
            }else{
                APICalls.basicParsing(data:bodyIn,status: head.statusCode)
            }
            
        }, onError: { (Error) in
            Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
            Helper.hidePI()
        }).disposed(by: disposeBag)
    }
    
    
    //product listing API
    class func products(_ data:[String:Any]) -> Observable<([Product],Int)> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        let header:[String:String] = [:]
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.Products, parameters: data,encoding: JSONEncoding.default,headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            if let dataGot2 = bodyIn[APIParams.Data] as? [[String:Any]] {
                                var array:[Product] = []
                                var input = 1
                                if let dataGot3 = bodyIn[APIParams.Input] as? Int {
                                    input = dataGot3
                                }
                                for each in dataGot2 {
                                    let
                                    it = Product.init(each)
                                    if input == 100 {
                                        it.parentProductId = it.ID
                                    }
                                    array.append(it)
                                }
                                observer.onNext((array,input))
                                return
                            }
                        }
                    }
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    
    //product add API
    class func AddProducts(_ data:[String:Any]) -> Observable<(Bool)> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        let header:[String:String] = [:]
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.AddProducts, parameters: data,encoding: JSONEncoding.default,headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            observer.onNext(true)
                            return
                        }
                    }
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    //product edit API
    class func UpdateProduct(_ data:[String:Any]) -> Observable<(Bool)> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        let header:[String:String] = [:]
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.UpdaeProduct, parameters: data,encoding: JSONEncoding.default,headers: header).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            observer.onNext(true)
                            return
                        }
                    }
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    //Store Data API
    class func store() {
        let data = Utility.userData
        RxAlamofire.requestJSON(.post, APITailEnds.getStore, parameters: ["storeId":data.Id,"token":data.sessionData], headers: [:]).debug().subscribe(onNext: { (head, body) in
            let bodyIn = body as! [String:Any]
            Helper.hidePI()
            let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
            if errNum == .success {
                if let dataGot = bodyIn[APIParams.Status] as? Bool {
                    if dataGot {
                        if let dataGot2 = bodyIn[APIParams.Data] as? [String:Any] {
                            Utility.setUserData(value: dataGot2)
                            return
                        }
                    }
                }
                if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                    APICalls.basicParsing(data: bodyIn, status: datagot)
                    return
                }
                if let dataGot = bodyIn[APIParams.Message] as? String {
                    Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                    return
                }
                Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
            }else{
                APICalls.basicParsing(data:bodyIn,status: head.statusCode)
            }
            
        }, onError: { (Error) in
            Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
            Helper.hidePI()
        }).disposed(by: disposeBag)
    }
    
    
    
    //Store status change API
    class func statusChange(_ storeStatus:Int) -> Observable<Bool> {
        let data = Utility.userData
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        //        let header:[String:String] = [:]//Utility.getHeader()
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.statusChange, parameters: ["storeId":data.Id,"token":data.sessionData,"status":storeStatus], headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            observer.onNext(true)
                            observer.onCompleted()
                            return
                        }
                    }
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    //Product status change API
    class func statusChangeProduct(_ dataIn:[String:Any]) -> Observable<Bool> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        //        let header:[String:String] = [:]//Utility.getHeader()
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.statusChangeProduct, parameters: dataIn, headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            observer.onNext(true)
                            observer.onCompleted()
                            return
                        }
                    }
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    //Store logout API
    class func logout() -> Observable<Bool> {
        let data = Utility.userData
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        //        let header:[String:String] = [:]//Utility.getHeader()
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.Logout, parameters: ["storeId":data.Id,"token":data.sessionData], headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            observer.onNext(true)
                            observer.onCompleted()
                            return
                        }
                    }
                    if let datagot = bodyIn[APIParams.StatusCode] as? Int {
                        APICalls.basicParsing(data: bodyIn, status: datagot)
                        return
                    }
                    if let dataGot = bodyIn[APIParams.Message] as? String {
                        Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        return
                    }
                    Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    //Cities Available API
    class func cityAvailable(_ location:Location) -> Observable<Location> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.CitiesAvailable, parameters: [APIParams.ID:location.CityId], headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        if dataGot {
                            if let dataGot = bodyIn[APIParams.Data] as? [String:Any] {
                                location.addData(dataGot)
                                observer.onNext(location)
                            }
                        }else if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }
                    }else{
                        if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }else{
                            Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                        }
                    }
                    
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                observer.onCompleted()
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    //Validate Email API
    class func validateEmailRegister(_ user:User) -> Observable<Bool> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.ValidateEmailRegister, parameters: Helper.urlEncoding([APIParams.Email:user.Email.lowercased()]), headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        observer.onNext(dataGot)
                        if !dataGot {
                            if let dataGot = bodyIn[APIParams.Message] as? String {
                                Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                            }
                            observer.onNext(false)
                            observer.onCompleted()
                        }
                    }else{
                        observer.onNext(false)
                        observer.onCompleted()
                        if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }else{
                            Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                        }
                    }
                    
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                observer.onCompleted()
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    //Validate Phone API
    class func validatePhoneRegister(_ user:User) -> Observable<Bool> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.ValidatePhoneRegister, parameters: Helper.urlEncoding([APIParams.CountryCode:user.CountryCode, APIParams.Phone: user.Phone]), headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn[APIParams.Status] as? Bool {
                        observer.onNext(dataGot)
                        if !dataGot {
                            if let dataGot = bodyIn[APIParams.Message] as? String {
                                Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                            }
                            observer.onNext(false)
                            observer.onCompleted()
                        }
                    }else{
                        observer.onNext(false)
                        observer.onCompleted()
                        if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }else{
                            Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                        }
                    }
                    
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                observer.onCompleted()
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    //forgotPassword
    class func forgotPassword(_ phone:String, _ countryCode:String) -> Observable<(String,String)> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.ForgotPassword, parameters: Helper.urlEncoding([APIParams.CountryCode:countryCode, "emailOrMobile": phone, "verifyType" : "1"]), headers: Utility.getHeaderWithoutAuth()).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn["token"] as? String {
                        if let dataGot2 = bodyIn[APIParams.Message] as? String {
                            observer.onNext((dataGot,dataGot2))
                        }else{
                            observer.onNext((dataGot,""))
                        }
                    }else{
                        if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }else{
                            Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                        }
                    }
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                observer.onCompleted()
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    //verifyOTP
    class func verifyOTP(_ otp:String,_ token:String) -> Observable<String> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.OTPValidation, parameters: Helper.urlEncoding(["token": token, "passwordOtp" : otp]), headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn["token"] as? String {
                        observer.onNext(dataGot)
                    }else{
                        if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }else{
                            Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                        }
                    }
                }else{
                    APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                observer.onCompleted()
            }, onError: { (Error) in
                Helper.showAlert(message: Error.localizedDescription.localized,head: StringConstants.Error(), type: 1)
                Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    //changePassword
    class func changePassword(_ password:String,_ token:String) -> Observable<(String,String)> {
        if !Reachable {
            Helper.showNoInternet()
            return Observable.create{ observer in
                return Disposables.create()
                }.share(replay: 1)
        }
        Helper.showPI(string: "")
        
        return Observable.create { observer in
            RxAlamofire.requestJSON(.post, APITailEnds.ChangePassword, parameters: Helper.urlEncoding(["token": token, "password" : password]), headers: [:]).debug().subscribe(onNext: { (head, body) in
                let bodyIn = body as! [String:Any]
                Helper.hidePI()
                let errNum = APICalls.ErrorCode(rawValue: head.statusCode)!
                if errNum == .success {
                    if let dataGot = bodyIn["token"] as? String {
                        if let dataGot2 = bodyIn[APIParams.Message] as? String {
                            observer.onNext((dataGot,dataGot2))
                        }else{
                            observer.onNext((dataGot,""))
                        }
                    }else{
                        if let dataGot = bodyIn[APIParams.Message] as? String {
                            Helper.showAlert(message: dataGot.localized, head: StringConstants.Error(), type: 0)
                        }else{
                            Helper.showAlert(message: "", head: StringConstants.Error(), type: 0)
                        }
                    }
                }else{
                    //APICalls.basicParsing(data:bodyIn,status: head.statusCode)
                }
                observer.onCompleted()
            }, onError: { (Error) in
                //Helper.showAlert(message: Error.localizedDescription,head: StringConstants.Error(), type: 1)
               // Helper.hidePI()
            }).disposed(by: disposeBag)
            return Disposables.create()
            }.share(replay: 1)
    }
    
    
    
    class func basicParsing(data:[String:Any],status: Int) {
        let dataIn = Helper.nullKeyRemoval(data: data)
        Helper.hidePI()
        let errNum = ErrorCode(rawValue: status)!
        var message = ""
        if let msg = dataIn[APIParams.Message] as? String {
            message = msg
        }
        switch errNum {
        case .success,.created,.deleted,.updated:
            Helper.showAlert(message: message.localized, head: StringConstants.Success(), type: 0)
            break
        case .ExpiredToken,.InvalidToken,.NoUser,.Banned,.Banned1:
            if let msg = dataIn[APIParams.Message] as? String {
                Helper.showAlertReturn(message: msg.localized, head: StringConstants.Error(), type: StringConstants.Logout(), closeHide: true, responce: Helper.ResponseTypes.Logout)
            }
            break
        case .NotFound:
            Helper.showAlert(message: message.localized, head: StringConstants.Error(), type: 1)
            break
        default:
            Helper.showAlert(message: message.localized, head: StringConstants.Error(), type: 1)
            break
        }
    }
}
