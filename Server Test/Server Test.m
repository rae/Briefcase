#import <Foundation/Foundation.h>

#import "ConnectionServer.h"
#import "TestServerDelegate.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    TestServerDelegate * delegate = [[TestServerDelegate alloc] init];
    
    [ConnectionServer startServerWithDelegate:delegate];
    
    while (TRUE) 
    {
	sleep(2);
	NSDate * until = [NSDate distantFuture];
	[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
    }
    
    [pool drain];
    return 0;
}
