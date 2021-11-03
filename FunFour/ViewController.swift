//
//  ViewController.swift
//  FunFour
//
//  Created by Amor on 2021/10/26.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    //MARK: Class Properties
    lazy var videoManager:VideoAnalgesic! = {
        let tmpManager = VideoAnalgesic(mainView: self.view)
        tmpManager.setCameraPosition(position: .back)
        return tmpManager
    }()
//    let wrapper = OpenCVWrapper()
    lazy var detector:CIDetector! = {
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                            CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        return detector
    }()
    let wrapper = OpenCVWrapper()
    
    //MARK: when there is a new value to set isSmile, it would async to display whether the face is smiling or blinking
    var isSmile:Bool = false{
        willSet(newValue){
            if newValue != self.isSmile {
                DispatchQueue.main.async {
                    self.faceLable.text = "smile:\(newValue) blinking:\(self.eyeBlinking)"
                }
            }
        }
    }
    
    //MARK: when there is a new value to set eyeBlinking, it would async to display whether the face is smiling or blinking
    var eyeBlinking:String = ""{// "left" means left eye blinking, "right" means eye blinking
        willSet(newValue){
            if newValue != self.eyeBlinking {
                DispatchQueue.main.async {
                    self.faceLable.text = "smile:\(self.isSmile) blinking:\(newValue)"
                }
            }
        }
    }
    // to display if smile or blinking detected(which eye)
    @IBOutlet weak var faceLable: UILabel!
    
    
    var filters : [CIFilter]! = nil
    @IBOutlet weak var ToggleFlashButton: UIButton!
    @IBOutlet weak var ToggleCameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    }
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }
        
        return applyFiltersToFaces(inputImage: inputImage, features: faces)
    }
    
    //MARK: Setup Face Detection
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,
                                   CIDetectorSmile:true,
                                CIDetectorEyeBlink:true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        //Rotates pixels around a point to simulate a vortex.
        let filterPinch = CIFilter(name:"CIVortexDistortion")!
        filterPinch.setValue(25, forKey: "inputAngle")
        filterPinch.setValue(100, forKey: "inputRadius")
        filters.append(filterPinch)
        
        //Distorts the pixels starting at the circumference of a circle and emanating outward.
        let circleSplashDistortion = CIFilter(name:"CICircleSplashDistortion")!
        circleSplashDistortion.setValue(150, forKey: "inputRadius")
        filters.append(circleSplashDistortion)
        
        //Creates a circular area that pushes the image pixels outward, distorting those pixels closest to the circle the most.
        let holeDistortion = CIFilter(name: "CIHoleDistortion")!
        holeDistortion.setValue(10, forKey: "inputRadius")
        filters.append(holeDistortion)
        
    }
    
    //MARK: Apply filters and apply feature detectors
    // use CIVortexDistortion to filter face, and CIHoleDistortion to highlight eyes and mouth
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        var filterCenter = CGPoint()
        
        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
                        
            let faceFilter = filters[0]
            faceFilter.setValue(retImage, forKey: kCIInputImageKey)
            faceFilter.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
            // could also manipulate the radius of the filter based on face size!
            retImage = faceFilter.outputImage!
            
            //use hole distortion filter
            let eyeFilter = filters[2]
           if f.hasLeftEyePosition {
               print("lab left eye detected")
               eyeFilter.setValue(retImage, forKey: kCIInputImageKey)
               eyeFilter.setValue(CIVector(cgPoint: CGPoint(x:f.leftEyePosition.x,y:f.leftEyePosition.y)), forKey: "inputCenter")
               retImage = eyeFilter.outputImage!
            }

            if f.hasRightEyePosition {
                print("lab right eye detected")
                eyeFilter.setValue(retImage, forKey: kCIInputImageKey)
                eyeFilter.setValue(CIVector(cgPoint: CGPoint(x:f.rightEyePosition.x,y:f.rightEyePosition.y)), forKey: "inputCenter")
                retImage = eyeFilter.outputImage!
            }
            
            // also use hole distortion filter since it is easy to find
            let mouthFilter = filters[2]
            if f.hasMouthPosition {
                print("lab mouth detected")
                mouthFilter.setValue(retImage, forKey: kCIInputImageKey)
                mouthFilter.setValue(CIVector(cgPoint: CGPoint(x:f.mouthPosition.x,y:f.mouthPosition.y)), forKey: "inputCenter")
                retImage = mouthFilter.outputImage!
            }
            
            // if there is a smile on a face
            if f.hasSmile {
                print("lab smile detected")
                self.isSmile = true
            } else {
                self.isSmile = false
            }
            
            if f.rightEyeClosed && !f.leftEyeClosed {// right eye blinking
                self.eyeBlinking = "right"
            } else if f.leftEyeClosed && !f.rightEyeClosed {// left eye blinking
                self.eyeBlinking = "left"
            } else {
                self.eyeBlinking = ""
            }
            
        }
        return retImage
    }
    
    // toggle flash
    // only works when the back camera is working
    @IBAction func toggleFlash(_ sender: Any) {
        _ = self.videoManager.toggleFlash()
    }
    
    // toggle camera
    @IBAction func toggleCamera(_ sender: Any) {
        self.videoManager.toggleCameraPosition()
    }
    
}

