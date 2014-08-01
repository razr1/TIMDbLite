//
//  TIMDbLiteResult.m
//  TIMSqlite
//
//  Created by timou on 14-5-27.
//  Copyright (c) 2014年 timou. All rights reserved.
//

#import "TIMDbLiteResult.h"

@implementation TIMDbLiteResult
-(TIMDbLiteResult*)initWithStmt:(sqlite3_stmt*)stmt
{
    self = [super init];
    if(self){
        _result = stmt;
    }
    return self;
}

-(id)next:(Class)objClass
{
    return [self next:objClass format:nil];
}

-(NSDictionary*)next
{
    NSMutableDictionary *result = nil;
    if(_result != nil){
        sqlite3_stmt *stmt = _result;
        if(sqlite3_step(stmt) == SQLITE_ROW){
            result = [[NSMutableDictionary alloc] init];
            int count = sqlite3_column_count(stmt);
            for(int i=0; i<count; i++){
                int type = sqlite3_column_type(stmt, i);
                NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
                id value;
                switch (type) {
                    case SQLITE_INTEGER:
                        value = [NSNumber numberWithInt:sqlite3_column_int(stmt, i)];
                        break;
                    case SQLITE_FLOAT:
                        value = [NSNumber numberWithDouble:sqlite3_column_double(stmt, i)];
                        break;
                    case SQLITE_BLOB:
                        value = [NSData dataWithBytes:sqlite3_column_blob(stmt, i) length:sizeof(sqlite3_column_blob(stmt, i))];
                        break;
                    case SQLITE_NULL:
                        value = [NSNull null];;
                        break;
                    case SQLITE_TEXT:
                        value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt,i)];
                        break;
                    default:
                        value = [NSNull null];;
                        break;
                }                
                result[name] = value;
            }
            
        }else{
            [self clear];
        }
    }
    return result;
}

-(id)next:(Class)objClass format:(NSDictionary*)fieldFormat
{
    id result = nil;
    if(_result != nil){
        sqlite3_stmt *stmt = _result;
        if(sqlite3_step(stmt) == SQLITE_ROW){
            result = [[objClass alloc] init];
            int count = sqlite3_column_count(stmt);
            for(int i=0; i<count; i++){
                int type = sqlite3_column_type(stmt, i);
                NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
                id value;
                switch (type) {
                    case SQLITE_INTEGER:
                        value = [NSNumber numberWithInt:sqlite3_column_int(stmt, i)];
                        break;
                    case SQLITE_FLOAT:
                        value = [NSNumber numberWithDouble:sqlite3_column_double(stmt, i)];
                        break;
                    case SQLITE_BLOB:
                        value = [NSData dataWithBytes:sqlite3_column_blob(stmt, i) length:sizeof(sqlite3_column_blob(stmt, i))];
                        break;
                    case SQLITE_NULL:
                        value = nil;
                        break;
                    case SQLITE_TEXT:
                        value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt,i)];
                        break;
                    default:
                        value = nil;
                        break;
                }
                
                if(!value)
                    continue;
                
                if(fieldFormat && fieldFormat[name]){
                    if(fieldFormat[name] == [NSDate class]){
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        dateFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
                        NSDate *date = [dateFormat dateFromString:value];
                        [result setValue:date forKey:name];
                        continue;
                    }
                    //...
                }
                
                [result setValue:value forKey:name];
            }
        }else{
            [self clear];
        }
    }
    return result;
}

-(void)clear
{
    if(_result){
        sqlite3_finalize(_result);
        _result = nil;
    }
}

-(void)dealloc
{
    [self clear];
}
@end
