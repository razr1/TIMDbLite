//
//  TIMDbLite.m
//  TIMSqlite
//
//  Created by timou on 14-5-24.
//  Copyright (c) 2014年 timou. All rights reserved.
//

#import "TIMDbLite.h"

@implementation TIMDbLite

-(TIMDbLite*)initWithDb:(NSString*)dbPath
{
    self = [super init];
    if(self && dbPath){
        _dbName = dbPath;
    }
    return self;
}

/**
 *  创建表
 *
 *  @param p_table   表名
 *  @param p_columns 字段
 *  @param exdelete  是否删除原表
 *
 *  @return BOOL
 */
-(BOOL)createTable:(NSString *)p_table columns:(NSString*)p_columns existsDelete:(BOOL)exdelete
{
    if(![self open]){
        return NO;
    }
    
    NSString *sql;
    if(exdelete){
        sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;CREATE TABLE %@ (%@)",p_table,p_table,p_columns];
    }else{
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)",p_table,p_columns];
    }
    
    char *errorMesg = nil;
    int result = sqlite3_exec(_db, [sql UTF8String], nil, nil, &errorMesg);
    if(result != SQLITE_OK){
        NSLog(@"%s",errorMesg);
        return NO;
    }
    //[self close:nil];
    return YES;
}
/**
 *  查询
 *
 *  @param table      表名
 *  @param fieldStr   筛选字段
 *  @param whereStr   WHERE字句
 *  @param groupByStr GROUP BY字句
 *  @param orderStr   ORDER BY字句
 *  @param limitStr   LIMIT 字句
 *
 *  @return TIMDbLiteResult*
 */
-(TIMDbLiteResult*)select:(NSString *)table field:(NSString *)fieldStr where:(NSString*)whereStr groupBy:(NSString *)groupByStr orderBy:(NSString*)orderStr limit:(NSString*)limitStr;
{
    if(![self open]){
        return nil;
    }
    
    NSString *wh   = whereStr ? [NSString stringWithFormat:@"WHERE %@",whereStr] : @"";
    NSString *gby  = groupByStr ? [NSString stringWithFormat:@"GROUP BY %@",groupByStr] : @"";
    NSString *oby  = orderStr ? [NSString stringWithFormat:@"ORDER BY %@",orderStr] : @"";
    NSString *li   = limitStr  ? [NSString stringWithFormat:@"LIMIT %@",limitStr] : @"";
    
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@ %@ %@ %@",fieldStr,table,wh,gby,oby,li];
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, nil);
    if(result != SQLITE_OK){
        sqlite3_finalize(stmt);
        NSLog(@"语句编译失败--sql:%@",sql);
        return nil;
    }
    TIMDbLiteResult *dbResult = [[TIMDbLiteResult alloc] initWithStmt:stmt];
    //[self close:nil];
    return dbResult;
}
/**
 *  查询
 *
 *  @param sql SQL语句，最后一个参数必须为nil
 *
 *  @return TIMDbLiteResult*
 */
-(TIMDbLiteResult*)select:(NSString*)sql, ...
{
    if(!sql || ![self open]){
        return nil;
    }
    sqlite3_stmt *stmt = nil;
    if(sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, nil) != SQLITE_OK){
        sqlite3_finalize(stmt);
        NSLog(@"语句编译失败--sql:%@",sql);
        return nil;
    }
    
    va_list argList;
    va_start(argList, sql);
    id param = va_arg(argList, id);
    int i = 1;
    while (param) {
        if(![self stmtBind:stmt object:param pos:i]){
            return nil;
        }
        i++;
        param = va_arg(argList, id);
    }
    va_end(argList);
    TIMDbLiteResult *dbResult = [[TIMDbLiteResult alloc] initWithStmt:stmt];
    //[self close:nil];
    return dbResult;
}
/**
 *  插入
 *
 *  @param table      表明
 *  @param insertdata 要插入的数据, @{"字段名":"值"}
 *  @param flag       是否返回 last_insert_rowid;
 *
 *  @return 如果失败-1,getLastInsertId为YES返回last_insert_rowid()，否则返回0
 */
-(NSInteger)insert:(NSString*)table data:(NSDictionary*)insertdata getLastInsertId:(BOOL)flag
{
    if(!insertdata || ![self open]){
        return -1;
    }
    
    NSArray *keys = [insertdata allKeys];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (id item in keys) {
        [values addObject:@"?"];
    }
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@);",table,[keys componentsJoinedByString:@","],[values componentsJoinedByString:@","]];
    
    sqlite3_stmt *stmt = nil;
    if(sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, nil) != SQLITE_OK){
        sqlite3_finalize(stmt);
        NSLog(@"语句编译失败--sql:%@",sql);
        return -1;
    }
    
    int i = 1;
    for (id key in insertdata) {
        if(![self stmtBind:stmt object:insertdata[key] pos:i]){
            return -1;
        }
        i++;
    }
        
    if(sqlite3_step(stmt) != SQLITE_DONE){
        NSLog(@"数据插入失败!---sql:%@",sql);
        sqlite3_finalize(stmt);
        return -1;
    }

    NSInteger result = 0;
    if(flag){
        NSString *lastInsertIdSql = @"SELECT last_insert_rowid();";
        sqlite3_prepare_v2(_db, [lastInsertIdSql UTF8String], -1, &stmt, nil);
        if(sqlite3_step(stmt) == SQLITE_ROW){
            result = sqlite3_column_int(stmt, 0);
        }
    }
    sqlite3_finalize(stmt);
    return result;
}

