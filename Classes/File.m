//
//  File.m
//  Briefcase
//
//  Created by Michael Taylor on 06/07/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//
//  Notes:
//	The File class references into an SQLite3 database.
//	It uses a separate thread for all processing because
//	SQLite is not fully thread safe.  Channeling all 
//	database access through a particular thread makes
//	threaded access safe.

#import "File.h"
#import "Utilities.h"

static sqlite3_stmt * theIncompleteStatement	= nil;
static sqlite3_stmt * theInsertStatement	= nil;
static sqlite3_stmt * theDeleteStatement	= nil;
static sqlite3_stmt * theDeleteDirStatement	= nil;
static sqlite3_stmt * theHydrateStatement	= nil;
static sqlite3_stmt * theSaveStatement		= nil;
static sqlite3_stmt * theIconSetStatement	= nil;
static sqlite3_stmt * theIconGetStatement	= nil;
static sqlite3_stmt * thePreviewSetStatement	= nil;
static sqlite3_stmt * thePreviewGetStatement	= nil;
static sqlite3_stmt * theWebArchiveSetStatement	= nil;
static sqlite3_stmt * theWebArchiveGetStatement	= nil;
static sqlite3_stmt * theSearchByPathStatement  = nil;
static sqlite3_stmt * theTotalSizeStatement	= nil;

static NSMutableDictionary * theFilesByLocalPath = nil;
static const int kInitialDictionaryCapacity = 512;

NSString * kFileDeleted = @"File Deleted";
NSString * kFileChanged = @"File Changed";
NSString * kDirectoryDeleted = @"Directory Deleted";

NSInteger fileSortFunction(id item1, id item2, void * context);

@interface File (Private)

- (void)_notifyDelete:(NSString*)file_name;
+ (void)_notifyDirectoryDelete:(NSString*)dir_name;
- (void)_notifyChanged:(File*)file;

- (void)_getOrCreateFile;
- (void)_deleteFromDatabase;
- (void)_hydrateWithStatement:(sqlite3_stmt*)statement;
- (void)_hydrate;
- (void)_save;
- (void)_setIconData:(NSData*)data;
- (void)_getIconData;
- (void)_setPreviewData:(NSData*)data;
- (void)_getPreviewData;
- (void)_setWebArchiveData:(NSData*)data;
- (void)_getWebArchiveData;

@end

void displayDatabaseError(NSString * error)
{
    NSLog(@"Error: %@ (%s)", error, sqlite3_errmsg([Database sharedDatabase].sqliteDatabase));
}

@implementation File

+ (NSArray*)fileListAtLocalPath:(NSString*)path
//
//  Return a list of all files at the given path relative to our downloads 
//  directory.  Use the file system, rather then the database because it is
//  much more efficient when there are a large number of files stored in 
//  Briefcase.
//
{
    @synchronized(self)
    {
	NSString * name;
	NSString * downloads_path = [Utilities pathToDownloads];
	NSString * local_path = [downloads_path stringByAppendingPathComponent:path];
	
	NSDirectoryEnumerator * enumerator;
	enumerator = [[NSFileManager defaultManager] enumeratorAtPath:local_path];
	
	NSMutableArray * result = [NSMutableArray array];
	
	while (name = [enumerator nextObject]) 
	{
	    NSDictionary * attributes = [enumerator fileAttributes];
	    
	    if ([attributes fileType] == NSFileTypeDirectory)
	    {
		[enumerator skipDescendents];
		[result addObject:name];
	    }
	    else
	    {
		NSString * file_path = [path stringByAppendingPathComponent:name];
		NSValue * value = [theFilesByLocalPath objectForKey:file_path];
		File * item = [value nonretainedObjectValue];
		if (!item)
		    item = [[[File alloc] initWithLocalPath:file_path] autorelease];
		[result addObject:item];
	    }
	}
	
	[result sortUsingFunction:fileSortFunction context:nil];
	
	return result;
    }
    return nil;
}

