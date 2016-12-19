//
//  BlueToothManager.m
//  3Pomelos
//
//  Created by 孟德林 on 2016/11/7.
//  Copyright © 2016年 ichezheng.com. All rights reserved.
//

#import "BlueToothManager.h"
typedef struct _CHAR{
    char buff[1000];
}CHAR_STRUCT;

typedef void(^ConnectBlock)(CBPeripheral *peripheral);

typedef void(^ScanBlock)(NSSet *array);

@interface BlueToothManager()

@property (nonatomic, copy)ConnectBlock connectBlock;
@property (nonatomic, copy)ScanBlock scanBlock;

@end

@implementation BlueToothManager
{
#pragma mark Old蓝牙设备参数
    CBPeripheral      *activePeripheral;
    long              receiveByteSize;   //返回数据的长度
    int               countPKSSize;      //计算收到数据包的次数
    NSMutableString   *receiveSBString;  //接收到的数据
    Boolean           isReceive;         //是否继续接收发过来的数据
    
#pragma mark New蓝牙设备参数
    CBCharacteristic *_bleCharacteristic;   // 写入数据的特征值 0x0A40
    CBCharacteristic *_readCharacteristic;  // 读取数据的特征值 0x0A41
    CBCharacteristic *_writeCharacteristic; // 注册监听通道的特征值 0x0A42
    
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    self.scanBlock = nil;
    self.connectBlock = nil;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initNotification];
        self.deviceCallBack = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)manager
{
    static BlueToothManager *sharedAccountManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}

// 初始化蓝牙中心设备（只需要应用被启动时，被调用一次）
- (void)initializerBLEManager{
    self.bleManager = [[DLMBlueTooth alloc] init];
    [self.bleManager _initializeCenterManager];
    self.bleManager.RSSIValue = kDEFAULT_RSSI_VALUE;
}

#pragma mark ---------- 中心设备操作 -----------
// 开始扫描设备
- (void)startScanDeviceWithBlock:(ScanBlock)block
{
    [self startScanDevice];
    self.scanBlock = block;
}

-(void)startScanDevice
{
    [self stopScan];           //扫描之前先断开已有的连接
    [self scanPeripheral];     //扫描之前清除所有之前的数据
    receiveSBString = [NSMutableString new];
    _startModel = MODEL_NORMAL;//将状态
    self.scanBlock = nil;
    
}

- (void)scanPeripheral {
    if (self.bleManager.currentActivePeripheral)
        if(self.bleManager.currentActivePeripheral.state == CBPeripheralStateConnected)
            [[self.bleManager BLECenterManager] cancelPeripheralConnection:[self.bleManager currentActivePeripheral]];
    [self.bleManager.peripherals removeAllObjects];
    [self.bleManager.currentActiveCharacteristics removeAllObjects];
    [self.bleManager.currentActiveDescriptors removeAllObjects];
    self.bleManager.currentActivePeripheral = nil;
    self.bleManager.currentActiveService = nil;
    /* 定时扫描持续时间10秒，之后打印扫描到的信息 */
    [self.bleManager _scanBLEPeripherals:6];  // 6
}

// 停止扫描
- (void)stopScan
{
    [self.bleManager _stopScan];
}

#pragma mark ---------- 外设操作 ------------
// 连接扫描的指定外设
- (void)connectPeripheralDevice:(CBPeripheral *)peripheral
{
    _currentPeripheral = peripheral;
    self.bleManager.currentActivePeripheral = peripheral;
    [self.bleManager _startConnectPeripheral:peripheral];
}
// 连接到扫描的指定外设   block（）回调
- (void)ConnectWithBlock:(ConnectBlock)block
{
    self.connectBlock = block;
    [self.bleManager _startConnectPeripheral:activePeripheral];
}

//首先RegisterNotification，然后开始接受外设发送的数据（到代理方法 “ReceiveData“接受数据）
- (void)startReceiveData
{
    if (self.currentPeripheral.state == CBPeripheralStateConnected) {
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC);
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [self.bleManager _notification:0xFFE0 characteristicUUID:0xFFE4 peripheral:self.bleManager.currentActivePeripheral isActive:YES];
        });
    }
}

//结束接受数据
- (void)stopReceiveData
{
    [self.bleManager _notification:0xFFE0 characteristicUUID:0xFFE4 peripheral:self.bleManager.currentActivePeripheral isActive:NO];
}

