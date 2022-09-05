//
//  HomeVC.swift
//  ManPro.net
//
//  Created by Lorenzo Malferrari on 27/03/19.
//  Copyright © 2019 Natisoft. All rights reserved.
//

/*
 
 Nell'appliccazione Android stampo le seguenti voci (MAC, Distance, TxPower, Rssi)
 Però la classe per IOS corrispondente mi restituisce solamente i seguenti valori:
 - proximityUUID | L'ID di prossimità del faro
 - major | Il valore più significativo nel faro
 - minor | Il valore meno significativo nel faro
 - proximity | La distanza relativa al faro
 - accuracy | La precisione del valore di prossimità, misurata in metri dal faro
 - rssi | La potenza del segnale ricevuto del faro, misurata in decibel
 ----------------------------------------------------------------------------------
 Da testare, poichè nella documentazione ufficiale non è preente ma XCode lo propone per avere la descrizione del ricevitore
 - description
 
 */

import UIKit
import CoreLocation
import UserNotifications

class HomeVC: BaseViewController, CLLocationManagerDelegate, StreamDelegate {
    
    //Oggetto per la gestione della localizzazione dei Beacon
    var locationManager: CLLocationManager!
    //Implementazione della Regione dei Beacon settando il UUID e dando un identificatore
    //attualmente settato con una stringa riconducibile a ManProNet
    let region = CLBeaconRegion(proximityUUID: NSUUID(uuidString: "b9407f30-f5f8-466e-aff9-25556b57fe6d")! as UUID, identifier: "com.manpronet")
    //Nome del file per salvare la data della ciclata
    let fileName = "reportCicliScanner.lm"
    //Inizializzazione della textView
    @IBOutlet weak var textViewBeacons: UITextView!
    //Inizializzazione degli attributi utili per la scrittura/lettura del record nel File
    var docManager:URL!, fileURL:URL!
    
    var serverAddress: CFString!
    //let serverPort: UInt32 = 8082

    var inputStream: InputStream!
    var outputStream: OutputStream!
    var connecting:Bool!
    
    //Informazioni sul device
    var nameDevice:String = "" //Nome del device dato da Utente/Casa Madre
    var systemNameDevice:String = "" //Systema operativo installato
    var systemVersionDevice:String = "" //Versione OS
    var modelDevice:String = "" //Modello del device
    var identifierForVendorDevice:String = ""
    var releaseVersionNumber:String = ""
    var buildVersionNumber:String = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //Aggiunta del Menù laterale
        addSlideMenuButton()
        print("Sono nella Home di ManProiBeacon2")
        
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
        
        checkSettings()
        print(" --------------------------- ")
        //Setto la TextView
        inizializzazione()
        //Abilitare il monitoraggio della batteria
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        //Costruzione del FileManager
        docManager = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        fileURL = docManager.appendingPathComponent(fileName)
        