+ (NSArray*)searchForFilesMatching:(NSString*)fragment
{
    @synchronized(self)
    {
	if (!theSearchByPathStatement)
	{
	    const char *sql = "SELECT size, is_zipped, download_complete, last_position, "
	    "bookmarks, remote_path, remote_mode, remote_host, remote_username, remote_port, "
	    "remote_create_time, remote_modify_time, local_path "
	    "FROM file WHERE local_path LIKE ? AND local_path NOT LIKE ?";
	    if (sqlite3_prepare_v2([Database sharedDatabase].sqliteDatabase, sql, 
				   -1, &theSearchByPathStatement, NULL) != SQLITE_OK) 
		displayDatabaseError(@"failed to prepare statement");
	}
	
	NSMutableArray * result = [NSMutableArray array];
	
	NSString * like = [NSString stringWithFormat:@"%%%@%%", fragment];
	NSString * not_like = [NSString stringWithFormat:@"%%%@%%/%%", fragment];
	
	int count = sqlite3_bind_parameter_count(theSearchByPathStatement);
	
	if(sqlite3_bind_text(theSearchByPathStatement, 1, [like UTF8String], -1, SQLITE_TRANSIENT))
	    displayDatabaseError(@"failed to bind parameter");
	
	if(sqlite3_bind_text(theSearchByPathStatement, 2, [not_like UTF8String], -1, SQLITE_TRANSIENT))
	    displayDatabaseError(@"failed to bind parameter");
	
	count = sqlite3_column_count(theSearchByPathStatement);
	
	while (sqlite3_step(theSearchByPathStatement) == SQLITE_ROW) 
	{
	    char * string_value = (char *)sqlite3_column_text(theSearchByPathStatement, 12);
	    if(!string_value)
		displayDatabaseError(@"failed to read database result");
	    
	    NSString * local_path = [NSString stringWithUTF8String:string_value];

	    NSValue * value = [theFilesByLocalPath objectForKey:local_path];
	    File * item = [value nonretainedObjectValue];
	    if (item)
		[result addObject:item];
	    else
	    {
		item = [[File alloc] init];
		[item _hydrateWithStatement:theSearchByPathStatement];
		[result addObject:item];
		[item release];
	    }
	}
	sqlite3_reset(theSearchByPathStatement);
	
	
	return [result sortedArrayUsingSelector:@selector(compareWithFile:)];
    }
    return nil;
}

+ (void)deleteDirectoryAtLocalPath:(NSString*)path
{
    @synchronized(self)
    {
	if (!theDeleteDirStatement)
	{
	    const char *sql = "DELETE FROM file WHERE local_path LIKE ?";
	    if (sqlite3_prepare_v2([Database sharedDatabase].sqliteDatabase, sql, 
				   -1, &theDeleteDirStatement, NULL) != SQLITE_OK) 
		displayDatabaseError(@"failed to prepare statement");
	}
	
	// Delete the database entries for the files below the given path
	NSString * delete_string = [NSString stringWithFormat:@"%@/%%", path];
	if (sqlite3_bind_text(theDeleteDirStatement, 1, [delete_string UTF8String], -1, SQLITE_TRANSIENT))
	    displayDatabaseError(@"failed to bind parameter");	
	
	if (sqlite3_step(theDeleteDirStatement) != SQLITE_DONE) 
	    displayDatabaseError(@"failed to delete database entries");	
	
	sqlite3_reset(theDeleteDirStatement);
		
	NSFileManager * manager = [NSFileManager defaultManager];
	NSString * directory_path = [[Utilities pathToDownloads] stringByAppendingPathComponent:path];
	
	NSError * error = nil;
	[manager removeItemAtPath:directory_path error:&error];
	if (error)
	    NSLog(@"Error removing file: %@",[error localizedDescription]);
	
	[self performSelectorOnMainThread:@selector(_notifyDirectoryDelete:)
			       withObject:path waitUntilDone:YES]; 
    }
}

+ (void)deleteFileAtLocalPath:(NSString*)path
{
    @synchronized(self)
    {
	File * file = [File fileWithLocalPath:path];
	if (file)
	    [file delete];
    }
}

+ (NSArray*)incompleteFiles
{
    NSMutableArray * result = nil;
    char * string_value;
    NSString * local_path;
    
    @synchronized(self)
    {
	if (!theIncompleteStatement)
	{
	    const char *sql = "SELECT local_path FROM file WHERE download_complete=0";
	    if (sqlite3_prepare_v2([Database sharedDatabase].sqliteDatabase, sql, 
				   -1, &theIncompleteStatement, NULL) != SQLITE_OK) 
	    {
		NSLog(@"Error: failed to prepare statement with message '%s'.", 
		      sqlite3_errmsg([Database sharedDatabase].sqliteDatabase));
	    }
	}
	
	result = [NSMutableArray array];
	
	while (sqlite3_step(theIncompleteStatement) == SQLITE_ROW) 
	{
	    string_value = (char *)sqlite3_column_text(theIncompleteStatement, 0);
	    local_path = (string_value) ? [NSString stringWithUTF8String:string_value] : @"";
	    
	    if ([[local_path lastPathComponent] length] == [local_path length])
		[result addObject:[File getOrCreateFileWithLocalPath:local_path]];
	}
	sqlite3_reset(theIncompleteStatement);
    }
    
    return result;
}

+ (NSUInteger)totalSizeOfAllFiles
{
    NSUInteger result = 0;
    
    @synchronized(self)
    {
	if (!theTotalSizeStatement)
	{
	    const char *sql = "SELECT size FROM file WHERE download_complete=1";
	    if (sqlite3_prepare_v2([Database sharedDatabase].sqliteDatabase, sql, 
				   -1, &theTotalSizeStatement, NULL) != SQLITE_OK) 
		displayDatabaseError(@"failed to prepare statement");
	}
	
	while (sqlite3_step(theTotalSizeStatement) == SQLITE_ROW) 
	    result += sqlite3_column_int64(theTotalSizeStatement, 0);
	
	sqlite3_reset(theTotalSizeStatement);
    }
    
    return result;
}

