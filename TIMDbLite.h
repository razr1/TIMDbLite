//
//  TIMDbLite.h
//  TIMSqlite
//
//  Created by timou on 14-5-24.
//  Copyright (c) 2014年 timou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "TIMDbLiteResult.h"

@interface TIMDbLite : NSObject
@property (readonly,atomic) sqlite3 *db;
@property (readonly,nonatomic) NSString *dbName;

-(TIMDbLite*)initWithDb:(NSString*)dbPath;
-(BOOL)createTable:(NSString *)p_table columns:(NSString*)p_columns existsDelete:(BOOL)exdelete;
-(TIMDbLiteResult*)select:(NSString *)table field:(NSString *)fieldStr where:(NSString*)whereStr groupBy:(NSString *)groupByStr orderBy:(NSString*)orderStr limit:(NSString*)limitStr;
-(TIMDbLiteResult*)select:(NSString*)sql, ...;
-(NSInteger)insert:(NSString*)table data:(NSDictionary*)insertdata getLastInsertId:(BOOL)flag;
-(BOOL)update:(NSString*)table data:(NSDictionary*)setData werhe:(NSString*)whereStr;
-(BOOL)deleteData:(NSString*)table wehre:(NSString*)whereStr;
-(BOOL)query:(NSString*)sql, ...;
-(void)close;
-(BOOL)open;
@end
