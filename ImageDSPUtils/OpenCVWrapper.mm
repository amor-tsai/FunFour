//
//  OpenCVWrapper.m
//  FunFour
//
//  Created by Amor on 2021/10/26.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import "FFTHelper.h"
#import "PeakFinder.h"
#import <Accelerate/Accelerate.h>

#define fingerCapturedFrameThreshold 30  //To make sure that the finger is detected, 30 frames of consistent finger detected is needed.
#define NUMBER_OF_COLOR_FRAME 600 // the number of average color channel per frame should be stored for analysis
#define REDNESS_THRESHOLD 209// the threshold of redness
#define HUE_THRESHOD 110.0 // the threshold of hue
#define PEAK_COUNT_FOR_USE 5 // use only 5 continuous peaks to detect heart rate

using namespace cv;
using std::vector;

@interface OpenCVWrapper()
@property (nonatomic) cv::Mat image;
@property (strong,nonatomic) CIImage* frameInput;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGAffineTransform inverseTransform;
@property (atomic) cv::CascadeClassifier classifier;
@property (atomic) cv::CascadeClassifier faceClassifier;
@property (atomic) cv::CascadeClassifier eyeClassifier;
@property (atomic) cv::CascadeClassifier mouthClassifier;
@property (nonatomic,readwrite) float* avgRedArray;
@property (nonatomic,readwrite) float* avgRedArrayForGraph;
@property (nonatomic) float* avgBlueArray;
@property (nonatomic) float* avgHueArray;
@property (atomic) NSInteger fingerDetectedCounter;
@property (atomic) NSInteger nonFingerDetectedCounter;
@property (nonatomic) BOOL fingerLastFlag;
@property (atomic) FFTHelper *fftHelper;
@property (atomic) PeakFinder *peakFinder;
@property (atomic) NSInteger frameCounter;
@property (atomic) NSInteger graphCounter;
@property (nonatomic) float heartRate;
//@property (nonatomic) NSMutableArray *fingerRedness;
@end


@implementation OpenCVWrapper
@synthesize fingerNowFlag;

#pragma mark ===Write Your Code Here===
// alternatively you can subclass this class and override the process image function


#pragma mark Define Custom Functions Here