+ (File*)getOrCreateFileWithLocalPath:(NSString*)local_path
{
    File * result = nil;
    @synchronized(self)
    {
	result = [[theFilesByLocalPath objectForKey:local_path] nonretainedObjectValue];
    }
    if (!result)
    {
	result = [[[File alloc] initWithLocalPath:local_path] autorelease];
	@synchronized(self)
	{
	    [theFilesByLocalPath setObject:[NSValue valueWithNonretainedObject:result] 
				    forKey:local_path];
	}
    }
    return result;
}

+ (File*)fileWithLocalPath:(NSString*)local_path
{
    File * result;
    @synchronized(self)
    {
	result = [[theFilesByLocalPath objectForKey:local_path] nonretainedObjectValue];
	if (result)
	{
	    NSLog(@"File: %@ ref count: %d",local_path,[result retainCount]);
	    if (!result->myIsHydrated)
		[result hydrate];
	    return result;
	}
	else
	{
	    result = [[File alloc] init];
	    result.localPath = local_path;
	    [result hydrate];
	    
	    if (!result.size || [result.size longLongValue] == 0)
		// Hydrating failed
		result = nil;
	    else
		[theFilesByLocalPath setObject:[NSValue valueWithNonretainedObject:result] 
					forKey:local_path];
	    
	    [result autorelease];
	}
    }
    return result;
}

- (id)init
{
    if (!theFilesByLocalPath)
    {
	@synchronized(self)
	{
	    theFilesByLocalPath = [[NSMutableDictionary alloc] initWithCapacity:kInitialDictionaryCapacity];
	}
    }
    
    if (self = [super init]) 
    {
	myLocalPath = nil;
        myDatabase = [Database sharedDatabase].sqliteDatabase;
        myIsDirty = NO;
	myIsHydrated = NO;
    }
    return self;
}

- (id)initWithLocalPath:(NSString*)local_path
{    
    if (!theFilesByLocalPath)
    {
	@synchronized(self)
	{
	    theFilesByLocalPath = [[NSMutableDictionary alloc] initWithCapacity:kInitialDictionaryCapacity];
	}
    }
    
    if (self = [super init]) 
    {
	myLocalPath = [local_path retain];
        myDatabase = [Database sharedDatabase].sqliteDatabase;
        myIsDirty = NO;
	myIsHydrated = NO;
	
	[self performSelector:@selector(_getOrCreateFile) 
		     onThread:[Database databaseThread] 
		   withObject:nil 
		waitUntilDone:YES];
	
	@synchronized(self)
	{
	    [theFilesByLocalPath setObject:[NSValue valueWithNonretainedObject:self] 
				    forKey:myLocalPath];
	}
    }
    return self;
}

- (id)retain
{
    return [super retain];
}

- (oneway void)release
{
    if ([self retainCount] == 1)
    {
	// We are about to release this object, remove our reference
	@synchronized(self)
	{
	    [theFilesByLocalPath removeObjectForKey:myLocalPath];
	}
    }
    
    [super release];
}

- (void)dealloc 
{
    [myLocalPath release];
    [mySize release];
    [myRemotePath release];
    [myRemoteHost release];
    [myPreviewData release];
    [myIconData release];
    [super dealloc];
}

- (void)delete 
{   	
    [self performSelector:@selector(_deleteFromDatabase) 
		 onThread:[Database databaseThread] 
	       withObject:nil 
	    waitUntilDone:YES];
    
    // Remove the actual file
    NSFileManager * manager = [NSFileManager defaultManager];
    NSError * error = nil;
    [manager removeItemAtPath:self.path error:&error];
    if (error)
    {
	NSLog(@"Error removing file: %@",[error localizedDescription]);
    }
        
    [self performSelectorOnMainThread:@selector(_notifyDelete:)
			   withObject:self waitUntilDone:YES]; 
    
    @synchronized(self)
    {
	[theFilesByLocalPath removeObjectForKey:myLocalPath];
    }
}

- (void)hydrate 
{
    if (myIsHydrated) return;
    
    [self performSelector:@selector(_hydrate) 
		 onThread:[Database databaseThread] 
	       withObject:nil 
	    waitUntilDone:YES];
}

- (void)save 
{
    if (myIsDirty) 
    {
	[self performSelector:@selector(_save) 
		     onThread:[Database databaseThread] 
		   withObject:nil 
		waitUntilDone:YES];
	
	[self performSelectorOnMainThread:@selector(_notifyChanged:)
			       withObject:self waitUntilDone:YES];
    }
}

