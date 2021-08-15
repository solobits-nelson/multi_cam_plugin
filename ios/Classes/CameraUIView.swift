import UIKit
import AVFoundation
import Photos
import ReplayKit


@available(iOS 13.0, *)
public class CameraUIView: UIView,AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate,RPPreviewViewControllerDelegate{

    required init() {
        super.init(frame: CGRect.zero)
        
        let screenBounds = UIScreen.main.bounds
        
        backPreview.frame = screenBounds
        backPreview.accessibilityLabel = "backPreview"
        
        let _backCamFrame = backPreview.frame
        
        frontPreview.frame =  CGRect(x: screenBounds.width - _backCamFrame.width/2, y: screenBounds.height - _backCamFrame.height/2, width: 180, height: 220.0)
        frontPreview.accessibilityLabel = "frontPreview"
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        frontPreview.isUserInteractionEnabled = true
        frontPreview.addGestureRecognizer(panGesture)
        
        
        backPreview.addSubview(frontPreview)
        backPreview.addSubview(recordButton)
        self.addSubview(backPreview)
        
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    let backPreview = ViewPreview()
    let frontPreview = ViewPreview()
    var panGesture = UIPanGestureRecognizer()
    
    let recordButton = UIButton()
    
    
    var dualVideoSession = AVCaptureMultiCamSession()
    var audioDeviceInput: AVCaptureDeviceInput?
    
    
    var backDeviceInput:AVCaptureDeviceInput?
    var backVideoDataOutput = AVCaptureVideoDataOutput()
    var backViewLayer:AVCaptureVideoPreviewLayer?
    var backAudioDataOutput = AVCaptureAudioDataOutput()
    
    
    var frontDeviceInput:AVCaptureDeviceInput?
    var frontVideoDataOutput = AVCaptureVideoDataOutput()
    var frontViewLayer:AVCaptureVideoPreviewLayer?
    var frontAudioDataOutput = AVCaptureAudioDataOutput()
    
    let dualVideoSessionQueue = DispatchQueue(label: "dual video session queue")
    
    let dualVideoSessionOutputQueue = DispatchQueue(label: "dual video session data output queue")
    
    
    
    
    //MARK:- Setup Dual Video Session
    func setUp(){
        
        #if targetEnvironment(simulator)
        let alertController = UIAlertController(title: "Mulit_Cam", message: "Please run on physical device", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
        
        return
        
        #endif
        
        // Set up the back and front video preview views.
        
        backPreview.videoPreviewLayer.setSessionWithNoConnection(dualVideoSession)
        frontPreview.videoPreviewLayer.setSessionWithNoConnection(dualVideoSession)
        
        // Store the back and front video preview layers so we can connect them to their inputs
        backViewLayer = backPreview.videoPreviewLayer
        frontViewLayer = frontPreview.videoPreviewLayer
        
        // Keep the screen awake
        UIApplication.shared.isIdleTimerDisabled = true
        
        dualVideoPermisson()
    }
    
    //MARK:- User Permission for Dual Video Session
    //ask user permissin for recording video from device
    func dualVideoPermisson(){
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            configureDualVideo()
            break
            
        case .notDetermined:
            
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted{
                    self.configureDualVideo()
                }
            })
            
            break
            
        default:
            // The user has previously denied access.
            DispatchQueue.main.async {
                let changePrivacySetting = "Device doesn't have permission to use the camera, please change privacy settings"
                let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                alertController.addAction(UIAlertAction(title: "Settings", style: .`default`,handler: { _ in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL,  options: [:], completionHandler: nil)
                    }
                }))
                
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    func configureDualVideo(){
        addNotifer()
        dualVideoSessionQueue.async {
            self.setUpSession()
        }
    }
    
