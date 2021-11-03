//
//  OpenCVWrapper.h
//  FunFour
//
//  Created by Amor on 2021/10/26.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

#import "PrefixHeader.pch"

@interface OpenCVWrapper : NSObject

@property (nonatomic) NSInteger processType;
@property (nonatomic) BOOL fingerNowFlag;
@property (nonatomic,readonly) float *avgRedArray;
@property (nonatomic,readonly) float *avgRedArrayForGraph;


// set the image for processing later
-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)rect
      andContext:(CIContext*)context;

//get the image raw opencv
-(CIImage*)getImage;

//get the image inside the original bounds
-(CIImage*)getImageComposite;

// call this to perform processing vision regarding finger
-(bool)processFinger;

// call this to perform highlighting face, mouth and eye in vision
-(void)processFace:(NSArray *)multipleFaces;

// use haar cascade classifier to process face detection
-(void)processFaceWithHaarCascade;

// for the video manager transformations
-(void)setTransforms:(CGAffineTransform)trans;

-(void)loadHaarCascadeWithFilename:(NSString*)filename;

// load haar cascade classifier with filename and classifier type(such as face,eye,mouth)
-(void)loadHaarCascadeWithFilename:(NSString *)filename
                    classifierName:(NSString *)classifierName;

@end
