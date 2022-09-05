//
//  Pannello.swift
//  ManPro.net
//
//  Created by Lorenzo Malferrari on 27/03/19.
//  Copyright © 2019 Natisoft. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import CoreLocation

class Pannello: BaseViewController, CLLocationManagerDelegate {
    
    //Oggetto per la gestione della localizzazione dei Beacon
    var locationManager: CLLocationManager!
    
    //INTERNET
    let internetON : String = NSLocalizedString("Il dispositivo è connesso a Internet", comment: "")
    let internetOFF : String = NSLocalizedString("Il dispositivo NON è connesso a Internet", comment: "")
    //GPS
    let gpsON : String = NSLocalizedString("Il dispositivo ha il GPS attivo", comment: "")
    let gpsOFF : String = NSLocalizedString("Il dispositivo NON ha il GPS attivo", comment: "")
    
    //Inizializzazione Bottoni
    @IBOutlet weak var bntInternet: UIButton!
    @IBOutlet weak var btnGPS: UIButton!
    //Inizializzazione Label
    @IBOutlet weak var lbIntroPannello: UILabel!
    @IBOutlet weak var lbInternet: UILabel!
    @IBOutlet weak var lbGPS: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        //Richiedo le autorizzazioni
        if(CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways){ locationManager.requestAlwaysAuthorization() }
        
        inizializzazione()
        //Aggiunta del Menù laterale
        addSlideMenuButton()
        //Controllo Internet
        checkInternet()
        //Controllo GPS
        checkGPS()
    }
    
    //Inizializzazione di alcuni parametri per le componenti grafiche della scheda
    func inizializzazione(){
        
        // Internet
        self.bntInternet.setTitle(NSLocalizedString("Test Connessione", comment: ""), for: .normal)
        self.bntInternet.layer.cornerRadius = 5
        self.bntInternet.layer.borderWidth = 1
        self.bntInternet.layer.borderColor = UIColor.white.cgColor
        self.bntInternet.contentEdgeInsets = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
        //self.bntInternet.titleEdgeInsets.left = 5
        //self.bntInternet.titleEdgeInsets.right = 5
        
        // GPS
        self.btnGPS.setTitle(NSLocalizedString("Test GPS", comment: ""), for: .normal)
        self.btnGPS.layer.cornerRadius = 5
        self.btnGPS.layer.borderWidth = 1
        self.btnGPS.layer.borderColor = UIColor.white.cgColor
        self.btnGPS.contentEdgeInsets = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
        //self.btnGPS.titleEdgeInsets.left = 5
        //self.btnGPS.titleEdgeInsets.right = 5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     Controllo se Internet è attivo
     */
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
    }

    //Verifico lo stato per Internet
    func checkInternet() {
        if isConnectedToNetwork(){
            print(internetON)
            lbInternet.text = internetON
            lbInternet.textColor = UIColor.green
        }
        else{
            print(internetOFF)
            lbInternet.text = internetOFF
            lbInternet.textColor = UIColor.red
        }
    }
    
    /*
     Controllo se GPS è attivo
     */
    //Da sistemare
    //Bisogna controllare i permessi e al primo utilizzo utente deve autorizzare l'uso del GPS
    func isConnectedToGPS() -> Bool {
        var status:Bool = false
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                status = false
            case .authorizedAlways, .authorizedWhenInUse:
                status = true
            }
        } else {
            status = false
        }
        return status
    }
    
    //Verifico lo stato per GPS
    func checkGPS(){
        if isConnectedToGPS(){
            print(gpsON)
            lbGPS.text = gpsON
            lbGPS.textColor = UIColor.green
        }
        else{
            print(gpsOFF)
            lbGPS.text = gpsOFF
            lbGPS.textColor = UIColor.red
        }
    }
    
    @IBAction func checkInternet(_ sender: UIButton) {
        checkInternet()
    }
    
    @IBAction func checkGPS(_ sender: UIButton) {
        checkGPS()
    }
}