    //MARK:- Add and Handle Observers
    func addNotifer() {
        
        // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
        // Add observers to handle these session interruptions and inform the user.
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError,object: dualVideoSession)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: dualVideoSession)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: dualVideoSession)
    }
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
        print("Session was interrupted")
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        print("Session interrupt ended")
    }
    
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            //Manage according to condition
        } else {
            //Manage according to condition
        }
    }
    
    func setUpSession(){
        if !AVCaptureMultiCamSession.isMultiCamSupported{
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: "Device is not supporting multicam feature", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
            return
        }
        
        guard setUpBackCamera() else{
            
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: "issue while setuping back camera", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
            return
            
        }
        
        guard setUpFrontCamera() else{
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: "issue while setuping front camera", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
            return
        }
        
        guard setUpAudio() else{
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: "issue while setuping audio session", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
            return
        }
        
        dualVideoSessionQueue.async {
            self.dualVideoSession.startRunning()
        }
        
    }
    
    
    
    func setUpBackCamera() -> Bool{
        //start configuring dual video session
        dualVideoSession.beginConfiguration()
        defer {
            //save configuration setting
            dualVideoSession.commitConfiguration()
        }
        
        //search back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("no back camera")
            return false
        }
        
        // append back camera input to dual video session
        do {
            backDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            
            guard let backInput = backDeviceInput,dualVideoSession.canAddInput(backInput) else {
                print("no back camera device input")
                return false
            }
            dualVideoSession.addInputWithNoConnections(backInput)
        } catch {
            print("no back camera device input: \(error)")
            return false
        }
        
        // seach back video port
        guard let backDeviceInput = backDeviceInput,
              let backVideoPort = backDeviceInput.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: backCamera.position).first else {
            print("no back camera input's video port")
            return false
        }
        
        // append back video ouput
        guard dualVideoSession.canAddOutput(backVideoDataOutput) else {
            print("no back camera output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(backVideoDataOutput)
        backVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        backVideoDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // connect back ouput to dual video connection
        let backOutputConnection = AVCaptureConnection(inputPorts: [backVideoPort], output: backVideoDataOutput)
        guard dualVideoSession.canAddConnection(backOutputConnection) else {
            print("no connection to the back camera video data output")
            return false
        }
        dualVideoSession.addConnection(backOutputConnection)
        backOutputConnection.videoOrientation = .portrait
        
        // connect back input to back layer
        guard let backLayer = backViewLayer else {
            return false
        }
        let backConnection = AVCaptureConnection(inputPort: backVideoPort, videoPreviewLayer: backLayer)
        guard dualVideoSession.canAddConnection(backConnection) else {
            print("no a connection to the back camera video preview layer")
            return false
        }
        dualVideoSession.addConnection(backConnection)
        
        return true
    }
    
    
    func setUpFrontCamera() -> Bool{
        
        //start configuring dual video session
        dualVideoSession.beginConfiguration()
        defer {
            //save configuration setting
            dualVideoSession.commitConfiguration()
        }
        
        //search front camera for dual video session
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("no front camera")
            return false
        }
        
        // append front camera input to dual video session
        do {
            frontDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            
            guard let frontInput = frontDeviceInput, dualVideoSession.canAddInput(frontInput) else {
                print("no front camera input")
                return false
            }
            dualVideoSession.addInputWithNoConnections(frontInput)
        } catch {
            print("no front input: \(error)")
            return false
        }
        
        // search front video port for dual video session
        guard let frontDeviceInput = frontDeviceInput,
              let frontVideoPort = frontDeviceInput.ports(for: .video, sourceDeviceType: frontCamera.deviceType, sourceDevicePosition: frontCamera.position).first else {
            print("no front camera device input's video port")
            return false
        }
        
        // append front video output to dual video session
        guard dualVideoSession.canAddOutput(frontVideoDataOutput) else {
            print("no the front camera video output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(frontVideoDataOutput)
        frontVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        frontVideoDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // connect front output to dual video session
        let frontOutputConnection = AVCaptureConnection(inputPorts: [frontVideoPort], output: frontVideoDataOutput)
        guard dualVideoSession.canAddConnection(frontOutputConnection) else {
            print("no connection to the front video output")
            return false
        }
        dualVideoSession.addConnection(frontOutputConnection)
        frontOutputConnection.videoOrientation = .portrait
        frontOutputConnection.automaticallyAdjustsVideoMirroring = false
        frontOutputConnection.isVideoMirrored = true
        
        // connect front input to front layer
        guard let frontLayer = frontViewLayer else {
            return false
        }
        let frontLayerConnection = AVCaptureConnection(inputPort: frontVideoPort, videoPreviewLayer: frontLayer)
        guard dualVideoSession.canAddConnection(frontLayerConnection) else {
            print("no connection to front layer")
            return false
        }
        dualVideoSession.addConnection(frontLayerConnection)
        frontLayerConnection.automaticallyAdjustsVideoMirroring = false
        frontLayerConnection.isVideoMirrored = true
        
        return true
    }
    
    
    func setUpAudio() -> Bool{
        //start configuring dual video session
        dualVideoSession.beginConfiguration()
        defer {
            //save configuration setting
            
            dualVideoSession.commitConfiguration()
        }
        
        // serach audio device for dual video session
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("no the microphone")
            return false
        }
        
        // append auido to dual video session
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            guard let audioInput = audioDeviceInput,
                  dualVideoSession.canAddInput(audioInput) else {
                print("no audio input")
                return false
            }
            dualVideoSession.addInputWithNoConnections(audioInput)
        } catch {
            print("no audio input: \(error)")
            return false
        }
        
        //search audio port back
        guard let audioInputPort = audioDeviceInput,
              let backAudioPort = audioInputPort.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .back).first else {
            print("no front back port")
            return false
        }
        
        // search audio port front
        guard let frontAudioPort = audioInputPort.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .front).first else {
            print("no front audio port")
            return false
        }
        
        // append back output to dual video session
        guard dualVideoSession.canAddOutput(backAudioDataOutput) else {
            print("no back audio data output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(backAudioDataOutput)
        backAudioDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // append front ouput to dual video session
        guard dualVideoSession.canAddOutput(frontAudioDataOutput) else {
            print("no front audio data output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(frontAudioDataOutput)
        frontAudioDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // add back output to dual video session
        let backOutputConnection = AVCaptureConnection(inputPorts: [backAudioPort], output: backAudioDataOutput)
        guard dualVideoSession.canAddConnection(backOutputConnection) else {
            print("no back audio connection")
            return false
        }
        dualVideoSession.addConnection(backOutputConnection)
        
        // add front output to dual video session
        let frontutputConnection = AVCaptureConnection(inputPorts: [frontAudioPort], output: frontAudioDataOutput)
        guard dualVideoSession.canAddConnection(frontutputConnection) else {
            print("no front audio connection")
            return false
        }
        dualVideoSession.addConnection(frontutputConnection)
        
        return true
    }
    
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        backPreview.bringSubviewToFront(frontPreview)
        let translation = sender.translation(in: backPreview)
        frontPreview.center = CGPoint(x: frontPreview.center.x + translation.x, y: frontPreview.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: backPreview)
    }
    
}



