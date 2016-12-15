//
//  ImageCell.m
//  CreateGif
//
//  Created by YangY on 16/10/24.
//  Copyright © 2016年 羊羊. All rights reserved.
//

#import "ImageCell.h"

@implementation ImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.borderColor = [UIColor grayColor].CGColor;
    self.layer.borderWidth = 1.0;
}

- (IBAction)clickRemoBtn:(id)sender {
    if (_remove) {
        _remove();
    }
}

@end