/**
 *  更新数据
 *
 *  @param table    表明
 *  @param setData  要更新的数据, @{"字段名":"值"}
 *  @param whereStr WHERE字句
 *
 *  @return BOOL
 */
-(BOOL)update:(NSString*)table data:(NSDictionary*)setData werhe:(NSString*)whereStr
{
    if(!setData || ![self open]){
        return NO;
    }
    
    NSArray *keys = [setData allKeys];
    if(whereStr == nil)
        whereStr = @"";
    else{
        whereStr = [NSString stringWithFormat:@"WHERE %@",whereStr];
    }
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@=? %@;",table,[keys componentsJoinedByString:@"=?,"],whereStr];
    
    sqlite3_stmt *stmt = nil;
    if(sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, nil) != SQLITE_OK){
        sqlite3_finalize(stmt);
        NSLog(@"语句编译失败--sql:%@",sql);
        return NO;
    }
    
    int i = 1;
    for (id key in setData){
        if(![self stmtBind:stmt object:setData[key] pos:i]){
            return NO;
        }
        i++;
    }
    
    BOOL result = YES;
    if(sqlite3_step(stmt) != SQLITE_DONE){
        NSLog(@"数据更新失败!---sql:%@",sql);
        result = NO;
    }
    
    sqlite3_finalize(stmt);
    return result;
}

/**
 *  删除数据
 *
 *  @param table    表明
 *  @param whereStr WHERE字句
 *
 *  @return BOOL
 */
-(BOOL)deleteData:(NSString*)table wehre:(NSString*)whereStr
{
    if(![self open]){
        return NO;
    }
    
    NSString *wh   = whereStr ? [NSString stringWithFormat:@"WHERE %@",whereStr] : @"";
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@",table,wh];
    int result;
    sqlite3_stmt *stmt = nil;
    if(sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, nil) == SQLITE_OK){
        result = sqlite3_step(stmt);
    }else{
        return NO;
    }
    sqlite3_finalize(stmt);
    return (result == SQLITE_DONE);
}

/**
 *  执行sql语句
 *
 *  @param sql SQL语句,最后一个参数必须为nil
 *
 *  @return BOOL
 */
-(BOOL)query:(NSString*)sql, ...
{
    if(!sql || ![self open]){
        return NO;
    }
    
    sqlite3_stmt *stmt = nil;
    int result = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, nil);
    if(result != SQLITE_OK){
        sqlite3_finalize(stmt);
        NSLog(@"语句编译失败--sql:%@",sql);
        return NO;
    }
    
    va_list argList;
    va_start(argList, sql);
    id param = va_arg(argList, id);
    int i = 1;
    while (param) {
        if(![self stmtBind:stmt object:param pos:i]){
            return NO;
        }
        i++;
        param = va_arg(argList, id);
    }
    va_end(argList);
    
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (result ==  SQLITE_DONE);
}

/**
 *  打开数据库
 *
 *  @return BOOL
 */
-(BOOL)open
{
    if(_dbName==nil || _dbName.length==0) {
        NSLog(@"Error:数据库文件路径是空！");
        return NO;
    }
    
    if(_db || sqlite3_open([_dbName UTF8String], &_db) == SQLITE_OK){
        return YES;
    }else{
        NSLog(@"数据库文件打开失败！");
        return NO;
    }
}

/**
 *  关闭数据库
 *
 *  @param stmt sqlite3_stmt
 */
-(void)close
{
    if(_db){
        sqlite3_close(_db);
        _db = nil;
    }
}

-(BOOL)stmtBind:(sqlite3_stmt *)stmt object:(id)obj pos:(int) i
{
    id param = obj;
    if([param isKindOfClass:[NSString class]]){
        //字符串类型
        sqlite3_bind_text(stmt, i, [param UTF8String], -1, nil);
    }else if([param isKindOfClass:[NSNumber class]]){
        //数字类型
        CFNumberRef numberRef = (__bridge CFNumberRef)param;
        int numberType = CFNumberGetType(numberRef);        
        switch(numberType){
            case kCFNumberIntType:
            case kCFNumberSInt8Type:
            case kCFNumberSInt16Type:
            case kCFNumberSInt32Type:
                sqlite3_bind_int(stmt,i,[param intValue]);
            break;
                
            case kCFNumberSInt64Type:
            case kCFNumberLongType:
            case kCFNumberLongLongType:
                sqlite3_bind_int64(stmt,i,[param intValue]);
            break;
                
            case kCFNumberFloatType:
            case kCFNumberFloat32Type:
            case kCFNumberFloat64Type:
                sqlite3_bind_double(stmt,i,[param floatValue]);
            break;
                
            case kCFNumberDoubleType:
                sqlite3_bind_double(stmt,i,[param doubleValue]);
            break;
                
            default:
                sqlite3_bind_text(stmt,i,[[param stringValue] UTF8String],-1,nil);
            break;
        }
    }else if([param isKindOfClass:[NSDate class]]){
        //日期
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        dateFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *dateStr = [dateFormat stringFromDate:param];
        sqlite3_bind_text(stmt, i, [dateStr UTF8String], -1, nil);
        
    }else if([param isKindOfClass:[NSData class]]){
        //二进制数据
        sqlite3_bind_blob(stmt, i, [param bytes], (int)[param length], nil);
    }else{
        NSLog(@"未知数据类型%@,只支持NSString,NSNumber,NSDate,NSData",[param class]);
        sqlite3_finalize(stmt);
        return NO;
    }
    return YES;
}

-(void) dealloc
{
    [self close];
    _dbName = nil;
}

@end
