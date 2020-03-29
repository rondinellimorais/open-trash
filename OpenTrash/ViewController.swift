//
//  ViewController.swift
//  OpenTrash
//
//  Created by Rondinelli Morais on 09/05/15.
//  Copyright (c) 2015 Rondinelli Morais. All rights reserved.
//

import Cocoa
import IOBluetooth

class ViewController: NSViewController {
	
	@IBOutlet weak var statusTrashTextLabel: NSTextField!
	@IBOutlet weak var waitingForConnectionProgressIndicator: NSProgressIndicator!
	@IBOutlet weak var waitingForConnectionTextField: NSTextField!
	
	var waitingForConnectionTimer:Timer?
	var kTrashDeviceMacAdress:String = "30-14-11-26-05-56"
	
	let IS_DEBUG = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if IS_DEBUG {
			initializeDebug()
		} else {
			initialize()
		}
		
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		appDelegate.statusTrashDidChange = { (status) -> Void in
			
			// quando o status da lixeira mudar
			switch status
			{
				case .Open:
					self.statusTrashTextLabel.stringValue = "Lixeira aberta!"
					self.statusTrashTextLabel.textColor = NSColor(calibratedRed: 78/255, green: 200/255, blue: 79/255, alpha: 1)
				
				case .Close:
					self.statusTrashTextLabel.stringValue = "Lixeira fechada!"
					self.statusTrashTextLabel.textColor = NSColor.red
					self.statusTrashTextLabel.textColor = NSColor(calibratedRed: 219/255, green: 58/255, blue: 49/255, alpha: 1)
				
				default:break
			}
		}
	}
	
	func initialize(){
		
		// initialize
		self.statusTrashTextLabel.isHidden = true
		self.waitingForConnectionProgressIndicator.startAnimation(nil)
		self.waitingForConnectionTextField.isHidden = false
		
		// check if trash is connected
		self.waitingForConnectionTimer = Timer.scheduledTimer(timeInterval: 1.0, target:self, selector: #selector(checkTrashConnection), userInfo: nil, repeats: true)
	}
	
	func initializeDebug(){
	 /**
		* Esse modo aqui é para programar a interface sem a conexão via bluetooth
		*/
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		appDelegate.startMonitor()
		
		// mostra a label de status da lixeira
		self.statusTrashTextLabel.isHidden = false
		
		// oculta a label de conexão
		self.waitingForConnectionTextField.isHidden = true
	}
	
	func connect(_ deviceAddress: String) -> Bool{
		
		for i in IOBluetoothDevice.pairedDevices() {
			let device = i as! IOBluetoothDevice
			
			if (device.addressString == deviceAddress) {
				return connect(device)
			}
		}
		return false
	}
	
	func connect(_ device: IOBluetoothDevice) -> Bool{
		
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		
		if device.isConnected() {
			appDelegate.startMonitor()
			return true
		}
		
		if( device.openConnection() == kIOReturnSuccess) {
			
			// Create an IOBluetoothSDPUUID object for the chat service UUID
			let sppServiceUUID = IOBluetoothSDPUUID(uuid16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
			
			// Finds the service record that describes the service (UUID) we are looking for:
			guard let sppServiceRecord:IOBluetoothSDPServiceRecord = device.getServiceRecord(for: sppServiceUUID) else {
				print("Error - no spp service in selected device.  ***This should never happen since the selector forces the user to select only devices with spp.***\n" )
				return false
			}
			
			// To connect we need a device to connect and an RFCOMM channel ID to open on the device:
			var rfcommChannelID = BluetoothRFCOMMChannelID()
			if sppServiceRecord.getRFCOMMChannelID(&rfcommChannelID) != kIOReturnSuccess {
				print("Error - no spp service in selected device.  ***This should never happen an spp service must have an rfcomm channel id.***\n" );
				return false
			}
			
			// Open asyncronously the rfcomm channel when all the open sequence is completed my implementation of "rfcommChannelOpenComplete:" will be called.
			if (device.openRFCOMMChannelAsync(&appDelegate.mRFCOMMChannel, withChannelID:rfcommChannelID, delegate: self) != kIOReturnSuccess) && ( appDelegate.mRFCOMMChannel != nil ) {
				
				// Something went bad (looking at the error codes I can also say what, but for the moment let's not dwell on
				// those details). If the device connection is left open close it and return an error:
				print("Error - open sequence failed.***\n" )
				
				appDelegate.closeDeviceConnectionOnDevice(device)
				
				return false
			}
			
			// So far a lot of stuff went well, so we can assume that the device is a good one and that rfcomm channel open process is going
			// well. So we keep track of the device and we (MUST) retain the RFCOMM channel:
			appDelegate.mBluetoothDevice = device
			
			return true
		}
		
		return false
	}
	
	@objc func checkTrashConnection(){
		
		if connect(kTrashDeviceMacAdress) {
			
			self.waitingForConnectionTimer?.invalidate()
			self.waitingForConnectionTimer = nil
			
			self.waitingForConnectionProgressIndicator.stopAnimation(nil)
			self.waitingForConnectionTextField.isHidden = true
			
			self.statusTrashTextLabel.isHidden = false
		}
	}
	
	@objc func closeDeviceConnectionOnDevice(_ device:IOBluetoothDevice) {
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		appDelegate.closeDeviceConnectionOnDevice(device)
	}
	
	@objc func closeRFCOMMConnectionOnChannel(_ channel:IOBluetoothRFCOMMChannel){
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		appDelegate.closeRFCOMMConnectionOnChannel(channel)
	}
}

extension ViewController : IOBluetoothRFCOMMChannelDelegate {
	
	// Called by the RFCOMM channel on us when new data is received from the channel:
	func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
		
		//        unsigned char *dataAsBytes = (unsigned char *)dataPointer;
		//
		//        while ( dataLength-- )
		//        {
		//            [self addThisByteToTheLogs:*dataAsBytes];
		//            dataAsBytes++;
		//        }
		
		let buf = UnsafeBufferPointer(start: dataPointer.assumingMemoryBound(to: UInt8.self), count: dataLength)
		let datas = Array(buf)
		print(Data(bytes: datas).base64EncodedString())
	}
	
	// Called by the RFCOMM channel on us once the baseband and rfcomm connection is completed:
	func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
		
		// If it failed to open the channel call our close routine and from there the code will
		// perform all the necessary cleanup:
		if error != kIOReturnSuccess {
			
			print("Error - failed to open the RFCOMM channel with error \(error).\n")
			
			self.rfcommChannelClosed(rfcommChannel)
			
			return
		}
		
		// The RFCOMM channel is now completly open so it is possible to send and receive data
		// ... add the code that begin the send data ... for example to reset a modem:
		// http://buildbot.com.br/blog/configuracao-do-modulo-bluetooth-hc-06-com-arduino/
		
		//        let str = "AT\n"
		//        let data = str.data(using: String.Encoding.ascii)!
		//
		//        let writebuffer = NSMutableData()
		//        writebuffer.setData(data)
		//
		//        rfcommChannel.writeSync(writebuffer.mutableBytes, length: UInt16(writebuffer.length))
		
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		
		appDelegate.rfcommChannel = rfcommChannel
		
		appDelegate.startMonitor()
	}
	
	// Called by the RFCOMM channel on us when something happens and the connection is lost:
	func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
		
		let appDelegate = NSApplication.shared.delegate as! AppDelegate
		
		// wait a second and close the device connection as well:
		self.performSelector(onMainThread: #selector(closeDeviceConnectionOnDevice(_:)), with: appDelegate.mBluetoothDevice, waitUntilDone: true)
		
		// wait a second and close the device connection as well:
		self.performSelector(onMainThread: #selector(closeRFCOMMConnectionOnChannel(_:)), with: appDelegate.mRFCOMMChannel, waitUntilDone: true)
	}
	
	func rfcommChannelControlSignalsChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
		print("rfcommChannelControlSignalsChanged")
	}
	
	func rfcommChannelFlowControlChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
		print("rfcommChannelFlowControlChanged")
	}
	
	func rfcommChannelWriteComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn) {
		print("rfcommChannelWriteComplete")
	}
	
	func rfcommChannelQueueSpaceAvailable(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
		print("rfcommChannelQueueSpaceAvailable")
	}
}
