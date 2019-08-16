//
//  ViewController.swift
//  BleROSCont
//
//  Created by idev on 2019/08/17.
//  Copyright © 2019 idev. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    let kServiveUUID = "74829A60-9471-4804-AD29-9497AD731EC9"
    let kCharacteristcUUID = "1C05C777-D455-4194-8196-F176E656A90F"

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var serviceUUID : CBUUID!
    var charcteristicUUID: CBUUID!

    @IBOutlet weak var p1Button: UIButton!
    @IBOutlet weak var p2Button: UIButton!
    @IBOutlet weak var msgLabel: UILabel!

    @IBAction func p1ButtonClicked(_ sender: Any) {
        let data: Data! = "p1".data(using: .utf8);
        let service: CBService! = peripheral.services!.first;
        let characteristic: CBCharacteristic! = service.characteristics!.first;
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse);
        msgLabel.text = "P1";
    }
    
    @IBAction func p2ButtonClicked(_ sender: Any) {
        let data: Data! = "p2".data(using: .utf8);
        let service: CBService! = peripheral.services!.first;
        let characteristic: CBCharacteristic! = service.characteristics!.first;
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse);
        msgLabel.text = "P2";
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        p1Button.layer.borderColor = UIColor.blue.cgColor;
        p1Button.layer.borderWidth = 1.0;
        p1Button.layer.cornerRadius = 10.0;
        p2Button.layer.borderColor = UIColor.blue.cgColor;
        p2Button.layer.borderWidth = 1.0;
        p2Button.layer.cornerRadius = 10.0;
        p1Button.isEnabled = false;
        p2Button.isEnabled = false;
        msgLabel.text = "init...";
        setup();
    }
    
    private func setup() {
        msgLabel.text = "setup";
        centralManager = CBCentralManager(delegate: self, queue: nil)
        serviceUUID = CBUUID(string: kServiveUUID)
        charcteristicUUID = CBUUID(string: kCharacteristcUUID)
    }
}

//MARK : - CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        //電源ONを待って、スキャンする
        case CBManagerState.poweredOn:
            msgLabel.text = "powerOn";
            let services: [CBUUID] = [serviceUUID]
            centralManager?.scanForPeripherals(withServices: services,
                                               options: nil)
        default:
            break
        }
    }
    
    /// ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        msgLabel.text = "device finded";
        self.peripheral = peripheral
        centralManager?.stopScan()
        //接続開始
        central.connect(peripheral, options: nil)
    }
    
    /// 接続されると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        msgLabel.text = "connected";
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    /// 切断されると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        p1Button.isEnabled = false;
        p2Button.isEnabled = false;
        msgLabel.text = "disconnected";
        // 再びスキャン開始
        let services: [CBUUID] = [serviceUUID]
        centralManager?.scanForPeripherals(withServices: services,
                                           options: nil)
    }
}

//MARK : - CBPeripheralDelegate
extension ViewController: CBPeripheralDelegate {
    /// サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        msgLabel.text = "service finded";
        if error != nil {
            print(error.debugDescription)
            return
        }
        //キャリアクタリスティク探索開始
        peripheral.discoverCharacteristics([charcteristicUUID],
                                           for: (peripheral.services?.first)!)
    }
    
    /// キャリアクタリスティク発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        msgLabel.text = "characteristics finded";
        if error != nil {
            print(error.debugDescription)
            return
        }
        p1Button.isEnabled = true;
        p2Button.isEnabled = true;
        peripheral.setNotifyValue(true,
                                  for: (service.characteristics?.first)!)
    }
    
    /// データ更新時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        updateWithData(data: characteristic.value!)
    }
    
    private func updateWithData(data : Data) {
        print(#function)
        let str: String? = String(data: data, encoding: .utf8);
        msgLabel.text = str;
    }
}
