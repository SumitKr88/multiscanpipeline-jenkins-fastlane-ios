//
//  ViewController.swift
//  AdManagerTest
//
//  Created by Kumar, Sumit on 22/11/19.
//  Copyright © 2019 sk. All rights reserved.
//

import GoogleMobileAds
import UIKit

class ViewController: UIViewController {

  /// The AdManager banner view.
  @IBOutlet weak var bannerView: DFPBannerView!
    
    lazy var adBannerView: GADBannerView = {
        /// Set custom Ad Size
        let adSize = GADAdSizeFromCGSize(CGSize(width: UIScreen.main.bounds.width, height: 108))
                let adBannerView = GADBannerView(adSize: adSize)
        
                adBannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
                adBannerView.delegate = self
                adBannerView.rootViewController = self
        
        return adBannerView
    }()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    print("Google Mobile Ads SDK version: \(DFPRequest.sdkVersion())")
    bannerView.adUnitID = "/6499/example/banner"
    bannerView.rootViewController = self
    bannerView.delegate = self
    bannerView.load(DFPRequest())
    
    //addBannerViewToView(adBannerView)
    //Request a Google Ad
    //adBannerView.load(GADRequest())
  }
    
    func addBannerViewToView(_ adBannerView: GADBannerView) {
     adBannerView.translatesAutoresizingMaskIntoConstraints = false
     view.addSubview(adBannerView)
     view.addConstraints(
       [NSLayoutConstraint(item: adBannerView,
                           attribute: .bottom,
                           relatedBy: .equal,
                           toItem: view.safeAreaLayoutGuide.topAnchor,
                           attribute: .top,
                           multiplier: 1,
                           constant: 0),
        NSLayoutConstraint(item: adBannerView,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: 0)
       ])
    }

}

extension ViewController: GADBannerViewDelegate {
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
      print("adViewDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
        didFailToReceiveAdWithError error: GADRequestError) {
      print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}