- (void)dehydrate
{
    [self save];
    
    [myLocalPath release];
    myLocalPath = nil;
    [mySize release];
    mySize = nil;
    [myRemotePath release];
    myRemotePath = nil;
    [myRemoteHost release];
    myRemoteHost = nil;
    [myRemoteUsername release];
    myRemoteUsername = nil;
    
    myIsHydrated = NO; 
}

- (NSComparisonResult)compareWithFile:(File*)other
{
    return [myLocalPath caseInsensitiveCompare:other.fileName];
}

#pragma mark Properties

- (NSString*)localPath
{
    return myLocalPath;
}

- (void)setLocalPath:(NSString*)local_path
{
    if ((!myLocalPath && !local_path) || (myLocalPath && local_path && [myLocalPath isEqualToString:local_path])) return;
    
    myIsDirty = YES;
    [myLocalPath release];
    myLocalPath = [local_path copy];
}

- (NSString*)fileName
{
    NSString * file_name = [myLocalPath lastPathComponent];
    if (myIsZipped)
	// Strip the .zip of the end of the filename
	return [file_name stringByDeletingPathExtension];
    else 
	return file_name;
}

- (NSString*)fileExtension
{
    return [[self.fileName pathExtension] lowercaseString];
}

- (NSString*)path
{
    NSString * downloads_path = [Utilities pathToDownloads];
    return [downloads_path stringByAppendingPathComponent:myLocalPath];
}

- (NSNumber*)size
{
    return mySize;
}

- (void)setSize:(NSNumber*)size
{
    NSAssert([size isKindOfClass:[NSNumber class]],@"Wrong type!!");
	
    
    if ((!mySize && !size) || (mySize && size && [mySize isEqualToNumber:size])) return;
    
    myIsDirty = YES;
    [mySize release];
    mySize = [size copy];
}

- (BOOL)isZipped
{
    return (BOOL)myIsZipped;
}

- (void)setIsZipped:(BOOL)zipped
{
    if (myIsZipped == zipped) return;
    
    myIsDirty = YES;
    myIsZipped = zipped;
}

- (BOOL)downloadComplete
{
    return (BOOL)myDownloadComplete;
}

- (void)setDownloadComplete:(BOOL)downloadComplete
{
    if (myDownloadComplete == (int)downloadComplete) return;
    
    myIsDirty = YES;
    myDownloadComplete = downloadComplete;
}

- (long long)lastViewLocation
{
    return myLastViewLocation;
}

- (void)setLastViewLocation:(long long)location
{
    if (myLastViewLocation == location) return;
    
    myIsDirty = YES;
    myLastViewLocation = location;
}

- (NSArray*)bookmarks
{
    return myBookmarks;
}

- (void)setBookmarks:(NSArray*)array
{
    myIsDirty = YES;
    myBookmarks = [array retain];
}

- (NSString*)remotePath
{
    return myRemotePath;
}

- (void)setRemotePath:(NSString*)remotePath
{
    if ((!myRemotePath && !remotePath) || 
	(myRemotePath && remotePath && [myRemotePath isEqualToString:remotePath])) return;
    
    myIsDirty = YES;
    [myRemotePath release];
    myRemotePath = [remotePath copy];
}

- (NSUInteger)remoteMode
{
    return myRemoteMode;
}

- (void)setRemoteMode:(NSUInteger)remoteMode
{
    if (myRemoteMode == remoteMode) return;
    
    myIsDirty = YES;
    myRemoteMode = remoteMode;
}

- (NSString*)remoteHost
{
    return myRemoteHost;
}

- (void)setRemoteHost:(NSString*)remoteHost
{
    if ((!myRemoteHost && !remoteHost) || 
	(myRemoteHost && remoteHost && [myRemoteHost isEqualToString:remoteHost])) return;
    
    myIsDirty = YES;
    [myRemoteHost release];
    myRemoteHost = [remoteHost copy];
}

- (NSString*)remoteUsername
{
    return myRemoteUsername;
}

- (void)setRemoteUsername:(NSString*)remoteUsername
{
    if ((!myRemoteUsername && !remoteUsername) || 
	(myRemoteUsername && remoteUsername && [myRemoteUsername isEqualToString:remoteUsername])) return;
    
    myIsDirty = YES;
    [myRemoteUsername release];
    myRemoteUsername = [remoteUsername copy];
}

- (NSUInteger)remotePort
{
    return myRemotePort;
}

- (void)setRemotePort:(NSUInteger)remotePort
{
    if (myRemotePort == remotePort) return;
    
    myIsDirty = YES;
    myRemotePort = remotePort;
}

- (NSDate*)remoteCreationTime
{
    return [NSDate dateWithTimeIntervalSince1970:myRemoteCreationTime];
}

- (void)setRemoteCreationTime:(NSDate*)date
{
    myRemoteCreationTime = [date timeIntervalSince1970];
}

