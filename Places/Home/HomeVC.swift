//
//  HomeVC.swift
//  Qoot Inventory
//
//  Created by Mohammed on 02/09/19.
//  Copyright © 2018 Mohammed. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SideMenu

class HomeVC: UIViewController {
    
    
    @IBOutlet weak var indicatorWidth: NSLayoutConstraint!
    @IBOutlet weak var constrainPage: NSLayoutConstraint!
    @IBOutlet weak var mainSearchBar: UISearchBar!
    @IBOutlet weak var tabTitleView: UIView!
    @IBOutlet var headerView: NavHeader!
    @IBOutlet weak var approvedButton: UIButton!
    @IBOutlet weak var pendingButton: UIButton!
    @IBOutlet weak var centralButton: UIButton!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var indicatorLeading: NSLayoutConstraint!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var pendingTableView: UITableView!
    @IBOutlet weak var outofstockTable: UITableView!
    @IBOutlet weak var approvedTableView: UITableView!
    @IBOutlet weak var centralTableView: UITableView!
    @IBOutlet weak var outofstckButton: UIButton!
    static let MunuResponse = PublishSubject<MenuResponding>()
    
    let pendingRC = UIRefreshControl()
    let approvedRC = UIRefreshControl()
    let centralRC = UIRefreshControl()
    let outofstockRC = UIRefreshControl()
    
    enum MenuResponding:Int {
        case Default = 0
        case Logout = 1
        case Language = 2
    }
    let homeVM = HomeVM()
    let addProducVM = AddProductVM()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        APICalls.store()
        self.navigationController?.navigationBar.isHidden = false
        UIApplication.shared.statusBarStyle = .lightContent
        setUI()
        setMenu()
        setVM()
        if Utility.userData.autoApproval != 1 {
            homeVM.getProduct(mainSearchBar.text!, 1)
        }
        homeVM.getProduct(mainSearchBar.text!, 0)
        homeVM.getProduct(mainSearchBar.text!, 2)
        homeVM.getProduct(mainSearchBar.text!, 3)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Utility.getLanguage().Code == "ar" {
            self.mainScrollView.contentOffset.x = CGFloat(homeVM.pagecount - 1) * UIScreen.main.bounds.width
        }
        scrollViewDidScroll(mainScrollView)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == String(describing: AddUnitVC.self) {
            let sen = sender as! (Int,Int,Int)
            if let VC: AddUnitVC = segue.destination as? AddUnitVC{
                VC.selectedType = AddUnitVC.SelectType(rawValue: sen.0)!
                var product:Product = Product.init([:])
                self.addProducVM.edit = true
                switch sen.2 {
                case 0:
                    product = homeVM.ApprovedArray[sen.1]
                    break
                case 1:
                    product = homeVM.PendingArray[sen.1]
                    break
                case 2:
                    self.addProducVM.edit = false
                    product = homeVM.CentralArray[sen.1]
                    break
                case 3:
                    product = homeVM.OutOfStockArray[sen.1]
                    break
                default:
                    break
                }
                VC.mainArray = product.Units
                VC.ResponseBack.subscribe(onNext: { [weak self]data in
                    self?.addProducVM.ProductHere = product
                    self?.addProducVM.ProductHere.Units = data as! [Unit]
                    if (self?.addProducVM.edit)!{
                        self?.addProducVM.editProduct()
                    }else{
                        self?.addProducVM.addProduct()
                    }
                }).disposed(by: VC.disposeBag)
            }
        }else if segue.identifier == String(describing: FilterVC.self) {
            if let nav: UINavigationController = segue.destination as? UINavigationController{
                if let VC: FilterVC = nav.viewControllers[0] as? FilterVC{
                    VC.CategoryArray = homeVM.categoryArray
                    VC.Brands = homeVM.brandArray
                    VC.Manufacturer = homeVM.manufacturer
                    VC.responseBack.subscribe(onNext: { [weak self]data in
                        self?.homeVM.categoryArray = data.0
                        self?.homeVM.brandArray = data.1
                        self?.homeVM.manufacturer = data.2
                        self?.homeVM.ApprovedArray.removeAll()
                        self?.homeVM.PendingArray.removeAll()
                        self?.homeVM.CentralArray.removeAll()
                        self?.homeVM.OutOfStockArray.removeAll()
                        self?.approvedTableView.reloadData()
                        self?.pendingTableView.reloadData()
                        self?.centralTableView.reloadData()
                        self?.outofstockTable.reloadData()
                        self?.homeVM.getProduct((self?.mainSearchBar.text)!, 0)
                        self?.homeVM.getProduct((self?.mainSearchBar.text)!, 3)
                        self?.homeVM.getProduct((self?.mainSearchBar.text)!, 2)
                        if self?.homeVM.pagecount != 3 {
                            self?.homeVM.getProduct((self?.mainSearchBar.text)!, 1)
                        }
                    }).disposed(by: self.homeVM.disposeBag)
                }
            }
        }else if segue.identifier == String(describing: AddProductVC.self) {
            if let nav: UINavigationController = segue.destination as? UINavigationController{
                if let VC: AddProductVC = nav.viewControllers[0] as? AddProductVC{
                    if let sen = sender as? Product {
                        VC.addProductVM.ProductHere = sen
                        VC.addProductVM.edit = true
                    }
                }
            }
        }
    }
    
    func setVM() {
        HomeVC.MunuResponse.subscribe(onNext: { data in
            switch data {
            case HomeVC.MenuResponding.Logout:
                Utility.setLogin(value: false)
                self.dismiss(animated: false, completion: nil)
                break
            default:
                break
            }
        }).disposed(by: homeVM.disposeBag)
        Helper.HelperResponseType.subscribe(onNext: { [weak self]data in
            switch data {
            case .Profile:
                self?.setUI()
                break
            default:
                break
            }
        }).disposed(by: homeVM.disposeBag)
        homeVM.responseBack.subscribe(onNext: { [weak self]data in
            switch data {
            case .Approved:
                self?.approvedTableView.reloadData()
                break
            case .Pending:
                self?.pendingTableView.reloadData()
                break
            case .Central:
                self?.centralTableView.reloadData()
                break
            case .OutOfStock:
                self?.outofstockTable.reloadData()
                break
            }
        }).disposed(by: homeVM.disposeBag)
        AppDelegate.ProductAddOrUpdated.subscribe(onNext: { [weak self]data in
            switch data {
            case .Add:
                self?.homeVM.ApprovedArray.removeAll()
                self?.homeVM.getProduct((self?.mainSearchBar.text)!, 0)
                self?.homeVM.PendingArray.removeAll()
                self?.homeVM.getProduct((self?.mainSearchBar.text)!, 1)
                self?.homeVM.CentralArray.removeAll()
                self?.homeVM.getProduct((self?.mainSearchBar.text)!, 2)
                break
            case .Update:
                self?.homeVM.ApprovedArray.removeAll()
                self?.homeVM.getProduct((self?.mainSearchBar.text)!, 0)
                self?.homeVM.PendingArray.removeAll()
                self?.homeVM.getProduct((self?.mainSearchBar.text)!, 1)
                self?.homeVM.CentralArray.removeAll()
                self?.homeVM.getProduct((self?.mainSearchBar.text)!, 2)
                break
            default:
                break
            }
            self?.centralTableView.reloadData()
            self?.approvedTableView.reloadData()
            self?.pendingTableView.reloadData()
        }).disposed(by: homeVM.disposeBag)
    }
}
