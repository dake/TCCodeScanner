//
//  TCCodeScannerView.m
//  SudiyiClient
//
//  Created by cdk on 15/5/4.
//  Copyright (c) 2015年 Sudiyi. All rights reserved.
//

#import "TCCodeScannerView.h"


@interface TCCodeScannerView ()

@property(nonatomic,strong,readonly) AVCaptureVideoPreviewLayer *previewLayer;

@end


@implementation TCCodeScannerView
{
    @private
    TCCodeScanner *_scanner;
}

- (void)dealloc
{
    [self stop];
}

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (nil != newWindow) {
        [self updateMetadata];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExpose:)];
        [self addGestureRecognizer:tapRecognizer];
        
        _scannerArea = self.bounds;
        
        [self configureLayer];
    }
    return self;
}



- (TCCodeScanner *)scanner
{
    if (nil == _scanner) {
        _scanner = [[TCCodeScanner alloc] init];
    }
    
    return _scanner;
}

- (void)updateMetadata
{
    // worked after layer did layout
    CGRect rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:self.scannerArea];
    NSAssert(!isnan(rectOfInterest.origin.x), nil);
    self.scanner.metadataOutput.rectOfInterest = rectOfInterest;
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureVideoOrientation)videoOrientation
{
    if ([self.previewLayer.connection isVideoOrientationSupported]) {
        return self.previewLayer.connection.videoOrientation;
    }
    else {
        return 0;
    }
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    if ([self.previewLayer.connection isVideoOrientationSupported]) {
        self.previewLayer.connection.videoOrientation = videoOrientation;
    }
}


- (void)start
{
    [_scanner.session startRunning];
}

- (void)stop
{
    [_scanner.session stopRunning];
}

- (void)configureLayer
{
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.scanner.torchMode = AVCaptureTorchModeAuto;
    self.previewLayer.session = self.scanner.session;
}


#pragma mark -

- (void)focusAndExpose:(UITapGestureRecognizer *)sender
{
    CGPoint location = [self.previewLayer captureDevicePointOfInterestForPoint:[sender locationInView:self]];
    [self.scanner focusAtPoint:location];
    [self.scanner exposeAtPoint:location];
}



@end
