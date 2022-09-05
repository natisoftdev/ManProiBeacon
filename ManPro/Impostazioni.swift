//
//  Impostazioni.swift
//  ManPro.net
//
//  Created by Lorenzo Malferrari on 27/03/19.
//  Copyright © 2019 Natisoft. All rights reserved.
//

import UIKit

class Impostazioni: BaseViewController {
    
    @IBOutlet weak var lbAccount: UILabel!
    @IBOutlet weak var lbIndirizzoPortale: UILabel!
    @IBOutlet weak var lbIdentificativoDB: UILabel!
    @IBOutlet weak var lbLogin: UILabel!
    @IBOutlet weak var lbPassword: UILabel!
    @IBOutlet weak var lbVersioneTesto: UILabel!
    @IBOutlet weak var lbVersioneNumero: UILabel!
    @IBOutlet weak var lbCheckCred: UILabel!
    
    @IBOutlet weak var tfIndirizzoPortale: UITextField!
    @IBOutlet weak var tfIdentificativoDB: UITextField!
    @IBOutlet weak var tfLogin: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    
    @IBOutlet weak var btnSave: UIButton!
    
    //Informazioni sul device
    var nameDevice:String = "" //Nome del device dato da Utente/Casa Madre
    var systemNameDevice:String = "" //Systema operativo installato
    var systemVersionDevice:String = "" //Versione OS
    var modelDevice:String = "" //Modello del device
    var identifierForVendorDevice:String = ""
    var releaseVersionNumber:String = ""
    var buildVersionNumber:String = ""
    
    //Inizializzazione delle classi
    let home = HomeVC()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSlideMenuButton()
        // Do any additional setup after loading the view.
        
        nameDevice = UIDevice.current.name //Nome del device dato da Utente/Casa Madre
        systemNameDevice = UIDevice.current.systemName //Systema operativo installato
        systemVersionDevice = UIDevice.current.systemVersion //Versione OS
        modelDevice = UIDevice.current.model //Modello del device
        identifierForVendorDevice = UIDevice.current.identifierForVendor!.uuidString
        
