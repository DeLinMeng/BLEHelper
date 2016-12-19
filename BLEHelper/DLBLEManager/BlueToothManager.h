//
//  BlueToothManager.h
//  3Pomelos
//
//  Created by 孟德林 on 2016/11/7.
//  Copyright © 2016年 ichezheng.com. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "Tools.h"
#import "DLMBlueTooth.h"

#define BLEMANAGER [BlueToothManager manager]

typedef enum MODEl_STATE
{
    MODEL_NORMAL = 0,
    MODEL_CONNECTING = 1,
    MODEL_SCAN = 2,
    MODEL_CONECTED = 3,
} StartModel;

@protocol BlueToothManagerDelegate <NSObject>

@optional
/**
 已经扫描到设备
 
 @param Peripherals 设备的集合
 */
- (void)didDiscoverPeripheral:(NSSet *)Peripherals canConnect:(BOOL)canConnect;


/**
 已经连接到指定的外设
 
 @param peripheral 指定的外设（默认扫描到的外设）
 */
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;


/**
 数据响应(老版本响应Value更新和接收数据通道)
 
 @param data 数据是分包接收的，需要做特别的处理
 */
- (void)receiveData:(NSString *)data;


/**
 数据响应(新版本响应Value更新，数据查看deviceCallBack属性)
 */
- (void)getValueForPeripheral;


/**
 停止扫描蓝牙外设

 */
- (void)stopScanBLEThenUpdateDevices;


/**
 已经断开蓝牙设备连接
 
 @param error 断开连接的错误信息
 */
- (void)didDisconnectPeripheral:(NSError *)error;


@end


@interface BlueToothManager : NSObject

@property (nonatomic, assign)id<BlueToothManagerDelegate>delegate;

@property (nonatomic, strong,readonly) CBPeripheral *currentPeripheral;

@property (nonatomic, assign) StartModel startModel;

@property (nonatomic, strong) DLMBlueTooth *bleManager;

@property (nonatomic, readonly) BOOL  isBandingDevice;

/**
 新版本数据
 */
@property (nonatomic, strong) NSMutableArray *deviceCallBack;

+ (instancetype)manager;
/**
 只需要在 AppDelegate.m 启动方法中被调用一次即可
 */
- (void)initializerBLEManager;


/**
 开始扫描设备
 */
- (void) startScanDevice;


/**
 停止扫描
 */
- (void) stopScan;


/**
 注册广播频道，准备开始接受数据
 */
- (void)startReceiveData;


/**
 注销广播频道，结束接受数据
 */
- (void)stopReceiveData;


/**
 连接指定的设备
 
 @param peripheral 指定的设备 peripheral
 */
- (void)connectPeripheralDevice:(CBPeripheral *)peripheral;

/**
 取消连接
 */
- (void)cancelConnect;


/**
 老版本发送数据
 
 @param data 发送的数据流（data）
 */
- (void)sendDataToDevice:(NSString *)data;


/**
 新版本发送数据

 @param data 发送的数据流 (data)
 */
- (void)writeValueForPeripheral:(NSData *)data;

/**
 是否已经绑定设备

 @param isBandingDevice 是否已经绑定设备
 */
- (void)setIsBandingDevice:(BOOL)isBandingDevice;
@end