- (NSDate*)remoteModificationTime
{
    return [NSDate dateWithTimeIntervalSince1970:myRemoteModifyTime];
}

- (void)setRemoteModificationTime:(NSDate*)date
{
    myRemoteModifyTime = [date timeIntervalSince1970];
}

- (NSData*)previewData
{
    if (!myPreviewData)
	[self performSelector:@selector(_getPreviewData) 
		     onThread:[Database databaseThread] 
		   withObject:nil 
		waitUntilDone:YES];
    return myPreviewData;
}

- (void)setPreviewData:(NSData*)data
{
    if (myPreviewData)
    {
	[myPreviewData release];
	myPreviewData = nil;
    }
    
    [self performSelector:@selector(_setPreviewData:) 
		 onThread:[Database databaseThread] 
	       withObject:data 
	    waitUntilDone:YES];
    
    myPreviewData = [data retain];
}

- (UIImage*)previewImage
{
    if (!myPreviewImage)
    {
	NSData * preview_data = [self previewData];
	if (preview_data)
	{
	    myPreviewImage = [[UIImage imageWithData:preview_data] retain];
	    
	    // To save memory, dump the preview data
	    [myPreviewData release];
	    myPreviewData = nil;
	}
    }
    return myPreviewImage;
}

- (NSData*)iconData
{
    if (!myIconData)
	[self performSelector:@selector(_getIconData) 
		     onThread:[Database databaseThread] 
		   withObject:nil 
		waitUntilDone:YES];
    return myIconData;
}

- (void)setIconData:(NSData*)data
{
    if (myIconData)
    {
	[myIconData release];
	myIconData = nil;
    }
    
    [self performSelector:@selector(_setIconData:) 
		 onThread:[Database databaseThread] 
	       withObject:data 
	    waitUntilDone:YES];
    
    myIconData = [data retain];
}

- (UIImage*)iconImage
{
    if (!myIconImage)
    {
	NSData * icon_data = [self iconData];
	if (icon_data)
	{
	    myIconImage = [[UIImage imageWithData:icon_data] retain];
	    
	    // To save memory, dump the icon data
	    [myIconData release];
	    myIconData = nil;
	}
    }
    return myIconImage;
}

- (NSString*)contentsAsString
{
    NSString * result = nil;
    NSFileHandle * handle = [NSFileHandle fileHandleForReadingAtPath:self.path];
    
    if (handle)
    {
	NSData * data = [handle readDataToEndOfFile];
	result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    
    return result;
}

- (NSData*)webArchiveData
{
    [self performSelector:@selector(_getWebArchiveData) 
		 onThread:[Database databaseThread] 
	       withObject:nil 
	    waitUntilDone:YES];
    NSData * result = myWebArchiveData;
    [myWebArchiveData autorelease];
    myWebArchiveData = nil;
    return result;
}

- (void)setWebArchiveData:(NSData*)data
{
    [self performSelector:@selector(_setWebArchiveData:) 
		 onThread:[Database databaseThread] 
	       withObject:data 
	    waitUntilDone:YES];
}

- (NSString*)mimeType
{
    NSString * uti = [Utilities utiFromFileExtension:self.fileExtension];
    if (uti)
	return [Utilities mimeTypeFromUTI:uti];
    
    return @"application/octet-stream";
}

#pragma mark Database management

#if BRIEFCASE_LITE

+ (void)_installManual
{
    // No manual for Lite users
}

#else

+ (void)_installManual
{
    // Install a copy of the user manual
    NSFileManager * file_manager = [NSFileManager defaultManager];
    NSString * path = [[NSBundle mainBundle] pathForResource:@"Briefcase Manual" ofType:@"pdf"];
    NSString * localized_name = NSLocalizedString(@"Briefcase Manual.pdf", @"The name of the file containing the manual.  This filename should be translated");
    NSString * doc_path = [[Utilities pathToDownloads] stringByAppendingPathComponent:localized_name];
    NSError * error = nil;
    [file_manager copyItemAtPath:path toPath:doc_path error:&error];
    
    if (error)
    {
	NSLog(@"Error: %@", [error localizedDescription]);
	return;
    }
    
    File * file = [File getOrCreateFileWithLocalPath:localized_name];
    NSDictionary * attributes = [file_manager attributesOfItemAtPath:doc_path error:&error];
    
    if (error)
    {
	NSLog(@"Error: %@", [error localizedDescription]);
	return;
    }
    
    file.size = [attributes objectForKey:NSFileSize];
    file.downloadComplete = YES;
    [file save];
        
    path = [[NSBundle mainBundle] pathForResource:@"icon" ofType:@"png"];
    NSData * icon_data = [NSData dataWithContentsOfFile:path];
    file.iconData = icon_data; 
}

#endif

+ (void)initializeFileDatabase
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self 
	       selector:@selector(databaseCreated:) 
		   name:kFileDatabaseCreated
		 object:nil];
    [center addObserver:self 
	       selector:@selector(databaseWillFinalize:) 
		   name:kFileDatabaseWillFinalize
		 object:nil];

    // Make sure the database is initialized
    [Database sharedDatabase];
}

