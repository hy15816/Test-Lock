//
//  ViewController.m
//  Test-Lock
//
//  Created by Lost_souls on 16/4/26.
//  Copyright © 2016年 __lost_souls. All rights reserved.
//

static int kIntervalTime = 7;

#define kCbChc  @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define kCbSer  @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
- (IBAction)click:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonWidthConstraint;
@property (strong, nonatomic) IBOutlet UILabel *showTipsLabel;
@property (strong, nonatomic) IBOutlet UILabel *showTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *showEndTimeLabel;

- (IBAction)resetItem:(UIBarButtonItem *)sender;
- (IBAction)stopItem:(UIBarButtonItem *)sender;

@property (strong,nonatomic) CBCentralManager *centralManager;
@property (strong,nonatomic) CBCharacteristic *cbCharacteristic;
@property (strong,nonatomic) CBPeripheral *cbPeripheral;
@property (assign,nonatomic) BOOL isSuc;
@property (assign,nonatomic) int totalConut;
@property (assign,nonatomic) int sucCount;
@property (assign,nonatomic) int failCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initCentralManager];
    
    [self addObserver:self forKeyPath:@"cbPeripheral" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    
    
}

- (void)initCentralManager {
    
    [self initData];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    
}

- (void)initData {
    
    self.totalConut = 0;
    self.sucCount = 0;
    self.failCount = 0;
    self.showTipsLabel.text = nil;
    self.showTimeLabel.text = nil;
    self.showEndTimeLabel.text = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.buttonWidthConstraint.constant = self.view.frame.size.width /3.f;
    self.button.layer.cornerRadius = self.buttonWidthConstraint.constant *0.5;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    NSLog(@"....connect ");
    
    self.isSuc = NO;
    [self.cbPeripheral discoverServices:@[[CBUUID UUIDWithString:kCbSer]]];
    
    [self performSelector:@selector(vc_timeout) withObject:nil afterDelay:2];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
//    if (error) {
//        NSLog(@"did Disconnect error:%@",error);
//    }
    self.cbPeripheral = nil;
    
}

/**
 *  2秒超时
 */
- (void)vc_timeout {
    if (self.isSuc == NO) { //if 不成功  fail + 1
        self.failCount++;
        [self performSelector:@selector(startScan) withObject:nil afterDelay:kIntervalTime -2];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (!error) {
        for (CBService *cbser in peripheral.services) {
//            NSLog(@"UUIDString:%@",cbser.UUID.UUIDString);
            if ([cbser.UUID.UUIDString isEqualToString:kCbSer]) {
//                NSLog(@"isEqual");
                [self.cbPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCbChc]] forService:cbser];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (!error) {
        for (CBCharacteristic *cbchc in service.characteristics) {
//            NSLog(@"chc.string:%@",cbchc.UUID.UUIDString);
            if ([cbchc.UUID.UUIDString isEqualToString:kCbChc]) {
                self.cbCharacteristic = cbchc;
                [self send];
            }
            [self.cbPeripheral setNotifyValue:YES forCharacteristic:cbchc];
        }
    }else {
        NSLog(@"discover chc error:%@",error);
    }
    
}

- (void)send {
    
    NSString *string =  @"1122334455185656679650";
    Byte send[17];
    for (int i=0; i<17; i++) {
        send[i] = 0;
    }
    send[0] = 0xa1;
    send[1] = 0xf0;
    send[2] = 0x0e;
    for (int j=0; j<string.length/2; j++) {
        NSString *s = [string substringWithRange:NSMakeRange(j, 2)];
        send[j+3] = s.integerValue;
    }
    
    for(int i= 0;  i<16; i++) send[16] =  send[16]^send[i];
    
    NSData *d=[NSData dataWithBytes:&send length:sizeof(send)];
    
    [self.cbPeripheral writeValue:d forCharacteristic:self.cbCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSString *name = advertisementData[CBAdvertisementDataLocalNameKey];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"name:%@<",name);
    
    if ([name isEqualToString:@"AEFREADER"]) {
        self.cbPeripheral = peripheral;
        self.cbPeripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
        [self.centralManager stopScan];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    
//    if (!error) {
        [self result:characteristic.value index:1];
//    }else {
//        NSLog(@"error-1:%@",error);
//    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
//    if (!error) {
        [self result:characteristic.value index:2];
//    }else {
//        NSLog(@"error-2:%@",error);
//    }
    
}

- (void)result:(NSData *)value index:(int)a{
    
    self.isSuc = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(vc_timeout) object:nil];
    NSLog(@"value - %d:%@",a,value);
    self.sucCount++;
    [self setTips];
    [self.centralManager cancelPeripheralConnection:self.cbPeripheral];
    self.cbPeripheral = nil;
    
//        [self performSelector:@selector(abcsdsd) withObject:nil afterDelay:2];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kIntervalTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startScan];
    });
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nullResponse) object:nil];
    [self performSelector:@selector(nullResponse) withObject:nil afterDelay:20];
    
}

/**
 *  10 秒 还没有数据返回，说明蓝牙无响应
 */
- (void)nullResponse {
    
    self.showEndTimeLabel.text = [NSString stringWithFormat:@"end   time : %@",[self stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)click:(UIButton *)sender {
    
    self.showTimeLabel.text = [NSString stringWithFormat:@"start time : %@",[self stringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
    
    [self startScan];
    
}

- (void) startScan {
    
    [self.centralManager stopScan];
    self.totalConut ++;
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kCbSer]] options:nil];
    [self setTips];
}

- (void)setTips {
    
    self.showTipsLabel.text = [NSString stringWithFormat:@"total:%d\nsuc:%d\nfail:%d",self.totalConut,self.sucCount,self.failCount];
    
}

- (NSString *)stringWithFormat:(NSString *)format{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:format];
    NSString *destString = [formatter stringFromDate:date];
    return destString;
}

- (IBAction)resetItem:(UIBarButtonItem *)sender {
    
    [self initData];
    
}

- (IBAction)stopItem:(UIBarButtonItem *)sender {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(vc_timeout) object:nil];
    
    [self nullResponse];
    [self.centralManager stopScan];
    
}
@end
