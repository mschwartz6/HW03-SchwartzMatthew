//
//  StudentInfo.h
//  HW03-SchwartzMatthew
//
//  Created by alive on 11/22/17.
//  Copyright © 2017 Matthew Schwartz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StudentInfo : NSObject
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *address;
@property (nonatomic,strong) NSString *phone;
-(id)initWithData:(NSString *)n andAddress:(NSString *)a andPhone: (NSString *)p;
@end
