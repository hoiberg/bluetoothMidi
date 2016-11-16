//
//  TableViewController.swift
//  BluetoothMIDI
//
//  Created by Alex on 11/11/2016.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//TODO: INFO SCREEN

import UIKit
import CoreBluetooth
import CoreMIDI

class Device {
    var peripheral: CBPeripheral?,
        name: String,
        identifier: UUID
    
    var midiBuffer = [UInt8](),
        expectedLength = 0
    
    init(name: String, identifier: UUID) {
        self.name = name
        self.identifier = identifier
    }
}

class TableViewController: CustomTableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //
    // MARK: - IBOutlets
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    //
    // MARK: - Variables
    
    let serviceUUIDs = [CBUUID(string: "FFE0")],
        characteristicUUIDs = [CBUUID(string: "FFE1")]
    
    var centralManager: CBCentralManager!
    
    var savedDevices = [Device](),
        newDevices = [CBPeripheral](),
        connectingDevices = [CBPeripheral]()
    
    var midiClient: MIDIClientRef = 0,
        midiOutputPort: MIDIPortRef = 0,
        midiDestinations = [MIDIEndpointRef](),
        selectedDestination: Int? = nil
    
    
    //
    // MARK: - Helper Functions
    
    func save() {
        var names = [String](),
            ids = [String]()
        for device in savedDevices {
            names.append(device.name)
            ids.append(device.identifier.uuidString)
        }
        
        UserDefaults.standard.set(names, forKey: "SavedNames")
        UserDefaults.standard.set(ids, forKey: "SavedUUIDs")
        UserDefaults.standard.synchronize()
    }
    
    
    //
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: .UIApplicationWillResignActive, object: nil)

        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        let names = UserDefaults.standard.array(forKey: "SavedNames") as? [String] ?? [String](),
            ids = UserDefaults.standard.array(forKey: "SavedUUIDs") as? [String] ?? [String]()
        for i in 0 ..< names.count {
            savedDevices.append(Device(name: names[i], identifier: UUID(uuidString: ids[i])!))
        }
        
        MIDIClientCreate("BleMidiClient" as CFString, nil, nil, &midiClient)
        MIDIOutputPortCreate(midiClient, "BleMidiClient" as CFString, &midiOutputPort)
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        applicationDidBecomeActive()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    //
    // MARK: - UIApplication
    
    func applicationDidBecomeActive(_: NSNotification? = nil) {
        
        newDevices = []

        if centralManager.state == .poweredOn {
            activityIndicator.startAnimating()
            statusLabel.text = "Scanning"
            centralManager.scanForPeripherals(withServices: serviceUUIDs)
            for peripheral in centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs) {
                var isNew = true
                for device in savedDevices {
                    if peripheral.identifier == device.identifier {
                        if !connectingDevices.contains(peripheral) {
                            centralManager.connect(peripheral)
                            connectingDevices.append(peripheral)
                        }
                        isNew = false
                    }
                }
                
                if isNew && !newDevices.contains(peripheral) {
                    newDevices.append(peripheral)
                }
            }
        } else {
            activityIndicator.stopAnimating()
            statusLabel.text = "Bluetooth Off"
        }
        
        midiDestinations = []
        
        for i in 0 ..< MIDIGetNumberOfDestinations() {
            let destination = MIDIGetDestination(i)
            if destination != 0 {
                midiDestinations.append(destination)
            }
        }
        
        if selectedDestination != nil && selectedDestination! >= midiDestinations.count {
            selectedDestination = nil
        }
        
        tableView.reloadData()
    }
    
    func applicationWillResignActive(_: NSNotification? = nil) {
        if centralManager.isScanning {
            activityIndicator.stopAnimating()
            statusLabel.text = "Done Scanning"
            centralManager.stopScan()
        }
    }
    
    
    //
    // MARK: - CBCentralManager
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            activityIndicator.stopAnimating()
            statusLabel.text = "Bluetooth Off"
            errorNotice("Bluetooth Off", autoClear: true)
            savedDevices.forEach { $0.peripheral = nil }
            newDevices = []
            connectingDevices = []
            tableView.reloadData()
        } else {
            applicationDidBecomeActive()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var isNew = true
        for device in savedDevices {
            if peripheral.identifier == device.identifier {
                if !connectingDevices.contains(peripheral) {
                    centralManager.connect(peripheral)
                    connectingDevices.append(peripheral)
                }
                isNew = false
            }
        }
        
        if isNew && !newDevices.contains(peripheral) {
            newDevices.append(peripheral)
        }
        
        tableView.reloadData()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(serviceUUIDs)
        
        delay(5) {
            if self.connectingDevices.contains(peripheral) {
                self.centralManager.cancelPeripheralConnection(peripheral)
                self.infoNotice("Failed", autoClear: true)
                self.connectingDevices.remove(at: self.connectingDevices.index(of: peripheral)!)
                self.tableView.reloadData()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(error?.localizedDescription)")
        infoNotice("Failed", autoClear: true)
        connectingDevices.remove(at: connectingDevices.index(of: peripheral)!)
        tableView.reloadData()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        for device in savedDevices {
            if peripheral.identifier == device.identifier {
                device.peripheral = nil
            }
        }
        
        if connectingDevices.contains(peripheral) {
            infoNotice("Failed to connect to\n\(peripheral.name ?? "Unidentified")", autoClear: true)
            connectingDevices.remove(at: connectingDevices.index(of: peripheral)!)
        }
        
        if UIApplication.shared.applicationState == .active {
            centralManager.stopScan()
            centralManager.scanForPeripherals(withServices: serviceUUIDs)
            for peripheral in centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs) {
                var isNew = true
                for device in savedDevices {
                    if peripheral.identifier == device.identifier {
                        if !connectingDevices.contains(peripheral) && device.peripheral == nil {
                            centralManager.connect(peripheral)
                            connectingDevices.append(peripheral)
                        }
                        isNew = false
                    }
                }
                
                if isNew && !newDevices.contains(peripheral) {
                    newDevices.append(peripheral)
                }
            }
            
            tableView.reloadData()
        }
    }
    
    
    //
    // MARK: - CBPeripheral
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristicUUIDs.contains(where: { $0 == characteristic.uuid }) {
                peripheral.setNotifyValue(true, for: characteristic)
                connectingDevices.remove(at: connectingDevices.index(of: peripheral)!)
                
                if newDevices.contains(peripheral) {
                    newDevices.remove(at: newDevices.index(of: peripheral)!)
                    savedDevices.append(Device(name: peripheral.name ?? "Unidentified", identifier: peripheral.identifier))
                    save()
                }
                
                for device in savedDevices {
                    if peripheral.identifier == device.identifier {
                        device.peripheral = peripheral
                        device.midiBuffer = []
                        device.expectedLength = 0
                        if device.name != peripheral.name {
                            device.name = peripheral.name ?? "Unidentified"
                            save()
                        }
                    }
                }
                
                tableView.reloadData()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let _ = characteristic.value else { return }
        
        let device = savedDevices[savedDevices.index(where: { $0.peripheral === peripheral })!]
        var expected = device.expectedLength,
            buffer = device.midiBuffer
        
        let bytes: [UInt8] = characteristic.value!.withUnsafeBytes {
            Array(UnsafeBufferPointer<UInt8>(start: $0, count: characteristic.value!.count/MemoryLayout<UInt8>.size))
        }
        
        for b in bytes {
            if buffer.isEmpty {
                if let msg = MidiMessageNumber(rawValue: b >> 4) {
                    switch msg {
                    case .ProgramChange,
                         .ChannelPressureAftertouch:
                        expected = 2;
                    case .NoteOff,
                         .NoteOn,
                         .PolyphonicAftertouch,
                         .ControlChange,
                         .PitchWheelChange:
                        expected = 3;
                    case .System:
                        if let sys = MidiSystemMessageNumber(rawValue: b) {
                            switch sys {
                            case .SystemExclusive:
                                expected = 256 // variable length; prevents buffer overflow
                            case .Undefined1,
                                 .Undefined2,
                                 .TuneRequest,
                                 .TimingClock,
                                 .Undefined3,
                                 .Start,
                                 .Continue,
                                 .Stop,
                                 .Undefined4,
                                 .ActiveSensing,
                                 .Reset:
                                expected = 1;
                            case .TimeCode,
                                 .SongSelect:
                                expected = 2;
                            case .SongPosition:
                                expected = 3;
                            case .EndOfExclusive:
                                expected = 1; // shouldn't happen
                            }
                        } else {
                            continue // not a sysmsg number; ignore
                        }
                    }
                } else {
                    continue // not a msg number; ignore
                }
            }
            
            if buffer.count < expected {
                buffer.append(b)
            }
            
            if expected == 256 && MidiSystemMessageNumber(rawValue: b) == .EndOfExclusive {
                expected = buffer.count // Important: Not tested
            }
            
            if buffer.count == expected {
                // we can finally send our data!! Yeeeeeeehaw!
                if let index = selectedDestination {
                    let dest = midiDestinations[index]
                    // using an alternative method to be able to send data of variable length
                    //http://stackoverflow.com/questions/26494434/using-midipacketlist-in-swift
                    var packet = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
                    let packetList = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
                    packet = MIDIPacketListInit(packetList)
                    packet = MIDIPacketListAdd(packetList, 1024, packet, 0, buffer.count, buffer)
                    MIDISend(midiOutputPort, dest, packetList)
                    packet.deinitialize(count: 1)
                    packetList.deinitialize(count: 1)
                    packetList.deallocate(capacity: 1)
                }
                
                expected = 0
                buffer = []
            }
        }
        
        device.expectedLength = expected
        device.midiBuffer = buffer
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return savedDevices.isEmpty ? 1 : savedDevices.count
        } else if section == 1 {
            return newDevices.isEmpty ? 1 : newDevices.count
        } else {
            return midiDestinations.isEmpty ? 1 : midiDestinations.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["My Devices", "New Devices", "Destinations"][section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if savedDevices.isEmpty {
                return tableView.dequeueReusableCell(withIdentifier: "NoSavedDeviceCell", for: indexPath)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath),
                    device = savedDevices[indexPath.row]
                
                cell.textLabel!.text = device.name
                cell.detailTextLabel!.text = device.peripheral == nil ? "Not Connected" : "Active"
                cell.selectionStyle = .none
                
                if connectingDevices.contains(where: { $0.identifier == device.identifier }) {
                    cell.detailTextLabel!.text = "Connecting..."
                }
                
                return cell
            }
        } else if indexPath.section == 1 {
            if newDevices.isEmpty {
                return tableView.dequeueReusableCell(withIdentifier: "NoNewDeviceCell", for: indexPath)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath),
                    device = newDevices[indexPath.row]
                
                cell.textLabel!.text = device.name ?? "Unidentified"
                cell.detailTextLabel!.text = ""
                cell.selectionStyle = .default
                
                if connectingDevices.contains(device) {
                    cell.detailTextLabel!.text = "Connecting..."
                }
                
                return cell
            }
        } else {
            if midiDestinations.isEmpty {
                return tableView.dequeueReusableCell(withIdentifier: "NoDestinationCell", for: indexPath)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath),
                    destination = midiDestinations[indexPath.row]
                
                var str: Unmanaged<CFString>?,
                    name = "Error"
                
                if MIDIObjectGetStringProperty(destination, kMIDIPropertyDisplayName, &str) == OSStatus(noErr) {
                    name = str!.takeRetainedValue() as String
                }
                
                cell.textLabel!.text = name
                
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && !newDevices.isEmpty {
            tableView.deselectRow(at: indexPath, animated: true)
            if !connectingDevices.contains(newDevices[indexPath.row]) {
                connectingDevices.append(newDevices[indexPath.row])
                centralManager.connect(newDevices[indexPath.row])
                tableView.reloadData()
            }
        } else if indexPath.section == 2 && !midiDestinations.isEmpty {
            tableView.deselectRow(at: indexPath, animated: true)
            if indexPath.row == selectedDestination {
                selectedDestination = nil
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
            } else {
                if selectedDestination != nil {
                    let oldIndexPath = IndexPath(row: selectedDestination!, section: 2)
                    tableView.cellForRow(at: oldIndexPath)!.accessoryType = .none
                }
                selectedDestination = indexPath.row
                tableView.cellForRow(at: indexPath)!.accessoryType = .checkmark
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        if indexPath.section == 2 && !midiDestinations.isEmpty {
            if indexPath.row == selectedDestination {
                cell.accessoryType = .checkmark
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && !savedDevices.isEmpty
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return indexPath.section == 0 && !savedDevices.isEmpty ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if let peripheral = savedDevices[indexPath.row].peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        savedDevices.remove(at: indexPath.row)
        tableView.reloadData()
        
        centralManager.stopScan()
        centralManager.scanForPeripherals(withServices: serviceUUIDs)
        for peripheral in centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs) {
            var isNew = true
            for device in savedDevices {
                if peripheral.identifier == device.identifier {
                    if !connectingDevices.contains(peripheral) && device.peripheral == nil {
                        centralManager.connect(peripheral)
                        connectingDevices.append(peripheral)
                    }
                    isNew = false
                }
            }
            
            if isNew && !newDevices.contains(peripheral) {
                newDevices.append(peripheral)
            }
        }
    }
}


//
// MARK: - More Helper Stuff

func delay(_ delay: Double, callback: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: callback)
}

enum MidiMessageNumber: UInt8 {
    case NoteOff = 0x8,
         NoteOn = 0x9,
         PolyphonicAftertouch = 0xA,
         ControlChange = 0xB,
         ProgramChange = 0xC,
         ChannelPressureAftertouch = 0xD,
         PitchWheelChange = 0xE,
         System = 0xF
}

enum MidiSystemMessageNumber: UInt8 {
    case SystemExclusive = 0xF0,
         TimeCode = 0xF1,
         SongPosition = 0xF2,
         SongSelect = 0xF3,
         Undefined1 = 0xF4,
         Undefined2 = 0xF5,
         TuneRequest = 0xF6,
         EndOfExclusive = 0xF7,
         TimingClock = 0xF8,
         Undefined3 = 0xF9,
         Start = 0xFA,
         Continue = 0xFB,
         Stop = 0xFC,
         Undefined4 = 0xFD,
         ActiveSensing = 0xFE,
         Reset = 0xFF
}
