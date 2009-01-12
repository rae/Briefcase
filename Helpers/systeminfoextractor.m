#import <Cocoa/Cocoa.h>

int main(int argc, char ** argv)
{
    [NSApplication sharedApplication];
    [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:NSTemporaryDirectory() forKey:@"temp dir"];
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    
    fwrite([data bytes], [data length], 1, stdout);
    
    return 0;
}