// using Haar Cascade to detect face, eyes, mouth
//MARK: this function is used to detect faces, eyes and mouth using haar cascade classifier and to highlight these objects' positions.
//To detect smile, there is a haar cascade classifier of smile.
//To detect blink, it needs to detect at least two frames, the first one has two eyes and the second one has zero eyes.
-(void)processFaceWithHaarCascade{
    cv::Mat image_copy;
    cvtColor(_image, image_copy, CV_BGRA2GRAY);
    vector<cv::Rect> objectsOfFaces;
    vector<cv::Rect> objectsOfEyes;
    vector<cv::Rect> objectsOfMouths;
    
    // face detection and highlight
    self.faceClassifier.detectMultiScale(image_copy, objectsOfFaces);
    // display bounding rectangles around the detected objects
    NSLog(@"lab4 number of faces detected: %ld",objectsOfFaces.size());
    // if there is at least one face detected
    if (objectsOfFaces.size() > 0) {
        for (size_t i=0;i<objectsOfFaces.size();i++) {
            
            //highlight the face detected with rectangle
            cv::rectangle(_image, cvPoint(objectsOfFaces[i].x, objectsOfFaces[i].y), cvPoint(objectsOfFaces[i].x + objectsOfFaces[i].width, objectsOfFaces[i].y + objectsOfFaces[i].height), Scalar(0,0,255,255));
            
            // eye detection should be in face area, otherwise there will be eyes detected outside some faces area
            self.eyeClassifier.detectMultiScale(image_copy(objectsOfFaces[i]), objectsOfEyes);
            NSLog(@"lab4 number of eyes detected: %ld",objectsOfEyes.size());
            // display bounding rectangles around the detected objects
            if (objectsOfEyes.size() > 0){
                for (size_t j=0;j<objectsOfEyes.size();j++){
                    // highlight the eyes detected
                    cv::rectangle(_image, cvPoint(objectsOfFaces[i].x+objectsOfEyes[i].x, objectsOfFaces[i].y+objectsOfEyes[i].y), cvPoint(objectsOfFaces[i].x+objectsOfEyes[i].x + objectsOfEyes[i].width, objectsOfFaces[i].y+objectsOfEyes[i].y + objectsOfEyes[i].height), Scalar(0,255,0,0));
                }
            }

            // mouth detection should be in the face area, otherwise there will be mouths detected outside the faces area
            self.mouthClassifier.detectMultiScale(image_copy(objectsOfFaces[i]), objectsOfMouths);
            NSLog(@"lab4 number of mouths detected: %ld",objectsOfMouths.size());
            if (objectsOfMouths.size() > 0){
                for (size_t k=0;k<objectsOfMouths.size();k++){
                    cv::rectangle(_image, cvPoint(objectsOfFaces[i].x+objectsOfMouths[i].x, objectsOfFaces[i].y+objectsOfMouths[i].y), cvPoint(objectsOfFaces[i].x+objectsOfMouths[i].x + objectsOfMouths[i].width, objectsOfFaces[i].y+objectsOfMouths[i].y + objectsOfMouths[i].height), Scalar(0,0,255,255));
                }
            }
            
        }
        
//        for( vector<cv::Rect>::const_iterator r = objectsOfFaces.begin(); r != objectsOfFaces.end(); r++)
//        {
//            //highlight
//            cv::rectangle( _image, cvPoint( r->x, r->y ), cvPoint( r->x + r->width, r->y + r->height ), Scalar(0,0,255,255));
//        }
        
//        // eye detection and hightlight
//        self.eyeClassifier.detectMultiScale(image_copy, objectsOfEyes);
//        NSLog(@"lab4 number of eyes detected: %ld",objectsOfEyes.size());
//        // display bounding rectangles around the detected objects
//        for( vector<cv::Rect>::const_iterator r = objectsOfEyes.begin(); r != objectsOfEyes.end(); r++)
//        {
//            //highlight the eyes detected with green color rectangle
//            cv::rectangle( _image, cvPoint( r->x, r->y ), cvPoint( r->x + r->width, r->y + r->height ), Scalar(0,255,0,0));
//        }
//
//        // mouth detection and hightlight
//        self.mouthClassifier.detectMultiScale(image_copy, objectsOfMouths);
//        // display bounding rectangles around the detected objects
//        NSLog(@"lab4 number of mouths detected: %ld",objectsOfMouths.size());
//        for( vector<cv::Rect>::const_iterator r = objectsOfMouths.begin(); r != objectsOfMouths.end(); r++)
//        {
//            cv::rectangle( _image, cvPoint( r->x, r->y ), cvPoint( r->x + r->width, r->y + r->height ), Scalar(0,0,255,255));
//        }
        
    }
    
    

}