        if let release = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.releaseVersionNumber = release
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.buildVersionNumber = build
        }
        
        print("Informazioni sul Telefono")
        print(nameDevice)
        print(systemNameDevice)
        print(systemVersionDevice)
        print(modelDevice)
        print(identifierForVendorDevice)
        print(releaseVersionNumber)
        print(buildVersionNumber)
        print("---------------------------")
        
        inizializzazione()
        //Ad apertura pagina controllo lo stato delle credenziali, richiamando il metodo che usa per salvarle
        saveMod()
        
        print("IndirizzoPortale: \(UserDefaults.standard.string(forKey: "indiPortale")!)")
        print("Database: \(UserDefaults.standard.string(forKey: "database")!)")
        print("Login: \(UserDefaults.standard.string(forKey: "login")!)")
        print("Password: \(UserDefaults.standard.string(forKey: "password")!)")
        print("Controllo Credenziali - Testo: \(UserDefaults.standard.string(forKey: "checkCred")!)")
        //Aggiorno il testo nella label
        self.lbCheckCred.text = NSLocalizedString(UserDefaults.standard.string(forKey: "checkCred")!, comment: "")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func inizializzazione(){
        
        //Account
        self.lbAccount.text = NSLocalizedString("Account", comment: "")
        self.lbAccount.font = UIFont.boldSystemFont(ofSize: 25.0)
        
        //indiPortale
        self.lbIndirizzoPortale.text = NSLocalizedString("Indirizzo del portale", comment: "")
        self.lbIndirizzoPortale.font = UIFont.boldSystemFont(ofSize: 22.0)
        if(UserDefaults.standard.string(forKey: "indiPortale") == ""){
            /* Indirizzo utilizzato per collegarsi al portale.Ad esempio https://sviluppo.manpronet.com */
            self.tfIndirizzoPortale.placeholder = NSLocalizedString("Ad esempio https://sviluppo.manpronet.com", comment: "")
        }
        else{
            self.tfIndirizzoPortale.text = UserDefaults.standard.string(forKey: "indiPortale")
        }
        
        //database
        self.lbIdentificativoDB.text = NSLocalizedString("Identificativo del database", comment: "")
        self.lbIdentificativoDB.font = UIFont.boldSystemFont(ofSize: 22.0)
        if(UserDefaults.standard.string(forKey: "database") == ""){
            self.tfIdentificativoDB.placeholder = NSLocalizedString("Il dato viene fornito dal gestore", comment: "")
        }
        else{
            self.tfIdentificativoDB.text = UserDefaults.standard.string(forKey: "database")
        }
        
        //login
        self.lbLogin.text = NSLocalizedString("Login", comment: "")
        self.lbLogin.font = UIFont.boldSystemFont(ofSize: 22.0)
        if(UserDefaults.standard.string(forKey: "login") == ""){
            self.tfLogin.placeholder = NSLocalizedString("Il dato viene fornito dal gestore", comment: "")
        }
        else{
            self.tfLogin.text = UserDefaults.standard.string(forKey: "login")
        }
        
        //password
        self.lbPassword.text = NSLocalizedString("Password", comment: "")
        self.lbPassword.font = UIFont.boldSystemFont(ofSize: 22.0)
        if(UserDefaults.standard.string(forKey: "password") == ""){
            self.tfPassword.placeholder = NSLocalizedString("Il dato viene fornito dal gestore", comment: "")
        }
        else{
           self.tfPassword.text = UserDefaults.standard.string(forKey: "password")
        }
        
        //save
        self.btnSave.setTitle(NSLocalizedString("Salva", comment: ""), for: .normal)
        self.btnSave.layer.cornerRadius = 5
        self.btnSave.layer.borderWidth = 1
        self.btnSave.layer.borderColor = UIColor.white.cgColor
        self.btnSave.contentEdgeInsets = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
        
        //checkCred | checkFlag = stato delle credenziali2
        //Il testo mi arriva da pagina web nel seguente formato -> num,testo
        //Es: 1,Le impostazioni di connessione risultano corrette
        self.lbCheckCred.text = NSLocalizedString(UserDefaults.standard.string(forKey: "checkCred")!, comment: "")
        
        print(NSLocalizedString(UserDefaults.standard.string(forKey: "checkCred")!, comment: ""))
        
        self.lbCheckCred.font = UIFont.boldSystemFont(ofSize: 25.0)
        if(UserDefaults.standard.integer(forKey: "checkFlag") == 0){
            self.lbCheckCred.textColor = UIColor.red
        }
        else {
            self.lbCheckCred.textColor = UIColor.green
        }
        
        //Version number
        self.lbVersioneTesto.text = NSLocalizedString("Versione dell'applicazione", comment: "")
        self.lbVersioneNumero.text = releaseVersionNumber
        self.lbVersioneNumero.font = UIFont.boldSystemFont(ofSize: 22.0)

    }
    
    @IBAction func changePortale(_ sender: UITextField) {
        UserDefaults.standard.set(tfIndirizzoPortale.text, forKey: "indiPortale")
        print(UserDefaults.standard.string(forKey: "indiPortale")!)
        if(UserDefaults.standard.string(forKey: "indiPortale") == ""){
            //Setto checkFlag
            UserDefaults.standard.set(1, forKey: "checkFlag")
            //Setto checkCred
            UserDefaults.standard.set(NSLocalizedString("Le impostazioni di connessione risultano corrette", comment: ""), forKey: "checkCred")
            self.tfIndirizzoPortale.placeholder = NSLocalizedString("Indirizzo utilizzato per collegarsi al portale. Ad esempio https://sviluppo.manpronet.com", comment: "")
        }
        else{
            //Controllo la struttra della stringa 'indiPortale'
            if(checkWebURL() == true){//Se rispetta i requisiti
                //Setto checkFlag
                UserDefaults.standard.set(1, forKey: "checkFlag")
                //Setto checkCred
                UserDefaults.standard.set(NSLocalizedString("Le impostazioni di connessione risultano corrette", comment: ""), forKey: "checkCred")
            }
            else{//Se non rispetts i requisiti
                //Setto checkFlag
                UserDefaults.standard.set(0, forKey: "checkFlag")
                //Setto checkCred
                UserDefaults.standard.set(NSLocalizedString("Indirizzo del portale non corretto", comment: ""), forKey: "checkCred")
            }
        }
        
        //print("|| controlloCredSettings ||")
        self.controlloCredSettings()
        //print("|| controlloCredSettings ||")
        
    }
    
    private func checkWebURL() -> Bool{
        var b : Bool = false
        //URL accettati
        let arr : [String] = ["https://sviluppo.manpronet.com",
                              "https://manpronet.com",
                              "https://natisoft.manpronet.com",
                              ""
        ]
        //ciclo su array e controllo che corrisponda ad almeno ad uno dei valori
        for val in arr {
            if(val == UserDefaults.standard.string(forKey: "indiPortale")!){
                b = true
            }
        }
        
        return b
    }
    
    @IBAction func changeDB(_ sender: UITextField) {
        UserDefaults.standard.set(tfIdentificativoDB.text, forKey: "database")
        print(UserDefaults.standard.string(forKey: "database")!)
        if(UserDefaults.standard.string(forKey: "database") == ""){
            self.tfIdentificativoDB.placeholder = NSLocalizedString("Il dato viene fornito dal gestore", comment: "")
        }
        
        //print("|| controlloCredSettings ||")
        self.controlloCredSettings()
        //print("|| controlloCredSettings ||")
        
    }
    
    @IBAction func changeLogin(_ sender: UITextField) {
        UserDefaults.standard.set(tfLogin.text, forKey: "login")
        print(UserDefaults.standard.string(forKey: "login")!)
        if(UserDefaults.standard.string(forKey: "login") == ""){
            self.tfLogin.placeholder = NSLocalizedString("Il dato viene fornito dal gestore", comment: "")
        }
        
        //print("|| controlloCredSettings ||")
        self.controlloCredSettings()
        //print("|| controlloCredSettings ||")
        
    }
    
    @IBAction func changePassword(_ sender: UITextField) {
        print("changePassword")
        
        UserDefaults.standard.set(tfPassword.text, forKey: "password")
        print(UserDefaults.standard.string(forKey: "password")!)
        
        if(UserDefaults.standard.string(forKey: "password") == ""){
            self.tfPassword.placeholder = NSLocalizedString("Il dato viene fornito dal gestore", comment: "")
        }
        
        //print("|| controlloCredSettings ||")
        self.controlloCredSettings()
        //print("|| controlloCredSettings ||")

    }
    
    @IBAction func saveModBtn(_ sender: UIButton) {
        self.saveMod()
        print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        print(NSLocalizedString(UserDefaults.standard.string(forKey: "checkCred")!, comment: ""))
        print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
    }
    
    private func controlloCredSettings(){
        print("controlloCredSettings")
        //DispatchQueue.main.async {
            let array = ["portale" : UserDefaults.standard.string(forKey: "indiPortale"),
                         "database" : UserDefaults.standard.string(forKey: "database"),
                         "login" : UserDefaults.standard.string(forKey: "login"),
                         "password" : UserDefaults.standard.string(forKey: "password")
            ]
        
            self.home.checkCredentials(array: array as! [String:String])
        //}
    }

    private func saveMod(){
        print("|| - saveMod - ||")
        print(UserDefaults.standard.string(forKey: "checkFlag")!)
        print("|| ----------- ||")
        print(UserDefaults.standard.string(forKey: "checkCred")!)
        print("|| - saveMod - ||")
        //Aggiorno il testo nella label
        self.lbCheckCred.text = NSLocalizedString(UserDefaults.standard.string(forKey: "checkCred")!, comment: "")
        if(UserDefaults.standard.integer(forKey: "checkFlag") == 0){
            self.lbCheckCred.textColor = UIColor.red
        }
        else {
            self.lbCheckCred.textColor = UIColor.green
        }
    }
}
