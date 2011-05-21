//
//  DeviceInfoViewController.m
//  DeviceInfo
//
//  Created by Tang Xiaoping on 5/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DeviceInfoViewController.h"

#import <stdio.h>
#import <string.h>

#import <mach/mach_host.h>
#import <sys/sysctl.h>

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>
#include <ifaddrs.h>
#include <string.h>
#include <stdbool.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

@implementation DeviceInfoViewController


//reference:http://furbo.org/2007/08/21/what-the-iphone-specs-dont-tell-you
- (void)printMemoryInfo
{
	size_t length;
	int mib[6]; 
	int result;
	
	printf("Memory Info\n");
	printf("-----------\n");
	
	int pagesize;
	mib[0] = CTL_HW;
	mib[1] = HW_PAGESIZE;
	length = sizeof(pagesize);
	if (sysctl(mib, 2, &pagesize, &length, NULL, 0) < 0)
	{
		perror("getting page size");
	}
	printf("Page size = %d bytes\n", pagesize);
	printf("\n");
	
	mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
	
	vm_statistics_data_t vmstat;
	if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS)
	{
		printf("Failed to get VM statistics.");
	}
	
	double total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
	double wired = vmstat.wire_count / total;
	double active = vmstat.active_count / total;
	double inactive = vmstat.inactive_count / total;
	double free = vmstat.free_count / total;
	
	printf("Total =    %8d pages\n", vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count);
	printf("\n");
	printf("Wired =    %8d bytes\n", vmstat.wire_count * pagesize);
	printf("Active =   %8d bytes\n", vmstat.active_count * pagesize);
	printf("Inactive = %8d bytes\n", vmstat.inactive_count * pagesize);
	printf("Free =     %8d bytes\n", vmstat.free_count * pagesize);
	printf("\n");
	printf("Total =    %8d bytes\n", (vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count) * pagesize);
	printf("\n");
	printf("Wired =    %0.2f %%\n", wired * 100.0);
	printf("Active =   %0.2f %%\n", active * 100.0);
	printf("Inactive = %0.2f %%\n", inactive * 100.0);
	printf("Free =     %0.2f %%\n", free * 100.0);
	printf("\n");
	
	mib[0] = CTL_HW;
	mib[1] = HW_PHYSMEM;
	length = sizeof(result);
	if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
	{
		perror("getting physical memory");
	}
	printf("Physical memory = %8d bytes\n", result);
	mib[0] = CTL_HW;
	mib[1] = HW_USERMEM;
	length = sizeof(result);
	if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
	{
		perror("getting user memory");
	}
	printf("User memory =     %8d bytes\n", result);
	printf("\n");
}

- (void)printProcessorInfo
{
	size_t length;
	int mib[6]; 
	int result;
	
	printf("Processor Info\n");
	printf("--------------\n");
	
	mib[0] = CTL_HW;
	mib[1] = HW_CPU_FREQ;
	length = sizeof(result);
	if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
	{
		perror("getting cpu frequency");
	}
	printf("CPU Frequency = %d hz\n", result);
	
	mib[0] = CTL_HW;
	mib[1] = HW_BUS_FREQ;
	length = sizeof(result);
	if (sysctl(mib, 2, &result, &length, NULL, 0) < 0)
	{
		perror("getting bus frequency");
	}
	printf("Bus Frequency = %d hz\n", result);
	printf("\n");
}

//reference:http://forums.macrumors.com/showthread.php?t=474628
- (int)printBatteryInfo
{
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
	
	CFDictionaryRef pSource = NULL;
	const void *psValue;
	
	int numOfSources = CFArrayGetCount(sources);
	if (numOfSources == 0) {
		perror("Error getting battery info");
		return 1;
	}
	
	printf("Battery Info\n");
	printf("------------\n");
	
	for (int i = 0 ; i < numOfSources ; i++)
	{
		pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
		if (!pSource) {
			perror("Error getting battery info");
			return 2;
		}
		psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));
		
		int curCapacity = 0;
		int maxCapacity = 0;
		int percent;
		
		psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
		CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
		
		psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
		CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
		
		percent = (int)((double)curCapacity/(double)maxCapacity * 100);
		
		printf ("powerSource %d of %d: percent: %d/%d = %d%%\n", i+1, CFArrayGetCount(sources), curCapacity, maxCapacity, percent);
		printf("\n");
		
	}
	
}