// use CoreImage to process face detection and highlight
//MARK: this function is not completed because I don't fix the problem of coordinates transformation to make rectanges at the right position.
-(void)processFace:(NSArray *)multipleFaces{
    cv::Mat image_copy;
    
//    cvtColor(_image, image_copy, CV_BGRA2GRAY);
    
    for (CIFaceFeature* face in multipleFaces) {
                
        CGRect faceBounds = CGRectApplyAffineTransform(face.bounds, self.transform);
        CIImage *faceImage = [_frameInput imageByCroppingToRect:faceBounds];
        
        cv::rectangle(_image,cvPoint(faceImage.extent.origin.x, faceImage.extent.origin.y),cvPoint(faceImage.extent.origin.x + faceImage.extent.size.width, faceImage.extent.origin.y + faceImage.extent.size.height), Scalar(0,0,255,255));

        
        // There is a different coordinate system between CoreImage and OpenGL
//        CGRect faceBounds = CGRectApplyAffineTransform(face.bounds, CGAffineTransformMakeScale(1, -1));
        
        // because the image we got is clockwise 90 degree transform, we have to transform our coordinates.
//        CGRect faceBounds = face.bounds;
//        CGFloat temp = faceBounds.size.width;
//        faceBounds.size.width = faceBounds.size.height;
//        faceBounds.size.height = temp;
//
//        temp = faceBounds.origin.x;
//        faceBounds.origin.x = face.bounds.origin.y;
//        faceBounds.origin.y = temp;
        
        // there is a mouth position in face detected
        if (face.hasMouthPosition) {
            
        }
        
        // there is a left eye position in face detected
        if (face.hasLeftEyePosition) {
            
        }
        
        // there is a right eye position in face detected
        if (face.hasRightEyePosition) {
//            cv::rectangle(_image, cvPoint(face.rightEyePosition.x, face.rightEyePosition.y),cvPoint(face.rightEyePosition.y+0.1, face.rightEyePosition.y+0.1), Scalar(0,0,255,255));
        }
        
        // there is a smile on the face
        if (face.hasSmile) {
            
        }
        
        if (face.leftEyeClosed && !face.rightEyeClosed) {
            //right eye blinking
        }
        
        if (!face.leftEyeClosed && face.rightEyeClosed) {
            //left eye blinking
        }
        
        if (face.leftEyeClosed && face.rightEyeClosed) {
            //eyes blinking
            
        }
        
//        cv::rectangle(_image,cvPoint(faceBounds.origin.x - faceBounds.size.width/2, faceBounds.origin.y - faceBounds.size.height/2),cvPoint(faceBounds.origin.x + faceBounds.size.width/2, faceBounds.origin.y + faceBounds.size.height/2), Scalar(0,0,255,255));
        
//        cv::rectangle(_image,cvPoint(faceBounds.origin.x + faceBounds.size.width, faceBounds.origin.y + faceBounds.size.height),cvPoint(faceBounds.origin.x, faceBounds.origin.y), Scalar(0,0,255,255));
        
        NSLog(@"lab x:%f y:%f width:%f height:%f",faceBounds.origin.x,faceBounds.origin.y,faceBounds.size.width,faceBounds.size.height);
        
    }
    
    
    
    
}

