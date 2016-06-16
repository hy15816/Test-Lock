//
//  CupboardViewController.m
//  Test-Lock
//
//  Created by Lost_souls on 16/6/6.
//  Copyright © 2016年 __lost_souls. All rights reserved.
//



#import "CupboardViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "LSCheckVersionView.h"

static NSString *const kSTRING_UUID_CBCHAR     = @"00002902-0000-1000-8000-00805f9b34fb";
static NSString *const kSTRING_UUID_SERVICE    = @"00001000-0000-1000-8000-00805f9b34fb";
static NSString *const kSTRING_UUID_W_CHAR     = @"00001001-0000-1000-8000-00805f9b34fb";
static NSString *const kSTRING_UUID_R_CHAR     = @"00001002-0000-1000-8000-00805f9b34fb";


@interface CupboardViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>


@property (strong, nonatomic) IBOutlet UIButton *start;
- (IBAction)stop:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)start:(id)sender;

@property (strong,nonatomic) CBCentralManager *centralManager;
@property (strong,nonatomic) CBCharacteristic *cbCharacteristic;
@property (strong,nonatomic) CBPeripheral *cbPeripheral;

@property (strong,nonatomic) LSCheckVersionView *check;
@end

@implementation CupboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@".....%@",[[UIDevice currentDevice] identifierForVendor].UUIDString);
    
    [self initCentralManager];
    
    
}

- (void)initCentralManager {
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"....connect ");
    
   
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.cbPeripheral discoverServices:nil];
    });
    
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    //    if (error) {
    //        NSLog(@"did Disconnect error:%@",error);
    //    }
    self.cbPeripheral = nil;
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if (!error) {
        for (CBService *cbser in peripheral.services) {
                        NSLog(@"UUIDString:%@",cbser.UUID.UUIDString);
            
                //                NSLog(@"isEqual");
                [self.cbPeripheral discoverCharacteristics:nil forService:cbser];
            
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (!error) {
        for (CBCharacteristic *cbchc in service.characteristics) {
            NSLog(@"chc:%@",cbchc);

//                        NSLog(@"chc.string:%@",cbchc.UUID.UUIDString);
            if ([cbchc.UUID.UUIDString isEqualToString:@"1003"]) {
                self.cbCharacteristic = cbchc;
                
            }
//            [self.cbPeripheral readValueForCharacteristic:cbchc];
            [self.cbPeripheral setNotifyValue:YES forCharacteristic:cbchc];
        }
    }else {
        NSLog(@"discover chc error:%@",error);
    }
    
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSString *name = advertisementData[CBAdvertisementDataLocalNameKey];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"p.name:<%@> adv.name:(%@)",peripheral.name,name);
    
    if ([name isEqualToString:@"BLE#0x44A6E503A76A"]) {
        self.cbPeripheral = peripheral;
        self.cbPeripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
        [self.centralManager stopScan];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
        if (!error) {
    [self result:characteristic.value index:1];
        }else {
            NSLog(@"error-1:%@",error);
        }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (!error) {
        [self result:characteristic.value index:2];
        
    }else {
            NSLog(@"error-2:%@",error);
    }
    
}

- (void)result:(NSData *)value index:(int)a{
    
    NSLog(@"value - %d:%@",a,value);
    UInt8 xval[20];
    NSInteger getlenth=[value length];
    [value getBytes:&xval length:getlenth];
    
    NSMutableString *dataString=[NSMutableString string];
    for(int i=0; i<getlenth; i++) [dataString appendFormat:@"%02x",xval[i]];
    NSLog(@"dataString: %@",dataString);
    
    NSString *resultString = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    NSLog(@"resulestring: %@",resultString);
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)stop:(id)sender {
    
    [self.centralManager stopScan];
}

- (IBAction)open:(id)sender {
    
    NSString *zeroString = @"0000000000";
    NSString *cnumber = @"0001";
    NSString *dcode = @"12345678";
    NSInteger boxIndex = 2;
    
    if (cnumber.length < 4) {
        cnumber = [NSString stringWithFormat:@"%@%@",cnumber,[zeroString substringToIndex:4-cnumber.length]];
    }
    NSLog(@"cnumber:%@",cnumber);
    NSInteger dcodeBaseLength = 8;
    if (dcode.length < dcodeBaseLength) {
        dcode = [NSString stringWithFormat:@"%@%@",dcode,[zeroString substringToIndex:dcodeBaseLength - dcode.length]];
    }
    NSLog(@"dcode:%@",dcode);
    
    NSInteger len = 14;
    Byte open[len];
    for (int i=0; i<len; i++) {
        open[i] = 0;
    }
    //    open[0] = 0x2B;
    //    open[1] = 0x23;
    open[0] = 0xC5;
    open[1] = len;
    for (int j=0; j<cnumber.length/2; j++) {
        open[2+j] = [[cnumber substringWithRange:NSMakeRange(j*2, 2)] integerValue];
    }
    open[4] = boxIndex;
    for (int k=0; k<dcode.length; k++) {
        NSString *s = [dcode substringWithRange:NSMakeRange(k, 1)];
        if ([self isPureInt:s]) {
            open[5+k] = [s integerValue];
        }else {
            open[5+k] = [[s uppercaseString] characterAtIndex:0];
        }
        
    }
    
    for (int n = 0;  n<len-1; n++) {
        open[len-1] =  open[len-1]^open[n];
    }
    
    //    int l = 1;
    //    Byte noti[l];
    //    for (int q=0; q<l; q++) {
    //        noti[q] = 1;
    //    }
    
    NSData *data = [NSData dataWithBytes:open length:sizeof(open)];
    
    NSLog(@"data:%@",data);
    if (self.cbPeripheral == nil || self.cbCharacteristic == nil) {
        NSLog(@"_cbPeripheral == nil || self.cbCharacteristic == nil");
        return;
    }
    [self.cbPeripheral writeValue:data forCharacteristic:self.cbCharacteristic type:CBCharacteristicWriteWithoutResponse];
    [self.cbPeripheral setNotifyValue:YES forCharacteristic:self.cbCharacteristic];
    [self.cbPeripheral readValueForCharacteristic:self.cbCharacteristic];
    
}

- (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}

- (IBAction)start:(id)sender {
    
//    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    
    [self.check showCheckView:^(NSInteger index) {
        //
        NSLog(@"index:%ld",(long)index);
        if (index == 2) {
            [self.check dismissCheckView];
        }
    }];
    
}


- (LSCheckVersionView *)check{
    
    if (!_check) {
        
//        _check = [[LSCheckVersionView alloc] initWithImage:[UIImage imageNamed:@"icon_no_wlan"] title:@"喜欢新版XXX吗?" subTitle:@"告诉我们你的想法吧!" item:@"喜欢,去评分",@"不喜欢,去吐槽",@"下次再说", nil];
        _check = [[LSCheckVersionView alloc] initWithImage:[UIImage imageNamed:@"icon_no_wlan"] msg:@"lost-souls你个大傻瓜!" cancel:@"我再想想" sure:@"确定" vc:self selectedIndex:^(NSInteger index) {
            NSLog(@"index:%ld",(long)index);
        }];
    }
    return _check;
}
    
@end
