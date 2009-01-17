//
//  untitled.m
//  Briefcase
//
//  Created by Michael Taylor on 27/12/08.
//  Copyright 2008 Hey Mac Software. All rights reserved.
//

#import "Database.h"
#import "File.h"

static sqlite3 *      theFileDatabase		= nil;
static WorkerThread * theDatabaseThread		= nil;

NSString * kFileDatabaseWillFinalize = @"File Database Finalize";
NSString * kFileDatabaseCreated = @"File Database Created";

static const int database_version = 2;

@implementation Database

+ (void)_raiseException:(NSString*)reason
{
    NSException * exception = [NSException exceptionWithName:NSLocalizedString(@"Database Operation Error", @"Title for dialogs that show error messages about failed database operations")
						      reason:reason
						    userInfo:nil];
    @throw exception;
}

+ (BOOL)createEditableCopyOfDatabaseIfNeeded 
{
    BOOL success;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *  error;
    NSArray *  paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * writableDBPath;
    
    writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"fileDatabase.sql"];
    
    if ([fileManager fileExistsAtPath:writableDBPath]) return FALSE;
    
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"fileDatabase.sql"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    
    if (!success)
        NSLog(@"Failed to create writable database file with message '%@'.", 
	      [error localizedDescription]);
    
    return success;
}

+ (void)runSQL:(NSString*)sql
{
    sqlite3_stmt * sql_statement = NULL;
    if (sqlite3_prepare_v2(theFileDatabase, [sql UTF8String], -1, &sql_statement, NULL) == SQLITE_OK) 
    {
	int success = sqlite3_step(sql_statement);
	
	sqlite3_finalize(sql_statement);
	
	if (success != SQLITE_DONE) 
	{
	    NSString * message = [NSString stringWithFormat:@"Failed to execute sql '%s'",
				  sqlite3_errmsg(theFileDatabase)];
	    [self _raiseException:message];
	}
    }
    else
    {
	NSString * message = [NSString stringWithFormat:@"Failed to prepare database statement '%s'",
			      sqlite3_errmsg(theFileDatabase)];
	[self _raiseException:message];
    }
    
}

+ (void)upgradeDatabaseFromVersion:(int)current_version
{
    if (current_version < 2)
    {
	// Add column for remote port number
	[self runSQL:@"ALTER TABLE file ADD COLUMN remote_port INTEGER"];
	// Add column for pre-rendered HTML
	[self runSQL:@"ALTER TABLE file ADD COLUMN webarchive BLOB"];
	// Add port value of 22 for all existing files
	[self runSQL:@"UPDATE file SET remote_port = 22"];
    }
    
    // Set new version number
    [self runSQL:@"DELETE FROM version"];
    NSString * version_string = [NSString stringWithFormat:@"INSERT INTO version VALUES(%d,0);",
				 database_version];
    [self runSQL:version_string];
}

+ (sqlite3 *)sharedDatabase
{
    if (!theFileDatabase)
    {
	@try
	{
	    NSArray  * paths;
	    NSString * documents_directory;
	    NSString * path;
	    
	    BOOL created = [Database createEditableCopyOfDatabaseIfNeeded];
	    
	    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
							NSUserDomainMask, YES);
	    documents_directory = [paths objectAtIndex:0];
	    path = [documents_directory stringByAppendingPathComponent:@"fileDatabase.sql"];
	    
	    if (!sqlite3_open([path UTF8String], &theFileDatabase) == SQLITE_OK) 
	    {
		// Even though the open failed, call close to properly clean up resources.
		sqlite3_close(theFileDatabase);
		NSLog(@"Failed to open database with message '%s'.", 
		      sqlite3_errmsg(theFileDatabase));
		theFileDatabase = nil;
		// TODO: More error handling?
	    }
	    
	    // Start the database thread
	    theDatabaseThread = [[WorkerThread alloc] init];
	    [theDatabaseThread start];
	    
	    // Check if we need to upgrade
	    const char *sql = "SELECT major, minor FROM version";
	    sqlite3_stmt * version_statement = NULL;
	    if (sqlite3_prepare_v2(theFileDatabase, sql, -1, &version_statement, NULL) == SQLITE_OK) 
	    {
		int success = sqlite3_step(version_statement);
		
		if (success == SQLITE_ROW) 
		{
		    int major = sqlite3_column_int(version_statement, 0);
		    
		    sqlite3_finalize(version_statement);
		    
		    if (major < database_version)
			[self upgradeDatabaseFromVersion:major];
		}
		else
		{
		    sqlite3_finalize(version_statement);
		    NSString * message = [NSString stringWithFormat:@"Failed to read database version '%s'",
					  sqlite3_errmsg(theFileDatabase)];
		    [self _raiseException:message];
		}
	    }
	    else
	    {
		NSString * message = [NSString stringWithFormat:@"Failed to prepare database statement '%s'",
				      sqlite3_errmsg(theFileDatabase)];
		[self _raiseException:message];
	    }
	    
	    if (created)
	    {
		NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
		[center postNotificationName:kFileDatabaseCreated object:nil];
	    }
	}
	@catch (NSException * e) {
	    UIAlertView *alert = 
	    alert = [[UIAlertView alloc] initWithTitle:[e name] 
					       message:[e reason]
					      delegate:nil 
				     cancelButtonTitle:NSLocalizedString(@"OK", @"Label for OK button") 
				     otherButtonTitles:nil];
	    [alert show];	
	    [alert release];
	}
	
    }
    return theFileDatabase;
}

+ (void)finalizeDatabase
{
    if (theFileDatabase)
    {
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:kFileDatabaseWillFinalize object:nil];
	if (sqlite3_close(theFileDatabase) != SQLITE_OK) {
	    NSLog(@"Error: failed to close database with message '%s'.", 
		  sqlite3_errmsg(theFileDatabase));
	}
    }
    if (theDatabaseThread)
    {
	[theDatabaseThread cancel];
	[theDatabaseThread release];
    }
}

+ (WorkerThread *)databaseThread
{
    return theDatabaseThread;
}

@end
