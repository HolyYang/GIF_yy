//
//  ViewController.m
//  GIF
//
//  Created by YangY on 16/10/27.
//  Copyright © 2016年 羊羊. All rights reserved.
//

#import "ViewController.h"
#import "UIView+Common.h"
#import "ZLPhotoActionSheet.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ImageCell.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/Photos.h>
#import "ZLDefine.h"
#import "ToastUtils.h"
#import <Photos/PHPhotoLibrary.h>
//item宽度
#define ITEM_Height                 (kViewWidth-60)/3
@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>{
    ZLPhotoActionSheet *        _actionSheet;
    NSMutableArray *            _photoArr;
    NSString *                  _pathUrl;
}
@property (weak, nonatomic) IBOutlet UIButton *choosePicture;
@property (weak, nonatomic) IBOutlet UIButton *createGif;
@property (weak, nonatomic) IBOutlet UICollectionView *collection;
@property (weak, nonatomic) IBOutlet XPQGifView *gifView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *gifView_height;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _photoArr = [[NSMutableArray alloc] init];
    //创建一个layout布局类
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    //设置布局方向为垂直流布局
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    //设置每个item的大小为100*100
    layout.itemSize = CGSizeMake(ITEM_Height, ITEM_Height);
    [self.collection setCollectionViewLayout:layout];
    UINib * nib = [UINib nibWithNibName:@"ImageCell" bundle:[NSBundle mainBundle]];
    [self.collection registerNib:nib forCellWithReuseIdentifier:@"cellid"];
    
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlelongGesture:)];
    [self.collection addGestureRecognizer:longGesture];
    
    _actionSheet = [[ZLPhotoActionSheet alloc] init];
    //设置照片最大选择数
    _actionSheet.maxSelectCount = 50;
    //设置照片最大预览数
    _actionSheet.maxPreviewCount = 100;
    
}

#pragma mark ------ UICollectionView
//返回分区个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
//返回每个分区的item个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _photoArr.count?:0;
}
//返回每个item
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ImageCell * cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellid" forIndexPath:indexPath];
    cell.imageV.image = _photoArr[indexPath.item];
    cell.remove = ^(void){
        id objc = [_photoArr objectAtIndex:indexPath.item];
        [_photoArr removeObject:objc];
        [self.collection reloadData];
    };
    return cell;
}
-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    id objc = [_photoArr objectAtIndex:sourceIndexPath.item];
    [_photoArr removeObject:objc];
    [_photoArr insertObject:objc atIndex:destinationIndexPath.item];
}
- (void)handlelongGesture:(UILongPressGestureRecognizer *)longGesture {
    //判断手势状态
    switch (longGesture.state) {
        case UIGestureRecognizerStateBegan:{
            //判断手势落点位置是否在路径上
            NSIndexPath *indexPath = [self.collection indexPathForItemAtPoint:[longGesture locationInView:self.collection]];
            if (indexPath == nil) {
                break;
            }
            //在路径上则开始移动该路径上的cell
            [self.collection beginInteractiveMovementForItemAtIndexPath:indexPath];
        }
            break;
        case UIGestureRecognizerStateChanged:
            //移动过程当中随时更新cell位置
            [self.collection updateInteractiveMovementTargetPosition:[longGesture locationInView:self.collection]];
            break;
        case UIGestureRecognizerStateEnded:
            //移动结束后关闭cell移动
            [self.collection endInteractiveMovement];
            break;
        default:
            [self.collection cancelInteractiveMovement];
            break;
    }
}
#pragma mark  ---点击选择图片
- (IBAction)choosePicture:(id)sender {
    
    [_actionSheet showWithSender:self animate:YES completion:^(NSArray<UIImage *> * _Nonnull selectPhotos) {
        [_photoArr addObjectsFromArray:selectPhotos];
        [self.collection reloadData];
    }];
}

#pragma mark  ---点击生成GIF
- (IBAction)createGif:(id)sender {
    if (_photoArr.count<2) {
        [ToastUtils showLong:@"请至少选择两张图片"];
        return;
    }
    [self creategif:_photoArr];
    
    NSURL *url = [NSURL fileURLWithPath:_pathUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    UIImage * image = [UIImage imageWithData:data];
    self.gifView_height.constant = image.size.width*150/image.size.height;
    [_gifView setGifData:data];
    [_gifView start];
}
-(void)creategif:(NSArray *)arr
{
    
    //图像目标
    CGImageDestinationRef destination;
    NSString *path ;
    //创建输出路径
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentStr = [document objectAtIndex:0];
    NSString *textDirectory = [documentStr stringByAppendingPathComponent:@"gif"];
    
    
    [fileManager createDirectoryAtPath:textDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *gifName = [NSString stringWithFormat:@"yangyang.gif"];
    path = [textDirectory stringByAppendingPathComponent:gifName];
    
    CFURLRef url = CFURLCreateWithFileSystemPath (
                                                  kCFAllocatorDefault,
                                                  (CFStringRef)path,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    
    //通过一个url返回图像目标
    destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, arr.count, NULL);
    //设置gif的信息,播放间隔时间,基本数据,和delay时间
    NSDictionary *frameProperties = [NSDictionary
                                     dictionaryWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.3], (NSString *)kCGImagePropertyGIFDelayTime, nil]
                                     forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    //设置gif信息
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [dict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCGImagePropertyGIFHasGlobalColorMap];
    
    [dict setObject:(NSString *)kCGImagePropertyColorModelRGB forKey:(NSString *)kCGImagePropertyColorModel];
    
    [dict setObject:[NSNumber numberWithInt:8] forKey:(NSString*)kCGImagePropertyDepth];
    
    [dict setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount];
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:dict
                                                              forKey:(NSString *)kCGImagePropertyGIFDictionary];
    //合成gif
    for (UIImage* dImg in arr)
    {
        CGImageDestinationAddImage(destination, dImg.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    _pathUrl = path;
    
}
- (IBAction)savePotot:(id)sender {
    
    NSURL *url = [NSURL fileURLWithPath:_pathUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        [ToastUtils showLong:@"保存成功"];
    }] ;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
