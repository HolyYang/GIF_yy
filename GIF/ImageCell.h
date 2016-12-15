//
//  ImageCell.h
//  CreateGif
//
//  Created by YangY on 16/10/24.
//  Copyright © 2016年 羊羊. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^Remove)(void);
@interface ImageCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageV;
@property(nonnull,copy)Remove remove;
@end