//MARK: use each frame of video to process finger detection and heart rate detection from average redness from finger picture
-(bool)processFinger{
    cv::Mat image_copy;
    char text[50]; // to print average color of BGR channel
    Scalar avgPixelIntensity;
    
    // get average value of redness, blueness and greenness
    cvtColor(_image, image_copy, CV_BGRA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    sprintf(text,"Avg. B: %.1f, G: %.1f, R: %.1f", avgPixelIntensity.val[2],avgPixelIntensity.val[1],avgPixelIntensity.val[0]);
    cv::putText(_image, text, cv::Point(30, 50), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    
    cvtColor(image_copy, image_copy, CV_BGR2HSV);
    Scalar avgIntensityHSV;
    avgIntensityHSV = cv::mean( image_copy );
    char textHSV[50];
    
    sprintf(textHSV, "Avg. H: %.1f, S: %.1f, V: %.1f",avgIntensityHSV.val[0],avgIntensityHSV.val[1],avgIntensityHSV.val[2]);
    cv::putText(_image, textHSV,cv::Point(30, 70), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    
    // I tried many times and decided to use HSV color because it could provide more consistent result rather than BGR
    // hue error should be between 115 and 125 and saturation should be between 248 and 258
    if (fabs(avgIntensityHSV.val[0] - 120) <= 5.0 && fabs(avgIntensityHSV.val[1] - 253) <= 5.0) {
        
        self.nonFingerDetectedCounter = 0; // reset non-finger detected counter because the finger is captured
        
        if (self.fingerLastFlag) {// consistently capturing the finger
            self.fingerDetectedCounter += 1;
        }else {
            self.fingerDetectedCounter = 1;
        }
        
        if (self.fingerDetectedCounter >= fingerCapturedFrameThreshold) {
            self.fingerNowFlag = true; // if continuous 30 frames are fingers then set true
        }
        
        // if finger is detected, then begin to detect heart rate
        
        //MARK: since the first serveral frames would record the redness without torch on, which is not what we want, so I add a threshold
        // If the finger is detected on the screen
        if (self.fingerNowFlag && avgPixelIntensity.val[0] > REDNESS_THRESHOLD) {
            // store each frame of average RGB color channel
            self.avgRedArray[self.frameCounter] = (float)avgPixelIntensity.val[0];
            self.avgRedArrayForGraph[self.frameCounter] = (float)avgPixelIntensity.val[0];
            self.avgBlueArray[self.frameCounter] = (float)avgPixelIntensity.val[2];
            self.avgHueArray[self.frameCounter] = (float)avgIntensityHSV[0];
            
//            if (self.frameCounter >= NUMBER_OF_COLOR_FRAME) {
//                self.frameCounter = 0;
            if (self.frameCounter == NUMBER_OF_COLOR_FRAME-1) {
                // use average color array to detect heart rate
//                float *rednessFFT;
//                [self.fftHelper performForwardFFTWithData:self.avgRedArray andCopydBMagnitudeToBuffer:rednessFFT];
                
                NSLog(@"lab heart rate begin redness");
                
                // let's normalize the avgRedArray
                float *normalizationAvgRedness = (float*)calloc(NUMBER_OF_COLOR_FRAME, sizeof(float));

                float mean = 0.0f;
                float sddev = 0.0f;
                vDSP_normalize(self.avgRedArray, 1, normalizationAvgRedness, 1, &mean, &sddev, vDSP_Length(NUMBER_OF_COLOR_FRAME));
                
                NSArray *redness = [self.peakFinder getFundamentalPeaksFromBuffer:self.avgRedArray withLength:NUMBER_OF_COLOR_FRAME usingWindowSize:7 andPeakMagnitudeMinimum:0.0 aboveFrequency:0 belowFrequency:0];
                
//                for (NSInteger i=0;i<NUMBER_OF_COLOR_FRAME;i++) {
//                    NSLog(@"lab average redness: %.6f",normalizationAvgRedness[i]);
//                }
                
                NSInteger peakCount = [redness count];
                for (Peak *object in redness) {
                    NSLog(@"lab index %lu magnitude %1.f",(unsigned long)object.index,object.magnitude);
                }
                
//                NSLog(@"lab heart rate begin hueness");
//                NSArray *hueness = [self.peakFinder getFundamentalPeaksFromBuffer:self.avgHueArray withLength:NUMBER_OF_COLOR_FRAME usingWindowSize:10 andPeakMagnitudeMinimum:0.1 aboveFrequency:0 belowFrequency:0];
//                for (Peak *object in hueness) {
//                    NSLog(@"lab index %d magnitude %1.f",object.index,object.magnitude);
//                }
                
                //MARK: I use last 4 continuous peaks to calculate, skipping the very last one. I have manipulated the getFundamentalPeaksFromBuffer function to get sorted index, which means the very end peak would be the first element
                if (peakCount > PEAK_COUNT_FOR_USE+2) {
                    Peak *firstPeak = [redness objectAtIndex:2];
                    Peak *lastPeak = [redness objectAtIndex:PEAK_COUNT_FOR_USE];
                    if (firstPeak && lastPeak) {
//                        NSLog(@"lab first peak index:%d frequency:%0.f",firstPeak.index,firstPeak.frequency);
//                        NSLog(@"lab last peak index:%d frequency:%0.f",lastPeak.index,lastPeak.frequency);
//                        NSLog(@"lab peak count:%d",peakCount);
                        float heartRate = PEAK_COUNT_FOR_USE*60*30/(firstPeak.index - lastPeak.index);
                        if (heartRate >= 40 && heartRate <= 180) {//if the heart rate range is fine.
                            self.heartRate = heartRate;
                        }
                        NSLog(@"lab heart rate: %.0f",heartRate);
                    }
                }
            }
            
            self.frameCounter += 1;
            if (self.frameCounter >= NUMBER_OF_COLOR_FRAME) {
                self.frameCounter = 0;
            }
            
            char textHeartRate[50];
            if (self.heartRate > 0) {
                sprintf(textHeartRate,"heart rate %0.f", self.heartRate);
                cv::putText(_image, textHeartRate,cv::Point(30, 90), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
            } else {
                sprintf(textHeartRate,"hear rate detecting...");
                cv::putText(_image, textHeartRate,cv::Point(30, 90), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
            }

        }
        
        self.fingerLastFlag = true;
        return true;
    } else {
        
        if (!self.fingerLastFlag) {// consistently capturing the non-finger
            self.nonFingerDetectedCounter += 1;
        }
        
        if (self.nonFingerDetectedCounter >= fingerCapturedFrameThreshold) {// consistently capturing non-finger for 30 frames
            self.fingerNowFlag = false;
            self.heartRate = 0;
            self.frameCounter = 0;
        }
        
        self.fingerLastFlag = false;
    }
    return false;
}


#pragma mark ====Do Not Manipulate Code below this line!====
-(void)setTransforms:(CGAffineTransform)trans{
    self.inverseTransform = trans;
    self.transform = CGAffineTransformInvert(trans);
}

-(void)loadHaarCascadeWithFilename:(NSString*)filename{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    self.classifier = cv::CascadeClassifier([filePath UTF8String]);
}

//
-(void)loadHaarCascadeWithFilename:(NSString *)filename
    classifierName:(NSString *)classifierName{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    cv::CascadeClassifier classifier = cv::CascadeClassifier([filePath UTF8String]);
    
    if ([classifierName  isEqual: @"face"]) {
        self.faceClassifier = classifier;
    } else if ([classifierName  isEqual: @"eye"]) {
        self.eyeClassifier = classifier;
    } else if ([classifierName isEqual: @"mouth"]) {
        self.mouthClassifier = classifier;
    }
}

// get haar cascade classifier with filename
-(cv::CascadeClassifier)getHaarCascadeClassifierWithFilename:(NSString*)filename{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    return cv::CascadeClassifier([filePath UTF8String]);
}

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.transform = CGAffineTransformScale(self.transform, -1.0, 1.0);
        
        self.inverseTransform = CGAffineTransformMakeScale(-1.0,1.0);
        self.inverseTransform = CGAffineTransformRotate(self.inverseTransform, -M_PI_2);
        
        self.fingerDetectedCounter = 0;
        self.nonFingerDetectedCounter = 0;
        self.frameCounter = 0;
        self.graphCounter = 0;
        
        self.avgRedArray = (float*)calloc(NUMBER_OF_COLOR_FRAME, sizeof(float));
        self.avgRedArrayForGraph = (float*)calloc(NUMBER_OF_COLOR_FRAME, sizeof(float));
        self.avgBlueArray = (float*)calloc(NUMBER_OF_COLOR_FRAME, sizeof(float));
        self.avgHueArray = (float*)calloc(NUMBER_OF_COLOR_FRAME, sizeof(float));
        
        self.fingerLastFlag = false;
        self.fingerNowFlag = false;
        
        self.heartRate = 0.0;
        
        self.fftHelper = [[FFTHelper alloc] initWithFFTSize:NUMBER_OF_COLOR_FRAME/2];
        self.peakFinder = [[PeakFinder alloc] initWithFrequencyResolution:7];
        
    }
    return self;
}

#pragma mark Bridging OpenCV/CI Functions
// code manipulated from
// http://stackoverflow.com/questions/30867351/best-way-to-create-a-mat-from-a-ciimage
// http://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c


-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)faceRectIn
      andContext:(CIContext*)context{
    
    CGRect faceRect = CGRect(faceRectIn);
    faceRect = CGRectApplyAffineTransform(faceRect, self.transform);
    ciFrameImage = [ciFrameImage imageByApplyingTransform:self.transform];
    
    
    //get face bounds and copy over smaller face image as CIImage
    //CGRect faceRect = faceFeature.bounds;
    _frameInput = ciFrameImage; // save this for later
    _bounds = faceRect;
    CIImage *faceImage = [ciFrameImage imageByCroppingToRect:faceRect];
    CGImageRef faceImageCG = [context createCGImage:faceImage fromRect:faceRect];
    
    // setup the OPenCV mat fro copying into
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(faceImageCG);
    CGFloat cols = faceRect.size.width;
    CGFloat rows = faceRect.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    _image = cvMat;
    
    // setup the copy buffer (to copy from the GPU)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                      // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), faceImageCG);
    
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(faceImageCG);
    
}

-(CIImage*)getImage{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return retImage;
}

-(CIImage*)getImageComposite{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    // now apply transforms to get what the original image would be inside the Core Image frame
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    CIFilter* filt = [CIFilter filterWithName:@"CISourceAtopCompositing"
                          withInputParameters:@{@"inputImage":retImage,@"inputBackgroundImage":self.frameInput}];
    retImage = filt.outputImage;
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    return retImage;
}

@end