- (int)printProcessInfo {
    int mib[5];
    struct kinfo_proc *procs = NULL, *newprocs;
    int i, st, nprocs;
    size_t miblen, size;
	
    /* Set up sysctl MIB */
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;
    mib[3] = 0;
    miblen = 4;
	
    /* Get initial sizing */
    st = sysctl(mib, miblen, NULL, &size, NULL, 0);
	
    /* Repeat until we get them all ... */
    do {
        /* Room to grow */
        size += size / 10;
        newprocs = realloc(procs, size);
        if (!newprocs) {
            if (procs) {
                free(procs);
            }
            perror("Error: realloc failed.");
            return (0);
        }
        procs = newprocs;
        st = sysctl(mib, miblen, procs, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
	
    if (st != 0) {
        perror("Error: sysctl(KERN_PROC) failed.");
        return (0);
    }
	
    /* Do we match the kernel? */
    assert(size % sizeof(struct kinfo_proc) == 0);
	
    nprocs = size / sizeof(struct kinfo_proc);
	
    if (!nprocs) {
        perror("Error: printProcessInfo.");
        return(0);
    }
    printf("  PID\tName\n");
    printf("-----\t--------------\n");
    for (i = nprocs-1; i >=0;  i--) {
		printf("%5d\t%s\n",(int)procs[i].kp_proc.p_pid, procs[i].kp_proc.p_comm);
    }
    free(procs);
    return (0);
}


- (void)getInfo
{
	printf("iPhone Hardware Info\n");
	printf("====================\n");
	printf("\n");
	
	[self printMemoryInfo];
	[self printProcessorInfo];
	[self printBatteryInfo];
	[self printProcessInfo];
}




#if ! defined(IFT_ETHER)
#define IFT_ETHER 0x6/* Ethernet CSMACD */
#endif

- (void) getNetWorkInfo
{
	bool success;
	struct ifaddrs *addrs;
	const struct ifaddrs *cursor;
	const struct sockaddr_dl *dlAddr;
	const uint8_t *base;
	int i;
	
	success = getifaddrs(&addrs) == 0;
	if (success) {
		cursor = addrs;
		while (cursor != NULL) {
			if ((cursor->ifa_flags & IFF_LOOPBACK) == 0 ) {
				printf("%s ", (char *)cursor->ifa_name);
				printf("%s\n",inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr));
			}
			if ( (cursor->ifa_addr->sa_family == AF_LINK)
				&& (((const struct sockaddr_dl *) cursor->ifa_addr)->sdl_type ==IFT_ETHER)
				) {
				dlAddr = (const struct sockaddr_dl *) cursor->ifa_addr;
				//      fprintf(stderr, " sdl_nlen = %d\n", dlAddr->sdl_nlen);
				//      fprintf(stderr, " sdl_alen = %d\n", dlAddr->sdl_alen);
				base = (const uint8_t *) &dlAddr->sdl_data[dlAddr->sdl_nlen];
				printf(" MAC address ");
				for (i = 0; i < dlAddr->sdl_alen; i++) {
					if (i != 0) {
						printf(":");
					}
					printf("%02x", base[i]);
				} 
				printf("\n");
			}
			cursor = cursor->ifa_next;
		}
	}
}


//reference:UIDevice
- (void)getDeviceInfo
{
	UIDevice *device = [UIDevice currentDevice];
	NSLog(@"Device name  is:%@", [device name]);
	NSLog(@"Device model is:%@", [device model]);
	NSLog(@"Device localizedModel is:%@", [device localizedModel]);
	NSLog(@"Device systemName is:%@", [device systemName]);
	NSLog(@"Device systemVersion is:%@", [device systemVersion]);
	NSLog(@"Device uniqueIdentifier is:%@", [device uniqueIdentifier]);
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	//[self getInfo];
	//[self getNetWorkInfo];
	[self getDeviceInfo];
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