+ (void)databaseCreated:(NSNotification*)notification
{
    // When a new database is created, inject our user manual
    [self _installManual];
    
}

+ (void)databaseWillFinalize:(NSNotification*)notification
{
    
    if (theInsertStatement) sqlite3_finalize(theInsertStatement);
    if (theDeleteStatement) sqlite3_finalize(theDeleteStatement);
    if (theHydrateStatement) sqlite3_finalize(theHydrateStatement);
    if (theSaveStatement) sqlite3_finalize(theSaveStatement);
    if (theIconSetStatement) sqlite3_finalize(theIconSetStatement);
    if (theIconGetStatement) sqlite3_finalize(theIconGetStatement);
    if (thePreviewSetStatement) sqlite3_finalize(thePreviewSetStatement);
    if (thePreviewGetStatement) sqlite3_finalize(thePreviewGetStatement);
    if (theWebArchiveSetStatement) sqlite3_finalize(theWebArchiveSetStatement);
    if (theWebArchiveGetStatement) sqlite3_finalize(theWebArchiveGetStatement);
    if (theIncompleteStatement) sqlite3_finalize(theIncompleteStatement);
}

@end

@implementation File (Private)

- (void)_notifyDelete:(NSString*)file_name
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kFileDeleted object:file_name];
}

+ (void)_notifyDirectoryDelete:(NSString*)dir_name
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kDirectoryDeleted object:dir_name];
}

- (void)_notifyChanged:(File*)file
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:kFileChanged object:file];
}

#pragma mark Threaded Helpers

