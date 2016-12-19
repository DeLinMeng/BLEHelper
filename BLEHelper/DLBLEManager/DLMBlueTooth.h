//
//  DLMBlueTooth.h
//  3Pomelos
//
//  Created by 孟德林 on 2016/11/4.
//  Copyright © 2016年 ichezheng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>

/*
 1、蓝牙设备流程：先扫描到外设 --- 获取服务 --- 获取特征值 --- 获取描述
 2、接受数据是 --- 从串口数据通道转发到蓝牙输出的数据 ---- 可以自由的关闭（及注册的通知）
 3、写入数据 --- 是APP通过BLE API接口，蓝牙输入转发到串口输出
 */
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                                         //////
////                  根据业务需要，如果想要获取不同的状态的需要注册通知，如下已经列出                                   //////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define STOPSCAN                      @"STOP_SCAN"                       // 结束扫描
#define kBLUETOOTH_ISALREADLY_OPEN    @"kBLUETOOTH_ISALREADLY_OPEN"      // 蓝牙设备已经打开
#define BLE_DEVICE_FOUND              @"BLE_DEVICE_FOUND"                // 蓝牙设备已经发现
#define BLE_DEVICE_RSSI_FOUND         @"BLEDEVICERSSIFOUND"              // 扫描到的外设
#define DID_CONNECTED_BLEDEVICE       @"DIDCONNECTEDBLEDEVICE"           // 已经连接到蓝牙设备
#define DEVICE_ISDISCONNECT           @"DEVICE_ISDISCONNECT"             // 已经断开了连接
#define RSSI_UPDATE                   @"RSSIUPDATE"                      // RSSI 已经更新
#define SERVICE_FOUND_OVER            @"SERVICEFOUNDOVER"                // SERVICE 被接收到
#define DOWNLOAD_SERVICE_PROCESS_STEP @"DOWNLOAD_SERVICE_PROCESS_STEP"   // 获取到服务的详信息
#define VALUE_CHANG_UPDATE            @"VALUECHANGUPDATE"                // 接受数据已经发生改变
#define BLUETOOTH_MACID               @"kBLUETOOTHMACID"                 // DOWNLOAD_SERVICE_PROCESS_STEP
#define BLE_WRITE_FINISH              @"BLEWRITEFINISH"                  // 写入成功
#define DEVICE_FAILCONNECT            @"DEVICE_FAILCONNECT"              // 设备已经断开连接

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                                       控制信号强度                                                         ////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define kDEFAULT_RSSI_VALUE         30
#define kDEFAULT_DISTIANCE_VALUE    10
#define kRANGEVALUE                 15         // 范围
#define kMINRSSIVALUE               30         // 最小值
#define kMAXRSSIVALUE               85         // 最大值

@interface DLMBlueTooth : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>{
    
    NSTimer *_scanKeepTimer; //扫描时间
    Boolean _isScan;         //是否正在扫描
}

@property (nonatomic ,strong) NSMutableSet *peripherals;                    //保存所有扫描到的外设

@property (nonatomic ,strong) CBCentralManager *BLECenterManager;           //BLE 中心管理器对象

@property (nonatomic ,strong) CBPeripheral *currentActivePeripheral;        //当前进入链接状态的外围设备

@property (nonatomic ,strong) NSMutableArray *currentActiveCharacteristics; //当前正在操作的特征值缓存

@property (nonatomic ,strong) NSMutableArray *currentActiveDescriptors;     //正在操作的特征值描述

@property (nonatomic ,strong) NSString *currentMode;                        //当前正在操作的UUID

@property (nonatomic ,strong) CBService *currentActiveService;              //当前的正在操作的服务

@property (readwrite)         Byte      RSSIValue;                         //RSSI值


// 写入数据，发送给外设
-(void)_writeValue:(int)serviceUUID
characteristicUUID:(int)characteristicUUID
        peripheral:(CBPeripheral *)peripheral
              data:(NSData *)data;
// 从外设读取数据
-(void)_readValue:(int)serviceUUID
characteristicUUID:(int)characteristicUUID
       peripheral:(CBPeripheral *)peripheral;

// 该外设注册通知状态是否活跃
-(void)_notification:(int)serviceUUID
  characteristicUUID:(int)characteristicUUID
          peripheral:(CBPeripheral *)peripheral
            isActive:(BOOL)isActive;

// 初始化中心管理器
- (void)_initializeCenterManager;


//
- (UInt16)_swap:(UInt16) s;

// 搜索外设，并设置超时时间
- (int)_scanBLEPeripherals:(int)timeOut;

// 停止扫描
- (void)_stopScan;

// 打印单个外设的详细信息
- (void)_logPeripheralInfo:(CBPeripheral *)peripheral;

// 开始连接指定的外部设备
- (void)_startConnectPeripheral:(CBPeripheral *)peripheral;

// 打印特征值描述
- (void)_logCharacteristicDescriptorMessage:(CBDescriptor *)descriptor;

// 打印特征值详细信息
- (void)_logCharacteristicInfoMessage:(CBCharacteristic *)characteristic;

//
- (id)_getCharcteristicDiscriptorFromCurrnetActiveDescriptorsArray:(CBCharacteristic *)characteristic;

// 判断当前特征值是否是活跃的(正在连接中的)
- (BOOL)_isActiveCharacteristic:(CBCharacteristic *)characteristic;

// 从外设中获取所有的服务
- (void)_getAllServicesFromPeripheral:(CBPeripheral *)Peripheral;

// 从外设中获取特征值
- (void)_getAllCharacteristicFromPeripheral:(CBPeripheral *)Peripheral;

// 发现服务根据UUID 和 peripheral
- (CBService *)_discoverServiceFromUUID:(CBUUID *)UUID peripheral:(CBPeripheral *)peripheral;

// 发现特性 根据UUID 和 service
- (CBCharacteristic *)_discoverCharacteristicFromUUID:(CBUUID *)UUID service:(CBService *)service;

#pragma mark ---- 关于UUID的一些操作
-(const char *) UUIDToString:(CFUUIDRef) UUID;

-(const char *) CBUUIDToString:(CBUUID *) UUID;

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;

-(int) compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;

-(UInt16) CBUUIDToInt:(CBUUID *) UUID;

-(int) UUIDSAreEqual:(CFUUIDRef)UUID1 u2:(CFUUIDRef)UUID2;


@end