//向外设发送数据（本质为写入中心和外设协议好的格式数据，然后发送）
- (void)sendDataToDevice:(NSString *)data
{
    NSString  *message =nil;
    BOOL IsAscii = YES;
    if (IsAscii) {
        message = data;
    }else{ //将显示十六进制的字符串，转化为ascii码发送
        message = [Tools stringFromHexString:data];
    }
    int        length = (int)message.length;
    Byte       messageByte[length];
    for (int index = 0; index < length; index++) {//生成和字符串长度相同的字节数据
        messageByte[index] = 0x00;
    }
    NSString   *tmpString;                           //转化为ascii码
    for(int index = 0; index<length ; index++)
    {
        tmpString = [message substringWithRange:NSMakeRange(index, 1)];
        if([tmpString isEqualToString:@" "])
        {
            messageByte[index] = 0x20;
        }else{
            if ([tmpString isEqualToString:@"\r"]) {
                messageByte[index] = 0x0d;
            }else if([tmpString isEqualToString:@"\n"]){
                messageByte[index] = 0x0a;
            }else{
                sscanf([tmpString cStringUsingEncoding:NSASCIIStringEncoding],"%s",&messageByte[index]);
            }
        }
        NSLog(@" message tmpString  : %@  end",tmpString);
    }
    NSLog(@" message   : %@  end",message);
    char lengthChar = 0 ;
    int  p = 0 ;
    while (length>0) {   //蓝牙数据通道 可写入的数据为20个字节
        if (length>20) {
            lengthChar = 20 ;
        }else if (length>0){
            lengthChar = length;
        }else
            return;
        NSData *data = [[NSData alloc]initWithBytes:&messageByte[p] length:lengthChar];
        [self.bleManager _writeValue:0xFFE5 characteristicUUID:0xFFE9 peripheral:self.bleManager.currentActivePeripheral data:data];
        length -= lengthChar;
        p += lengthChar;
    }
}

#pragma mark 新版本写入数据
- (void)writeValueForPeripheral:(NSData *)data
{
    [self.bleManager _writeValue:0xA032 characteristicUUID:0xA040 peripheral:self.bleManager.currentActivePeripheral data:data];
    if (self.deviceCallBack.count > 0) {
        [self.deviceCallBack removeAllObjects];
    }
    
}

// 取消外设的连接
- (void)cancelConnect
{
    _currentPeripheral.delegate = nil;
    _currentPeripheral = nil;
    if (self.bleManager.currentActivePeripheral) {
        [self.bleManager.BLECenterManager cancelPeripheralConnection:self.bleManager.currentActivePeripheral];
    }
}

#pragma mark ------------------------------------ 蓝牙状态的通知事件 ---------------------------------------------
-(void)initNotification
{
    //设定通知
    //发现BLE外围设备
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //成功连接到指定外围BLE设备
    [nc addObserver: self
           selector: @selector(didConectedbleDevice:)
               name: DID_CONNECTED_BLEDEVICE
             object: nil];
    
    [nc addObserver: self
           selector: @selector(stopScanBLEDevice)
               name: STOPSCAN
             object: nil];
    
    [nc addObserver: self
           selector: @selector(bleDeviceWithRSSIFound:)
               name: BLE_DEVICE_RSSI_FOUND
             object: nil];
    
    [nc addObserver: self
           selector: @selector(serviceFoundOver:)
               name: SERVICE_FOUND_OVER
             object: nil];
    
    [nc addObserver: self
           selector: @selector(didDiscoverCharacteristFromService)
               name: DOWNLOAD_SERVICE_PROCESS_STEP
             object: nil];
    
    [nc addObserver: self
           selector: @selector(valueUpdate:)
               name: VALUE_CHANG_UPDATE
             object: nil];
    [nc addObserver:self
           selector:@selector(deviceDisconnect:)
               name:DEVICE_ISDISCONNECT
             object:nil];
    [nc addObserver:self
           selector:@selector(writeFinished)
               name:BLE_WRITE_FINISH
             object:nil];
}
/* --------------------------------------------中心的状态通知---------------------------------------------*/

// 扫描到外设 RSSI更新
-(void)bleDeviceWithRSSIFound:(NSNotification *)notification{   //此方法刷新次数过多，会导致tableview界面无法刷新的情况发生
    if (self.scanBlock) {
        self.scanBlock(self.bleManager.peripherals);
    }
    Byte RSSI = -[[notification object] charValue];
    /* 如果设备已经被绑定，那么直接进行扫描，不对RSSI进行限定。如果设备没有被绑定那么进行RSSI限定，
       主要目的是为了在用户没有绑定之前，需要靠近很近的距离才能扫描到，然后才能进行绑定。
     
     限定范围参考:
     1、65 距离在1.2米以内左右, 如果在范围内的话可以进行
     2、根据业务需要进行添加。
     */
    if (self.isBandingDevice == YES) // 已经绑定
    {
        if ([self.delegate respondsToSelector:@selector(didDiscoverPeripheral: canConnect:)])
        {
            [self.delegate didDiscoverPeripheral:self.bleManager.peripherals canConnect:YES];
        }
    }else // 没有绑定
    {
        if (RSSI < 140)
        {
            // 连接范围
            if ([self.delegate respondsToSelector:@selector(didDiscoverPeripheral: canConnect:)])
            {
                [self.delegate didDiscoverPeripheral:self.bleManager.peripherals canConnect:YES];
            }
        }else{
            
            NSLog(@"超出范围了");
        }
    }
}

//结束扫描
-(void)stopScanBLEDevice{
    NSLog(@"BLE外设列表被更新！\r\n");
    if ([self.delegate respondsToSelector:@selector(stopScanBLEThenUpdateDevices)]) {
        [self.delegate stopScanBLEThenUpdateDevices];
    }
}