- (void)_getOrCreateFile
{
    sqlite3 * database = [Database sharedDatabase].sqliteDatabase;
    
    if (!database)
    {
	// TODO Error handling
    }
    
    // First try to hydrate using our filename as the primary key
    [self _hydrate];
    
    if (!myIsHydrated)
    {
	// Hydrating failed, insert a new record into the database
	if (theInsertStatement == nil) {
	    static char *sql = "INSERT INTO file (local_path) VALUES(?)";
	    if (sqlite3_prepare_v2(database, sql, -1, &theInsertStatement, NULL) != SQLITE_OK) 
	    {
		NSLog(@"Error: failed to prepare statement with message '%s'.", 
		      sqlite3_errmsg(database));
	    }
	}
	
	sqlite3_bind_text(theInsertStatement, 1, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
	
	int success = sqlite3_step(theInsertStatement);
	sqlite3_reset(theInsertStatement);
	
	if (success == SQLITE_ERROR) 
	    NSLog(@"Error: failed to insert into the database with message '%s'.", 
		  sqlite3_errmsg(database));
    }
    
}

- (void)_deleteFromDatabase 
{   
    if (theDeleteStatement == nil) 
    {
        const char *sql = "DELETE FROM file WHERE local_path=?";
        if (sqlite3_prepare_v2(myDatabase, sql, -1, &theDeleteStatement, NULL) != SQLITE_OK) 
	{
            NSLog(@"Error: failed to prepare statement with message '%s'.", 
		  sqlite3_errmsg(myDatabase));
        }
    }
    
    sqlite3_bind_text(theDeleteStatement, 1, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theDeleteStatement);
    sqlite3_reset(theDeleteStatement);
    
    if (success != SQLITE_DONE) 
        NSLog(@"Error: failed to delete from database with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
}

- (void)_hydrateWithStatement:(sqlite3_stmt*)statement
{
    char * string_value;
    sqlite_int64 int64_value;
    int int_value;
    double real_value;
    const void * blob_data;
    
    [mySize release];
    int64_value = sqlite3_column_int64(statement, 0);
    mySize = [NSNumber numberWithLongLong:(long long)int64_value];
    [mySize retain];
    
    int_value = sqlite3_column_int(statement, 1);
    myIsZipped = (BOOL)int_value;
    
    int_value = sqlite3_column_int(statement, 2);
    myDownloadComplete = (BOOL)int_value;
    
    myLastViewLocation = sqlite3_column_int64(statement, 3);
    
    [myBookmarks release];
    blob_data = sqlite3_column_blob(statement, 4);
    if (blob_data)
    {
	int size = sqlite3_column_bytes(statement, 4);
	NSData * data = [[NSData alloc] initWithBytesNoCopy:(void*)blob_data 
						     length:(NSUInteger)size 
					       freeWhenDone:NO];
	myBookmarks = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
	[data release];
    }
    else
	myBookmarks = [[NSArray alloc] init];
    
    [myRemotePath release];
    string_value = (char *)sqlite3_column_text(statement, 5);
    myRemotePath = (string_value) ? [NSString stringWithUTF8String:string_value] : @"";
    [myRemotePath retain];
    
    int64_value = sqlite3_column_int64(statement, 6);
    myRemoteMode = (unsigned int)int64_value;
    
    [myRemoteHost release];
    string_value = (char *)sqlite3_column_text(statement, 7);
    myRemoteHost = (string_value) ? [NSString stringWithUTF8String:string_value] : @"";
    [myRemoteHost retain];
    
    [myRemoteUsername release];
    string_value = (char *)sqlite3_column_text(statement, 8);
    myRemoteUsername = (string_value) ? [NSString stringWithUTF8String:string_value] : @"";
    [myRemoteUsername retain];
    
    int64_value = sqlite3_column_int64(statement, 9);
    myRemotePort = (unsigned int)int64_value;
    
    real_value = sqlite3_column_double(statement, 10);
    myRemoteCreationTime = real_value;
    
    real_value = sqlite3_column_double(statement, 11);
    myRemoteModifyTime = real_value;   
    
    [myLocalPath release];
    string_value = (char *)sqlite3_column_text(statement, 12);
    myLocalPath = (string_value) ? [NSString stringWithUTF8String:string_value] : @"";
    [myLocalPath retain];   
}

- (void)_hydrate 
{
    if (theHydrateStatement == nil) 
    {
        const char *sql = "SELECT size, is_zipped, download_complete, last_position, "
	"bookmarks, remote_path, remote_mode, remote_host, remote_username, remote_port, "
	"remote_create_time, remote_modify_time, local_path "
	"FROM file WHERE local_path=?";
        if (sqlite3_prepare_v2(myDatabase, sql, -1, &theHydrateStatement, NULL) != SQLITE_OK) 
	{
            NSLog(@"Error: failed to prepare statement with message '%s'.", 
		  sqlite3_errmsg(myDatabase));
        }
    }
    
    sqlite3_bind_text(theHydrateStatement, 1, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theHydrateStatement);
    
    if (success == SQLITE_ROW) 
    {
	[self _hydrateWithStatement:theHydrateStatement];
	myIsHydrated = YES;
    } 
    else 
    {
        // The query did not return 
        self.size = [NSNumber numberWithInt:0];
	self.isZipped = NO;
	self.downloadComplete = NO;
	self.lastViewLocation = 0;
	self.bookmarks = [NSArray array];
	self.remotePath = @"";
	self.remoteMode = 0666;
	self.remoteHost = @"";
	self.remotePort = 22;
	self.remoteUsername = @"";
	self.remoteCreationTime = [NSDate date];
	self.remoteModificationTime = [NSDate date];
	myIsHydrated = NO;
    }
    
    sqlite3_reset(theHydrateStatement);
}

- (void)_save 
{
    if (theSaveStatement == nil) {
	const char *sql = "UPDATE file SET size=?, is_zipped=?,"
	"download_complete=?, last_position=?, bookmarks=?, remote_path=?, "
	"remote_mode=?, remote_host=?, remote_username=?, remote_port=?, "
	"remote_create_time=?, "
	"remote_modify_time=? WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &theSaveStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    // Bind the query variables.
    sqlite3_bind_int64(theSaveStatement, 1, [mySize longLongValue]);
    sqlite3_bind_int(theSaveStatement, 2, myIsZipped);
    sqlite3_bind_int(theSaveStatement, 3, myDownloadComplete);
    sqlite3_bind_int64(theSaveStatement, 4, myLastViewLocation);
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:myBookmarks];    
    sqlite3_bind_blob(theSaveStatement, 5, [data bytes], [data length], SQLITE_TRANSIENT);
    
    sqlite3_bind_text(theSaveStatement, 6, [myRemotePath UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(theSaveStatement, 7, myRemoteMode);
    sqlite3_bind_text(theSaveStatement, 8, [myRemoteHost UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(theSaveStatement, 9, [myRemoteUsername UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(theSaveStatement, 10, myRemotePort);
    sqlite3_bind_double(theSaveStatement, 11, myRemoteCreationTime);
    sqlite3_bind_double(theSaveStatement, 12, myRemoteModifyTime);
    sqlite3_bind_text(theSaveStatement, 13, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theSaveStatement);
    sqlite3_reset(theSaveStatement);
    if (success != SQLITE_DONE) {
	NSLog(@"Error: failed to save File record to database with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
    // Update the object state with respect to unwritten changes.
    myIsDirty = NO;
}

- (void)_setIconData:(NSData*)data
{
    if (theIconSetStatement == nil) {
	const char *sql = "UPDATE file SET icon=? WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &theIconSetStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    
    sqlite3_bind_blob(theIconSetStatement, 1, [data bytes], [data length], SQLITE_TRANSIENT);
    sqlite3_bind_text(theIconSetStatement, 2, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theIconSetStatement);
    sqlite3_reset(theIconSetStatement);
    if (success != SQLITE_DONE) {
	NSLog(@"Error: failed to save icon data with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
} 

- (void)_getIconData
{
    [myIconData release];
    myIconData = nil;
    
    if (theIconGetStatement == nil) {
	const char *sql = "SELECT icon FROM file WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &theIconGetStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    
    sqlite3_bind_text(theIconGetStatement, 1, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theIconGetStatement);
    
    if (success != SQLITE_ROW) {
	NSLog(@"Error: failed to load icon data with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
    
    const void * data = sqlite3_column_blob(theIconGetStatement, 0);
    if (data)
    {
	int size = sqlite3_column_bytes(theIconGetStatement, 0);
	myIconData = [NSData dataWithBytes:data length:(NSUInteger)size];
	[myIconData retain];
    }
    
    sqlite3_reset(theIconGetStatement);
}

- (void)_setPreviewData:(NSData*)data
{
    [myPreviewData release];
    myPreviewData = [data retain];
    
    if (thePreviewSetStatement == nil) {
	const char *sql = "UPDATE file SET preview=? WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &thePreviewSetStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    
    sqlite3_bind_blob(thePreviewSetStatement, 1, [data bytes], [data length], SQLITE_TRANSIENT);
    sqlite3_bind_text(thePreviewSetStatement, 2, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(thePreviewSetStatement);
    sqlite3_reset(thePreviewSetStatement);
    if (success != SQLITE_DONE) {
	NSLog(@"Error: failed to save preview data with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
} 

- (void)_getPreviewData
{
    [myPreviewData release];
    myPreviewData = nil;
    
    if (thePreviewGetStatement == nil) {
	const char *sql = "SELECT preview FROM file WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &thePreviewGetStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    
    sqlite3_bind_text(thePreviewGetStatement, 1, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(thePreviewGetStatement);
    
    if (success != SQLITE_ROW) {
	NSLog(@"Error: failed to save preview data with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
    
    const void * data = sqlite3_column_blob(thePreviewGetStatement, 0);
    if (data)
    {
	int size = sqlite3_column_bytes(thePreviewGetStatement, 0);
	myPreviewData = [NSData dataWithBytes:data length:(NSUInteger)size];
	[myPreviewData retain];
    }
    
    sqlite3_reset(thePreviewGetStatement);
}

- (void)_setWebArchiveData:(NSData*)data
{
    [myWebArchiveData release];
    myWebArchiveData = nil;
    
    if (theWebArchiveSetStatement == nil) {
	const char *sql = "UPDATE file SET webarchive=? WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &theWebArchiveSetStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    
    sqlite3_bind_blob(theWebArchiveSetStatement, 1, [data bytes], [data length], SQLITE_TRANSIENT);
    sqlite3_bind_text(theWebArchiveSetStatement, 2, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theWebArchiveSetStatement);
    sqlite3_reset(theWebArchiveSetStatement);
    if (success != SQLITE_DONE) {
	NSLog(@"Error: failed to save webarchive data with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
} 

- (void)_getWebArchiveData
{
    [myWebArchiveData release];
    myWebArchiveData = nil;
    
    if (theWebArchiveGetStatement == nil) {
	const char *sql = "SELECT webarchive FROM file WHERE local_path=?";
	if (sqlite3_prepare_v2(myDatabase, sql, -1, &theWebArchiveGetStatement, NULL) != SQLITE_OK) 
	{
	    NSLog(@"Error: failed to prepare statement with message '%s'.",
		  sqlite3_errmsg(myDatabase));
	}
    }
    
    sqlite3_bind_text(theWebArchiveGetStatement, 1, [myLocalPath UTF8String], -1, SQLITE_TRANSIENT);
    
    int success = sqlite3_step(theWebArchiveGetStatement);
    
    if (success != SQLITE_ROW) {
	NSLog(@"Error: failed to save webarchive data with message '%s'.", 
	      sqlite3_errmsg(myDatabase));
    }
    
    const void * data = sqlite3_column_blob(theWebArchiveGetStatement, 0);
    if (data)
    {
	int size = sqlite3_column_bytes(theWebArchiveGetStatement, 0);
	myWebArchiveData = [NSData dataWithBytes:data length:(NSUInteger)size];
	[myWebArchiveData retain];
    }
    
    sqlite3_reset(theWebArchiveGetStatement);
}

@end

NSInteger fileSortFunction(id item1, id item2, void * context)
//
//  Sort list of File objects and NSStrings
//
{
    NSString * string1, * string2;
    
    if ([item1 isKindOfClass:[NSString class]])
	string1 = item1;
    else
	string1 = [(File*)item1 fileName];
    
    if ([item2 isKindOfClass:[NSString class]])
	string2 = item2;
    else
	string2 = [(File*)item2 fileName];
    
    return [string1 compare:string2 options:NSCaseInsensitiveSearch];
}
