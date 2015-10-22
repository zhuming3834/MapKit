//
//  ViewController.m
//  MapKit
//
//  Created by HGDQ on 15/10/21.
//  Copyright (c) 2015年 HGDQ. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "ResultTableViewCell.h"

@interface ViewController ()<CLLocationManagerDelegate,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong)CLLocationManager *manage;
@property (weak, nonatomic) IBOutlet UILabel *currentLocation;       //当前位置
@property (weak, nonatomic) IBOutlet UILabel *currentLatitudeLabel;  //当前位置的纬度
@property (weak, nonatomic) IBOutlet UILabel *currentLongitudeLabel; //当前位置的精度
@property (weak, nonatomic) IBOutlet UILabel *currentAltitudeLabel;  //当前位置的海拔
@property (weak, nonatomic) IBOutlet UITextField *textField;         //搜索栏textField
@property (weak, nonatomic) IBOutlet UITableView *tabelView;         //搜做结果显示
@property (weak, nonatomic) IBOutlet UILabel *resultNumLabel;

@property (nonatomic,copy)NSArray *placemarksArr;                    //存储搜索结果

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTextField];
	[self setTableView];
	[self setCLLoactionManage];
	// Do any additional setup after loading the view, typically from a nib.
}
/**
 *  开启定位和开启方向
 */
- (void)setCLLoactionManage{
	self.manage = [[CLLocationManager alloc] init];
	self.manage.delegate = self;
	self.manage.desiredAccuracy = kCLLocationAccuracyBest;
	//开始定位
	[self.manage startUpdatingLocation];
	//iOS8请求授权
	[self.manage requestWhenInUseAuthorization];
	//开始方向
	[self.manage startUpdatingHeading];
}
#pragma mark - 定位的回调
/**
 *  定位的回调
 *  这个回调会多次执行
 *  @param manager   manager description
 *  @param locations locations description
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
	CLLocation *loc = [locations firstObject];
//	NSLog(@"纬度 = %f，经度 = %f",loc.coordinate.latitude,loc.coordinate.longitude);
//	NSLog(@"数组个数 = %ld",(long)locations.count);
//	NSLog(@"海平面高度 = %f",loc.altitude );
//	NSLog(@"速度 = %f",loc.speed);
//	NSLog(@"时间 = %@",loc.timestamp);
	//逆向地理编码
	static dispatch_once_t oneToken;
	dispatch_once(&oneToken, ^{
		[self setRevGeocodeWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
	});
	//当前位置的海拔高度
	self.currentAltitudeLabel.text = [NSString stringWithFormat:@"%f",loc.altitude];
	//当前位置的纬度
	self.currentLatitudeLabel.text = [NSString stringWithFormat:@"%f",loc.coordinate.latitude];
	//当前位置的精度
	self.currentLongitudeLabel.text =[NSString stringWithFormat:@"%f",loc.coordinate.longitude];
}
#pragma mark - 方向的回调
/**
 *  方向的回调
 *
 *  @param manager    manager description
 *  @param newHeading newHeading description
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
	//与磁场北方向的偏角
//	NSLog(@"magneticHeading = %f",newHeading.magneticHeading);
//	//与正北方向的偏角
//	NSLog(@"trueHeading = %f",newHeading.trueHeading);
//	NSLog(@"headingAccuracy = %f",newHeading.headingAccuracy);
//	NSLog(@"description = %@",newHeading.description);
//	NSLog(@"timestamp = %@",newHeading.timestamp);
//	NSLog(@"x = %f",newHeading.x);
//	NSLog(@"y = %f",newHeading.y);
//	NSLog(@"z = %f",newHeading.z);
}
#pragma mark -正向地理编码
/**
 *  根据地名获取地理编码
 *
 *  @param place 需要被定位的地名
 */
- (void)getClgeocode:(NSString *)place{
	CLGeocoder *clgeocode = [[CLGeocoder alloc] init];
	[clgeocode geocodeAddressString:place completionHandler:^(NSArray *placemarks, NSError *error) {
		self.placemarksArr = placemarks;
		self.resultNumLabel.text = [NSString stringWithFormat:@"%d条数据",placemarks.count];
		[self.tabelView reloadData];
	}];
}
#pragma mark -逆向地理编码
/**
 *  逆向地理编码
 *
 *  @param latitude  latitude 纬度
 *  @param longitude longitude 精度
 */
- (void)setRevGeocodeWithLatitude:(float)latitude longitude:(float)longitude{
	CLLocation  *revGeocode = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
	CLGeocoder *clgeocode = [[CLGeocoder alloc] init];
	[clgeocode reverseGeocodeLocation:revGeocode completionHandler:^(NSArray *placemarks, NSError *error) {
		CLPlacemark *mark = (CLPlacemark *)placemarks[0];
		NSLog(@"name = %@",mark.name);
		self.currentLocation.text = mark.name;
	}];
}
/**
 *  textField和代理的关联
 */
- (void)setTextField{
	self.textField.delegate = self;
}
#pragma mark - 实现textField代理方法
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
	return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
	
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
	return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField{
	return YES;
}
/**
 *  textField回调方法
 *  键盘搜索键按下后开始正向地理编码搜索  收起键盘
 *  @param textField textField description
 *
 *  @return YES
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[self getClgeocode:textField.text];
	[textField resignFirstResponder];
	return YES;
}
/**
 *  设置tabelView和代理关联
 *  注册ResultTableViewCell
 */
- (void)setTableView{
	self.tabelView.delegate = self;
	self.tabelView.dataSource = self;
	[self.tabelView registerNib:[UINib nibWithNibName:@"ResultTableViewCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
}
#pragma mark - 实现tabelView代理回调方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	//设置row的个数
	return self.placemarksArr.count;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	//设置row的高度
	return 60;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	static NSString *identify = @"Cell";
	ResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
	if (cell == nil) {
		cell = [[[NSBundle mainBundle] loadNibNamed:@"ResultTableViewCell" owner:self options:nil] firstObject];
	}
	CLPlacemark *mark = (CLPlacemark *)self.placemarksArr[indexPath.row];
	cell.loactionLabel.text = mark.name;
	cell.laLabel.text = [NSString stringWithFormat:@"%f",mark.location.coordinate.longitude];
	cell.loLabel.text = [NSString stringWithFormat:@"%f",mark.location.coordinate.latitude];
	return cell;
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
















