        print("Informazioni sul Telefono")
        print(nameDevice)
        print(systemNameDevice)
        print(systemVersionDevice)
        print(modelDevice)
        print(identifierForVendorDevice)
        print(releaseVersionNumber)
        print(buildVersionNumber)
        //Batteria
        print(UIDevice.current.batteryLevel)
        //print(UIDevice.current.batteryState.rawValue)
        //print(UIDevice.BatteryState.self)
        print(" --------------------------- ")
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        //Richiedo le autorizzazioni
        if(CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways){ locationManager.requestAlwaysAuthorization() }
        //Aggiorno le autorizzazioni
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        //Inizio del servizio
        locationManager.startRangingBeacons(in: region)
    }
    
    //Metodo che inizializza la textView che andrà a contenere i dati dei Beacon percepiti nei dintorni
    func inizializzazione(){
        self.automaticallyAdjustsScrollViewInsets = false
        //textViewBeacons.center = self.view.center
        textViewBeacons.text = NSLocalizedString("In caricamento......", comment: "")
        textViewBeacons.textAlignment = NSTextAlignment.justified
        textViewBeacons.backgroundColor = UIColor.lightGray
        // Use RGB colour
        textViewBeacons.backgroundColor = UIColor.white
        // Update UITextView font size and colour
        textViewBeacons.font = UIFont.systemFont(ofSize: 20)
        textViewBeacons.textColor = UIColor.black
        textViewBeacons.font = UIFont.boldSystemFont(ofSize: 20)
        textViewBeacons.font = UIFont(name: "Verdana", size: 17)
        // Capitalize all characters user types
        //textViewBeacons.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        // Make UITextView web links clickable
        textViewBeacons.isSelectable = true
        textViewBeacons.isEditable = false
        //textViewBeacons.dataDetectorTypes = UIDataDetectorTypes.link
        // Make UITextView corners rounded
        //textViewBeacons.layer.cornerRadius = 10
        // Enable auto-correction and Spellcheck
        //textViewBeacons.autocorrectionType = UITextAutocorrectionType.yes
        //textViewBeacons.spellCheckingType = UITextSpellCheckingType.yes
        // textViewBeacons.autocapitalizationType = UITextAutocapitalizationType.None
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Il metodo più importante dell'applicazione
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"//Data nello stesso formato che ho settato su Android
        //Data della scansione
        let result = formatter.string(from: date)
        //Stampo nella Console la data
        //print("Data Scansione: "+result+"\n\n")
        //Testo da inserire eventualmente in file di report
        //let record = result + " - " + String(beacons.count) + "\n" //cast da int a string
        //print("LivelloBatteria: \(getBatteryLevel()) - Data Scansione: "+record+"\n")
        //let firstBeacon = beacons.filter{ $0.proximity != CLProximity.unknown}
        let firstBeacon = beacons/*.filter{ $0.proximity != CLProximity.unknown}*/
        if(firstBeacon.count > 0){
            var dati:String = ""
            //Leggo tutti i Beacons nelle vicinanze
            for beacon in firstBeacon {
                var stato:String = ""
                if(beacon.proximity.rawValue == 0){ stato = NSLocalizedString("Sconosciuto", comment: "") }
                else if(beacon.proximity.rawValue == 1){ stato = NSLocalizedString("Molto vicino", comment: "") }
                else if(beacon.proximity.rawValue == 2){ stato = NSLocalizedString("Nelle vicinanze", comment: "") }
                else{ stato = NSLocalizedString("Lontano", comment: "") }
                //Stringa da stampare nella schermata della App
                let dato:String = "UUID: \(beacon.proximityUUID) \n"+NSLocalizedString("Prossimità", comment: "")+": \(stato) \nMajor:\(beacon.major) \nMinor:\(beacon.minor) \nRssi:\(beacon.rssi)" + "\n"
                
                //let array_DEMO = ["mpnet_build_teamservice_estero","barone","1","\(modelDevice)",result,"\(identifierForVendorDevice)","\(buildVersionNumber)",String(getBatteryLevel()),"1","\(beacon.proximityUUID):\(beacon.major):\(beacon.minor)","\(beacon.proximity.rawValue)","1","\(beacon.rssi)"]
                
                /*let array = [
                    UserDefaults.standard.string(forKey: "database"),
                    UserDefaults.standard.string(forKey: "login"),
                    UserDefaults.standard.string(forKey: "password"),
                    "\(modelDevice)",
                    result,
                    "\(identifierForVendorDevice)",
                    "\(buildVersionNumber)",
                    String(getBatteryLevel()),
                    "1",
                    "\(beacon.proximityUUID):\(beacon.major):\(beacon.minor)",
                    "\(beacon.proximity.rawValue)",
                    "1",
                    "\(beacon.rssi)"
                ]*/
                
                let array2 = [
                    "portale" : UserDefaults.standard.string(forKey: "indiPortale"), /* https://sviluppo.manpronet.com || UserDefaults.standard.string(forKey: "indiPortale") */
                    "database" : UserDefaults.standard.string(forKey: "database"),
                    "login" : UserDefaults.standard.string(forKey: "login"),
                    "password" : UserDefaults.standard.string(forKey: "password"),
                    "modelDevice" : "\(modelDevice)",
                    "dataCamp" : result,
                    "identifierForVendorDevice" : "\(identifierForVendorDevice)",
                    "buildVersionNumber" : "\(buildVersionNumber)",
                    "livBatteria" : String(getBatteryLevel()),
                    "tempoCampionamento" : "1",
                    "mac" : "\(beacon.proximityUUID):\(beacon.major):\(beacon.minor)",
                    "proximity" : "\(beacon.proximity.rawValue)",
                    "txPower" : "1",
                    "rssi" : "\(beacon.rssi)"
                ]
                print("||------------------||")
                print(array2 as! [String:String])
                print("||------------------||")
                //print(array_DEMO)
                //var record:String = createXMLRecord(array: array)
                
                print("Controllo se le credenziali sono corrette")
                print("||------------------||")
                checkCredentials(array: array2 as! [String:String])
                
                if(UserDefaults.standard.bool(forKey: "checkFlag") == true){
                    sendRecordWithPHP(array: array2 as! [String:String])
                    print("Credenziali risultano corrette")
                }
                else{
                    //Le credenziali non risultano corrette
                    print("Credenziali NON risultano corrette")
                }
                print("||------------------||")
                dati += dato + "\n"
            }
            
            //Costruisco la stringa da inserire nel file di reportistica -> "dataScan - livelloBatteria - nBeacon visti"
            let stringa:String = "\(result) - \(getBatteryLevel()) - \(firstBeacon.count)"
            //Inserisco nel File la stringa appena costruita
            insertDataScan(dataScan: stringa+"\n")
            //Costruisco e stampo la stringa da visualizzare nella textView
            self.textViewBeacons.text = NSLocalizedString("LivelloBatteria", comment: "")+": \(getBatteryLevel())%\n"+NSLocalizedString("Data Scansione", comment: "")+": " + result + "\n\n" + dati
            //Stampo i dati nella console
            print(dati)
            print("------------------")
            //Il Beacon più vicino mostro attraverso il colore la sua vicinanza
            guard let fB = firstBeacon.first?.proximity else {print("Beacon non trovati"); return}
            //Setto il colore della schermata con un colore a seconda della dua distanza da me
            let backgroundColour: UIColor = {
                switch fB {
                case .immediate : return UIColor.green
                case .near : return UIColor.orange
                case .far : return UIColor.red
                case .unknown : return UIColor.gray
                }
            }()
            //Applico il colore alla View dell'applicazione
            view.backgroundColor = backgroundColour
        }
    }
    
    //Metodo che controlla il cambiamento delle autorizzazione e ne gestisce gli aspetti
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            // Disable your app's location features
            locationManager.stopUpdatingLocation()
            locationManager.stopRangingBeacons(in: region)
            break
        case .authorizedWhenInUse:
            // Enable only your app's when-in-use features.
            locationManager.requestWhenInUseAuthorization()
            locationManager.stopRangingBeacons(in: region)
            locationManager.startRangingBeacons(in: region)
            break
        case .authorizedAlways:
            // Enable any of your app's location services.
            locationManager.requestAlwaysAuthorization()
            locationManager.stopRangingBeacons(in: region)
            locationManager.startRangingBeacons(in: region)
            break
        case .notDetermined:
            break
        }
    }
    
    /* CODICE PER SVILUPPI FUTURI */
    //Inserimento della data di scansione nel file reportCicliScanner.lm
    func insertDataScan(dataScan: String){
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(dataScan.data(using: .utf8)!)
            fileHandle.closeFile()
        } catch { print("Error writing to file \(error)") }
        //print(dataScan)
        //print("Saving data in: \(fileURL.path)")
    }
    
    //Lettura dei dati dal File
    func readFile(fileURL : URL){
        //if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        //let URL = dir.appendingPathComponent(fileName)
        //print("File Path -> \(URL.path)")
        print("Lettura contenuto del file reportCicliScanner.lm")
        var text: String = ""
        //reading
        do {
            let text2 = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
            //text = text + "\n" + text2
            text += "\n" + text2
            //print(text2)
        }
        catch {print("Errore nella lettura del file \(fileName)")}
        print(text)
        //}
    }
    
    //Ottengo il percorso della cartella dove saranno presenti i reports
    func getDocumentsDirectory() -> URL {
        //let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        //return paths[0]
        //Forma alternativa - riassuntiva
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /* METODO DA SITEMARE */
    func deleteFile() -> Bool {
        var flag : Bool = false
        /*if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
         */
        do {
            try FileManager.default.removeItem(atPath: fileName)
            flag = true
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
            flag = false
        }
        //}
        return flag
    }
    
    //Costruisce la stringa in formato XML
    func createXMLRecord(array : [String]) -> String{
        //Attualmente ho solamente riprodotto il stringa da Android App
        //Cerco di costruire più campi possibili lato IOS
        var record: String = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>"
        record += "<invio>"
        //Credenziali
        record += "<db_connect>" + array[0] + "</db_connect>"
        record += "<utente>" + array[1] + "</utente>"
        record += "<password>" + array[2] + "</password>"
        //Dati della Scansione
        record += "<model>" + array[3] + "</model>"
        record += "<datacampionamento>" + array[4] + "</datacampionamento>"
        record += "<iosid>" + array[5] + "</iosid>"
        record += "<batterialivello>" + array[6] + "</batterialivello>"
        record += "<tempocampionamento>" + array[7] + "</tempocampionamento>"
        record += "<numeroVersione>" + array[8] + "</numeroVersione>"
        //Dati dal Beacon
        record += "<mac>" + array[9] + "</mac>"
        record += "<distance>" + array[10] + "</distance>"
        record += "<txpower>" + array[11] + "</txpower>"
        record += "<rssi>" + array[12] + "</rssi>"
        //record += "<ios_id>" + array[13] + "</ios_id>"
        record += "</invio>"
        return record
    }
    
    //Costruisco la stringa per essere mandata via POST in php
    func createPHPRecord(array : [String:String]) -> String{
        print("createPHPRecord")
        var str:String = ""
        str += "db_connect=\(array["database"]!)&"
        str += "Login=\(array["login"]!)&"
        str += "Password=\(array["password"]!)&"
        str += "Model=\(array["modelDevice"]!)&"
        str += "dataCamp=\(array["dataCamp"]!)&"
        str += "Android_id=\(array["identifierForVendorDevice"]!)&"
        str += "NumeroVersioneApp=\(array["buildVersionNumber"]!)&"
        str += "LivelloBatteria=\(array["livBatteria"]!)&"
        str += "TempoCampionamento=\(array["tempoCampionamento"]!)&"
        str += "Mac=\(array["mac"]!)&"
        str += "Distance=\(array["proximity"]!)&"
        str += "TxPower=\(array["txPower"]!)&"
        str += "Rssi=\(array["rssi"]!)"
        return str
    }
    
    //Costruzione della notifica da visualizzare nel Divice
    func createNotification(contenuto : String){
        /*if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            var content = UNMutableNotificationContent()
            content.title = "ManProiBeacon"
            content.subtitle = "Scansione dei Beacon attiva"
            content.body = contenuto
            content.sound = UNNotificationSound.default
            content.threadIdentifier = "notifica-locale"
            let date = Date(timeIntervalSinceNow: 10)
        } else {
            // Fallback on earlier versions
        }*/
    }
    
    //Invio del record usando la pagina PHP
    func sendRecordWithPHP(array : [String:String]){
        print("sendRecordWithPHP")
        //var indirizzoPortale:String = "https://sviluppo.manpronet.com:"
        var indirizzoPortale:String = array["portale"]!
        
        if(indirizzoPortale == "" || indirizzoPortale == "https://sviluppo.manpronet.com"){
            indirizzoPortale = "https://sviluppo.manpronet.com:8089"
        }
        else{
            indirizzoPortale += ":8082"
        }
        
        let percorsoPortale:String = "/app_mobile/file.php"
        print("URL -> \(indirizzoPortale+percorsoPortale)")
        let request = NSMutableURLRequest(url: NSURL(string: indirizzoPortale+percorsoPortale)! as URL)
        request.httpMethod = "POST"
        //let postString = "a=\(usernametext.text!)&b=\(password.text!)&c=\(info.text!)&d=\(number.text!)"
        let postString = createPHPRecord(array: array)
        print(postString)
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            //print("response = \(response)")
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    //Metodo attualmente non in uso
    //Invia la stringa passata al Socket
    //True -> invio avvenuto con successo
    //False -> ERRORE, invio non avvenuto
    /*func sendRecord(record : String) -> Bool{
        //Operazioni da fare
        connect(record: record)
        //Ritorno stato per capire se l'invio è stato effettuato
        //return connecting
        return false
    }*/
    
    //Metodo per ottenere il livello della batteria del Dispositivo
    func getBatteryLevel() -> Int {
        //let battery = UIDevice.current.batteryLevel
        //return Int(battery * 100)
        //Forma alternativa - riassuntiva
        return Int(UIDevice.current.batteryLevel * 100)
    }
    
    //Metodo che attualmente non fa niente
    func connect(record : String) {
        /*
         connecting = true
         while connecting {
         print("connecting...")
         
         var readStream:  Unmanaged<CFReadStream>?
         var writeStream: Unmanaged<CFWriteStream>?
         
         CFStreamCreatePairWithSocketToHost(nil, self.serverAddress, self.serverPort, &readStream, &writeStream)
         
         // Documentation suggests readStream and writeStream can be assumed to
         // be non-nil. If you believe otherwise, you can test if either is nil
         // and implement whatever error-handling you wish.
         
         self.inputStream = readStream!.takeRetainedValue()
         self.outputStream = writeStream!.takeRetainedValue()
         
         self.inputStream.delegate = self
         self.outputStream.delegate = self
         
         self.inputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
         self.outputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
         
         self.inputStream.open()
         self.outputStream.open()
         
         // send record
         let handshake = record.data(using: .utf8)
         let returnVal = self.outputStream.write(UnsafePointer(handshake?.bytes), maxLength: handshake.length)
         print("written: \(returnVal)")
         
         // wait to receive handshake
         let bufferSize = 1024
         var buffer = Array<UInt8>(_unsafeUninitializedCapacity: bufferSize, initializingWith: 0)
         
         print("waintig for handshake...")
         
         let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
         if bytesRead >= 0 {
         var output = NSString(bytes: &buffer, length: bytesRead, encoding: NSUTF8StringEncoding)
         print("received from host \(serverAddress): \(output)")
         } else {
         // Handle error
         connecting = false
         }
         
         self.inputStream.close()
         self.outputStream.close()
         }
         */
    }
    
    func checkSettings(){
        if(UserDefaults.standard.string(forKey: "indiPortale") == nil){
            UserDefaults.standard.set("", forKey: "indiPortale")
        }
        print("IndirizzoPortale: \(UserDefaults.standard.string(forKey: "indiPortale")!)")
        
        if(UserDefaults.standard.string(forKey: "database") == nil){
            UserDefaults.standard.set("", forKey: "database")
        }
        print("Database: \(UserDefaults.standard.string(forKey: "database")!)")
        
        if(UserDefaults.standard.string(forKey: "login") == nil){
            UserDefaults.standard.set("", forKey: "login")
        }
        print("Login: \(UserDefaults.standard.string(forKey: "login")!)")
        
        if(UserDefaults.standard.string(forKey: "password") == nil){
            UserDefaults.standard.set("", forKey: "password")
        }
        print("Password: \(UserDefaults.standard.string(forKey: "password")!)")
        
        if(UserDefaults.standard.string(forKey: "checkCred") == nil){
            UserDefaults.standard.set("", forKey: "checkCred")
        }
        print("Messaggio delle credenziali: \(UserDefaults.standard.string(forKey: "checkCred")!)")
        
        if(UserDefaults.standard.string(forKey: "checkFlag") == nil){
            UserDefaults.standard.set("", forKey: "checkFlag")
        }
        print("Stato delle credenziali: \(UserDefaults.standard.string(forKey: "checkFlag")!)")
    }
    
    //Metodo attualmente non in uso
    /*public func stream(stream: Stream, handleEvent eventCode: Stream.Event) {
        
        print("stream event")
        
        if stream === inputStream {
            switch eventCode {
            case Stream.Event.errorOccurred:
                print("input: ErrorOccurred")
            case Stream.Event.openCompleted:
                print("input: OpenCompleted")
            case Stream.Event.hasBytesAvailable:
                print("input: HasBytesAvailable")
                /*
                 Here you can `read()` from `inputStream`
                 */
            default:
                break
            }
        }
        else if stream === outputStream {
            switch eventCode {
            case Stream.Event.errorOccurred:
                print("output: ErrorOccurred")
            case Stream.Event.openCompleted:
                print("output: OpenCompleted")
            case Stream.Event.hasSpaceAvailable:
                print("output: HasSpaceAvailable")
                /*
                 Here you can write() to `outputStream`
                 */
            default:
                break
            }
        }
        
    }
    */
    
    public func checkCredentials(array : [String:String]) {
        print("checkCredentials")
        //Devo controllare che le credenziali siano corrette
        //database && login && password
        var indirizzoPortale:String = ""
        if(array["portale"]! == "" || array["portale"]! == "https://sviluppo.manpronet.com"){
            indirizzoPortale = "https://sviluppo.manpronet.com:8089"
        }
        else{ indirizzoPortale = array["portale"]!+":8082" }
        //Controllo sintassi
        let flag = checkDomainSyntax(dominio : indirizzoPortale)
        if(flag == true){
            let percorsoPortale:String = "/app_mobile/controlloCred.php"
            print("URL -> \(indirizzoPortale+percorsoPortale)")
            let request = NSMutableURLRequest(url: NSURL(string: indirizzoPortale+percorsoPortale)! as URL)
            request.httpMethod = "POST"
            let postString = createCredRecord(array: [UserDefaults.standard.string(forKey: "database")!,UserDefaults.standard.string(forKey: "login")!,UserDefaults.standard.string(forKey: "password")!])
            print(postString)
            request.httpBody = postString.data(using: String.Encoding.utf8)
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                if error != nil {
                    print("error=\(String(describing: error))")
                    return
                }
                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                //print("responseString = \(String(describing: responseString))")
                print("responseString_v2 = \(responseString!)")
                let arr = responseString!.components(separatedBy: ",")
                let res = arr[0]
                let testo = arr[1]
                UserDefaults.standard.set(res, forKey: "checkFlag")
                UserDefaults.standard.set(testo, forKey: "checkCred")
                print("testo = \(UserDefaults.standard.string(forKey: "checkCred")!)")
            }
            task.resume()
        }
        else{
            //Errore
        }
    }
    
    public func createCredRecord(array : [String]) -> String{
        var result : String = ""
        print("createCredRecord")
        result += "db_connect=\(array[0])&"
        result += "Login=\(array[1])&"
        result += "Password=\(array[2])"
        return result
    }
    
    public func checkDomainSyntax(dominio : String) -> Bool{
        var flag : Bool = false
        print("URL da interrogare -> \(dominio)")
        if ( dominio.contains("https:") && dominio.contains(".com") ) {flag = true}
        return flag
    }
}
