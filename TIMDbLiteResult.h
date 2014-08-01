//
//  TIMDbLiteResult.h
//  TIMSqlite
//
//  Created by timou on 14-5-27.
//  Copyright (c) 2014年 timou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface TIMDbLiteResult : NSObject
@property (readonly) sqlite3_stmt *result;
-(TIMDbLiteResult*)initWithStmt:(sqlite3_stmt*)stmt;
-(NSDictionary*)next;
-(id)next:(Class)objClass;
-(id)next:(Class)objClass format:(NSDictionary*)fieldFormat;
-(void)clear;
@end
