//
//  SecondViewController.swift
//  FunFour
//
//  Created by Amor on 2021/10/27.
//

import Foundation
import UIKit
import AVFoundation
import Metal

class SecondViewController:UIViewController{
        
    struct videoConstants {
        static let frame_threshod = 600
    }
    
    //MARK: Class Properties
    var videoManager:VideoAnalgesic! = nil
    let wrapper = OpenCVWrapper()
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    var isFingerDetected = false{
        willSet(newValue){
            guard isFingerDetected != newValue else {
                return
            }
            _ = self.videoManager.toggleFlash(flashSwitch: newValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
                
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setFPS(desiredFrameRate: 30.0)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        graph?.addGraph(withName: "redness", shouldNormalize: false, numPointsInGraph: videoConstants.frame_threshod)
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.5, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        
            
    }
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        var retImage = inputImage
        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        self.wrapper.setTransforms(self.videoManager.transform)
        self.wrapper.setImage(retImage,
                              withBounds: retImage.extent, //
                             andContext: self.videoManager.getCIContext())
        
        _ = self.wrapper.processFinger()
        self.isFingerDetected = self.wrapper.fingerNowFlag
        
        retImage = self.wrapper.getImage() // get back opencv processed part of the image (overlayed on original)
        
        return retImage
    }
    
    // periodically, update the graph with refreshed FFT Data
    @objc
    func updateGraph(){
        // MARK: I don't know how to conver a c float pointer type to swift float array, so I just use a trick to add zero value so I get a swift float array
        let tmp:[Float] = Array(repeating: 0.0, count: videoConstants.frame_threshod)
        var data:[Float] = Array(repeating: 0.0, count: videoConstants.frame_threshod)
        vDSP_vadd(self.wrapper.avgRedArrayForGraph, 1, tmp, 1, &data, 1, vDSP_Length(videoConstants.frame_threshod))
        self.graph?.updateGraph(
            data: data,
            forKey: "redness"
        )
    }
}

