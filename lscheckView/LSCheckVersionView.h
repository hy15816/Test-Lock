//
//  LSCheckVersionView.h
//  anxindian
//
//  Created by Lost_souls on 16/6/6.
//  Copyright © 2016年 anerfa. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^didSelecedIndex)(NSInteger index);

@interface LSCheckVersionView : UIView



- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title subTitle:(NSString *)subTitle item:(NSString *)item, ...NS_REQUIRES_NIL_TERMINATION;

- (instancetype)initWithImage:(UIImage *)image msg:(NSString *)msg cancel:(NSString *)cancel sure:(NSString *)sure vc:(UIViewController *)vc  selectedIndex:(didSelecedIndex)selectedIndex;


- (void)showCheckView:(didSelecedIndex)selectedIndex;
- (void)dismissCheckView;

@end