/* -------------------------------------------外设的状态通知----------------------------------------------*/

//连接成功
-(void)didConectedbleDevice:(CBPeripheral *)peripheral {
    NSLog(@"BLE设备连接成功！\r\n");
    _startModel = MODEL_CONNECTING;
    [self stopScan];
    [self.bleManager.currentActivePeripheral discoverServices:nil];
    if ([self.delegate respondsToSelector:@selector(didConnectPeripheral:)]) {
        [self.delegate didConnectPeripheral:self.currentPeripheral];
    }
}

//发现服务
-(void)serviceFoundOver:(CBPeripheral *)peripheral {
    NSLog(@" 获取所有的服务！\r\n ");
    _startModel = MODEL_SCAN;
}
//服务特征值
-(void)didDiscoverCharacteristFromService{
    _startModel = MODEL_CONECTED;
    NSLog(@"获取所有的特征值! \r\n");
#pragma mark 新版本特征值处理
    for (CBCharacteristic *characteristic in self.bleManager.currentActiveCharacteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0000a040-0000-1000-8000-00805F9B34FB"]]) {
            _bleCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0000a041-0000-1000-8000-00805F9B34FB"]] ) {
            _readCharacteristic = characteristic;
            [self.bleManager _readValue:0xA032 characteristicUUID:0xA041 peripheral:self.currentPeripheral];
//            [self.currentPeripheral readValueForCharacteristic:characteristic];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0000a042-0000-1000-8000-00805F9B34FB"]] ) {
            _writeCharacteristic = characteristic;
            [self.bleManager _notification:0xA032 characteristicUUID:0xA042 peripheral:self.currentPeripheral isActive:YES];
//            [self.currentPeripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}
//特征值已经更新
-(void)valueUpdate:(NSNotification *)notification
{
    CBCharacteristic *tmpCharacter = (CBCharacteristic*)[notification object];
    
#pragma mark 适配新版本通道
    if (tmpCharacter == _readCharacteristic) {
        NSData *receiveData = tmpCharacter.value;
        Byte *byte = (Byte *)[receiveData bytes];
        for (NSInteger i =0; i < receiveData.length; i ++) {
            NSLog(@"readCharacteristic---receiveDataBytes ====== %d\n",byte[i]);
        }
        [self.deviceCallBack removeAllObjects];
        if (byte[2] == (receiveData.length - 6)) {
            if (receiveData.length > 6) {
                if ([self.delegate respondsToSelector:@selector(getValueForPeripheral)]) {
                    [self.deviceCallBack addObject:receiveData];
                    [self.delegate getValueForPeripheral];
                }
            }
        }
    }else if (tmpCharacter == _writeCharacteristic){
        NSData *receiveData = tmpCharacter.value;
        Byte *byte = (Byte *)[receiveData bytes];
        for (NSInteger i =0; i < receiveData.length; i ++) {
            NSLog(@"writeCharacteristic---receiveDataBytes ====== %d\n",byte[i]);
        }
        [self.deviceCallBack removeAllObjects];
        if (byte[2] == (receiveData.length - 6)) {
            if (receiveData.length > 6) {
                if ([self.delegate respondsToSelector:@selector(getValueForPeripheral)]) {
                    [self.deviceCallBack addObject:receiveData];
                    [self.delegate getValueForPeripheral];
                }
            }
        }
    }

#pragma mark 适配老版本通道
    CHAR_STRUCT buf1;
    //将获取的值传递到buf1中；
    [tmpCharacter.value getBytes:&buf1 length:tmpCharacter.value.length];
    receiveByteSize += tmpCharacter.value.length;  //计算收到的所有数据包的长度
    countPKSSize++;
    BOOL IsAscii = YES;
    NSMutableString *muString = [NSMutableString new];
    if(IsAscii) //Ascii
    {
        for(int i =0;i<tmpCharacter.value.length;i++)
        {
            NSString *getString =[Tools stringFromHexString:[NSString stringWithFormat:@"%02X",buf1.buff[i]&0x000000ff]];
            [receiveSBString appendString:getString];
            [muString appendString:getString];
        }
    }else {//十六进制显示
        for(int i =0;i<tmpCharacter.value.length;i++)
        {
            NSString *getString = [NSString stringWithFormat:@"%02X",buf1.buff[i]&0x000000ff];
            [receiveSBString appendString:getString];
            [muString appendString:getString];
        }
        NSLog(@"传出来的数据 ----- %@",muString);
    }
    if ([self.delegate respondsToSelector:@selector(receiveData:)]) {
        [self.delegate receiveData:muString];
    }
}
// 完成写入
- (void)writeFinished{
    [self.bleManager _readValue:0xA032 characteristicUUID:0xA041 peripheral:self.currentPeripheral];
}

// 设备已经断开
- (void)deviceDisconnect:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(didDisconnectPeripheral:)]) {
        [self.delegate didDisconnectPeripheral:error];
    }
}

- (void)setIsBandingDevice:(BOOL)isBandingDevice{
    _isBandingDevice = isBandingDevice;
}

@end
