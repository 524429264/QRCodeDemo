//
//  QRView.m
//  QRCodeDemo
//
//  Created by NationSky on 16/2/24.
//  Copyright © 2016年 nsky. All rights reserved.
//

#import "QRView.h"
#import <AVFoundation/AVFoundation.h>

@interface QRView ()<AVCaptureMetadataOutputObjectsDelegate>

@end
@implementation QRView
{
    AVCaptureSession *_session;
    UIImageView *_scanView;
    UIImageView *_lineView;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initView];
    }
    return self;
}

- (void)initView
{
    UIImage *scanImage = [UIImage imageNamed:@"scanscanBg"];
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    CGFloat scanW = 200;
    CGRect scanFrame = CGRectMake(width/2.-100, height/2.-100, scanW, scanW);
    _scanViewFrame = scanFrame;
    
    
    _scanView = [[UIImageView alloc]initWithImage:scanImage];
    _scanView.backgroundColor = [UIColor clearColor];
    _scanView.frame = scanFrame;
    [self addSubview:_scanView];
    
    
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //闪光灯
    if ([device hasFlash] && [device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setFlashMode:AVCaptureFlashModeAuto];
        [device setTorchMode:AVCaptureTorchModeAuto];
        [device unlockForConfiguration];
    }
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 刷新线程
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    output.rectOfInterest = [self rectOfInterestByScanViewRect:_scanView.frame];
    //初始化连接对象
    _session = [[AVCaptureSession alloc]init];
    
    //采集率
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    if (input) {
        [_session addInput:input];
    }
    
    if (output) {
        [_session addOutput:output];
        //设置扫码支持的编码格式
        
        NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:0];
        
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [array addObject:AVMetadataObjectTypeQRCode];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
            [array addObject:AVMetadataObjectTypeEAN13Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
            [array addObject:AVMetadataObjectTypeEAN8Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
            [array addObject:AVMetadataObjectTypeCode128Code];
        }
        output.metadataObjectTypes = array;
        
    }
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.bounds;
    [self.layer insertSublayer:layer above:0];
    [self bringSubviewToFront:_scanView];
    [self setOverView];
    [_session startRunning];
    [self loopDrawLine];
    
    
}

- (CGRect)rectOfInterestByScanViewRect:(CGRect)rect{
    
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    CGFloat x = (height - CGRectGetHeight(rect))/2/height;
    CGFloat y = (width - CGRectGetWidth(rect))/2/width;
    
    CGFloat w = CGRectGetHeight(rect)/height;
    CGFloat h = CGRectGetWidth(rect)/width;
    
    return CGRectMake(x, y, w, h);
}

#pragma mark - 添加模糊效果
- (void)setOverView
{
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    CGFloat x = CGRectGetMinX(_scanView.frame);
    CGFloat y = CGRectGetMinY(_scanView.frame);
    CGFloat w = CGRectGetWidth(_scanView.frame);
    CGFloat h = CGRectGetHeight(_scanView.frame);
    
    [self creatView:CGRectMake(0, 0, width, y)];
    [self creatView:CGRectMake(0, y + h, width, height - y)];
    [self creatView:CGRectMake(0, y, x, h)];
    [self creatView:CGRectMake(x + w, y, x, h)];
    
}

- (void)creatView:(CGRect)rect{
    CGFloat alpha = 0.5;
    UIView *view = [[UIView alloc]initWithFrame:rect];
    view.backgroundColor = [UIColor grayColor];
    view.alpha = alpha;
    [self addSubview:view];
}

#pragma mark - 动画
- (void)loopDrawLine {
    
    UIImage *lineImage = [UIImage imageNamed:@"scanLine"];
    
    CGFloat x = CGRectGetMinX(_scanView.frame);
    CGFloat y = CGRectGetMinY(_scanView.frame);
    CGFloat w = CGRectGetWidth(_scanView.frame);
    CGFloat h = CGRectGetHeight(_scanView.frame);
    
    CGRect start = CGRectMake(x, y, w, 2);
    CGRect end = CGRectMake(x, y + h - 2, w, 2);
    
    if (!_lineView) {
        _lineView = [[UIImageView alloc]initWithImage:lineImage];
        _lineView.frame = start;
        [self addSubview:_lineView];
    }else{
        _lineView.frame = start;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2 animations:^{
        _lineView.frame = end;
    } completion:^(BOOL finished) {
        [weakSelf loopDrawLine];
    }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count>0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        if ([_delegate respondsToSelector:@selector(qrView:ScanResult:)]) {
            [_delegate qrView:self ScanResult:metadataObject.stringValue];
        }
    }
}

- (void)startScan{
    _lineView.hidden = NO;
    [_session startRunning];
}

- (void)stopScan{
    _lineView.hidden = YES;

    [_session stopRunning];
}

@end
