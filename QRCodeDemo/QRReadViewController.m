//
//  ViewController.m
//  QRCodeDemo
//
//  Created by NationSky on 15/12/27.
//  Copyright © 2015年 nsky. All rights reserved.
//

#import "QRReadViewController.h"
#import "QRView.h"
#import "QRCodeController.h"

@interface QRReadViewController ()<QRViewDelegate>

@end

@implementation QRReadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"扫一扫";
    QRView *qrView = [[QRView alloc]initWithFrame:self.view.bounds];
    qrView.delegate = self;
    [self.view addSubview:qrView];
}

//代理回调扫描结果
- (void)qrView:(QRView *)view ScanResult:(NSString *)result
{
    [view stopScan];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"跳转" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:result]];
        [view startScan];
     
    }]];
    NSLog(@"扫描结果:%@",result);
    
    [alert addAction:[UIAlertAction actionWithTitle:@"二维码" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        QRCodeController *qrVC = [[QRCodeController alloc]init];
        qrVC.content = result;
        [self.navigationController pushViewController:qrVC animated:YES];
        
        [view startScan];

    }]];
    [self presentViewController:alert animated:true completion:^{
        
        
    }];
}


#pragma mark - 颜色
//获取颜色
- (UIColor *)colorFromHexRGB:(NSString *)inColorString
{
    UIColor *result = nil;
    unsigned int colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
        NSScanner *scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char) (colorCode >> 16);
    greenByte = (unsigned char) (colorCode >> 8);
    blueByte = (unsigned char) (colorCode); // masks off high bits
    result = [UIColor
              colorWithRed: (float)redByte / 0xff
              green: (float)greenByte/ 0xff
              blue: (float)blueByte / 0xff
              alpha:1.0];
    return result;
}


@end
