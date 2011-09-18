//
// Glitch Run
//
// Copyright 2011 Tiny Speck, Inc.
// Created by David Wilkinson.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License. 
//
// See more about Glitch at http://www.glitch.com
// http://www.tinyspeck.com
//


#import "GlitchAvatarData.h"
#import "GlitchSpriteSheet.h"
#import "GlitchAnimation.h"
#import "GlitchAvatarAnimationFrame.h"

@interface GlitchAvatarData ()

@property (nonatomic, retain) GlitchAnimationSet *animationSet;
@property (retain, nonatomic) NSMutableDictionary *animations;
@property (retain, nonatomic) NSMutableDictionary *imageTokens;
@property (retain, nonatomic) NSMutableDictionary *spritesheets;
@property (retain, nonatomic) NSMutableDictionary *frames;
@property (retain, nonatomic) NSObject<GlitchAvatarDataDelegate> *delegate;
@property (retain, nonatomic) NSFileManager *fileManager;
@property (copy, nonatomic) NSString *avatarDataDirectory;

@end

@implementation GlitchAvatarData

@synthesize animationSet = _animationSet;
@synthesize animations = _animations;
@synthesize imageTokens = _imageTokens;
@synthesize spritesheets = _spritesheets;
@synthesize frames = _frames;
@synthesize delegate = _delegate;
@synthesize fileManager = _fileManager;
@synthesize avatarDataDirectory = _avatarDataDirectory;

- (id)init
{
    self = [super init];
    if (self) 
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		self.avatarDataDirectory = [documentsDirectory stringByAppendingPathComponent:@"GlitchAvatarData"];

		NSFileManager *fm = [[NSFileManager alloc] init];
		self.fileManager = fm;
		[fm release];
		
		if (![self.fileManager fileExistsAtPath:self.avatarDataDirectory])
		{
			[self.fileManager createDirectoryAtPath:self.avatarDataDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		}
        
        self.animations = [NSMutableDictionary dictionaryWithCapacity:12];
        self.imageTokens = [NSMutableDictionary dictionaryWithCapacity:12];
        self.frames = [NSMutableDictionary dictionaryWithCapacity:100];
        self.spritesheets = [NSMutableDictionary dictionaryWithCapacity:12]; 
    }
    
    return self;
}


-(void)dealloc
{
    [_animationSet release];
    _animationSet = nil;
    
    [_animations removeAllObjects];
    [_animations release];
    _animations = nil;
    
    [_imageTokens removeAllObjects];
    [_imageTokens release];
    _imageTokens = nil;
    
    [_fileManager release];
    _fileManager = nil;
    
    for (NSValue *v in [_spritesheets allValues])
    {
        CGImageRef imageRef = [v pointerValue];
        if (imageRef != NULL)
        {
            CGImageRelease(imageRef);
        }
    }
    [_spritesheets release];
    _spritesheets = nil;
    
    [_avatarDataDirectory release];
    _avatarDataDirectory = nil;
    
    [super dealloc];
}

#pragma mark - Animations

-(void)checkIfAllSpriteSheetsLoaded
{
   if ([self.imageTokens count] == 0)
   {
       // No outstanding requests, we must have everything
       if (self.delegate)
       {
           [self.delegate glitchAvatarDataLoaded:self];
       }
   }
}

-(void)loadFromAnimationSet:(GlitchAnimationSet *)theAnimationSet withDelegate:(NSObject<GlitchAvatarDataDelegate> *)theDelegate
{
    self.delegate = theDelegate;
    self.animationSet = theAnimationSet;
    
    // Load all the images
    for (NSString *name in self.animationSet.spritesheets)
    {
        NSLog(@"Loading spritesheet %@", name);
        GlitchSpriteSheet *ss = [self.animationSet.spritesheets objectForKey:name];
        DZDataLoadToken token = [[DZDataLoader sharedDataLoader] loadData:[NSURL URLWithString:ss.url] withDelegate:self];
        // Store the token away so that when we get the response, we know which spritesheet it is for
        [self.imageTokens setObject:name forKey:[NSNumber numberWithInteger:token]];
    }
    [self checkIfAllSpriteSheetsLoaded];
}


-(NSArray *)framesForAnimationName:(NSString *)name
{
    NSMutableArray *f = [self.animations objectForKey:name];
    if (f == nil)
    {
        GlitchAnimation *animation = [self.animationSet.animations objectForKey:name];
        if (animation)
        {
            NSArray *frameList = animation.frames;
            if (frameList)
            {
                f = [NSMutableArray arrayWithCapacity:[frameList count]];
                for (NSNumber *frameNumber in frameList) 
                {
                    GlitchAvatarAnimationFrame *frame = [self.frames objectForKey:frameNumber];
                    [f addObject:frame];
                }
                [self.animations setObject:f forKey:name];
            }
        }
    }
    return f;
}

-(CGImageRef)spritesheetForName:(NSString *)name
{
    // TODO lazy loading
    return [(NSValue *)[self.spritesheets objectForKey:name] pointerValue];
}

-(CCAnimation *)animationForName:(NSString *)name
{
    NSString *animationName = [NSString stringWithFormat:@"avatar-%@", name];
    CCAnimation *animation = [[CCAnimationCache sharedAnimationCache] animationByName:animationName];
    if (animation == nil)
    {
        NSArray *frames = [self framesForAnimationName:name];
        animation = [CCAnimation animation];
        for (GlitchAvatarAnimationFrame *f in frames)
        {
            NSString *frameName = [NSString stringWithFormat:@"avatar-frame-%d", [f->frameNumber integerValue]];
            CCTexture2D *texture = [[CCTextureCache sharedTextureCache] textureForKey:frameName];
            CGRect frameRect = f->frame;
            if (texture == nil)
            {
                CGImageRef spritesheet = [self spritesheetForName:f->sheetName];
                CGImageRef frameRef = CGImageCreateWithImageInRect(spritesheet, frameRect);
                texture = [[CCTextureCache sharedTextureCache] addCGImage:frameRef forKey:frameName];
                CGImageRelease(frameRef);
            }
            CGRect rect = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
            [animation addFrameWithTexture:texture rect:rect];
        }
    }
    return animation;
}

-(CCTexture2D *)defaultTexture
{
    CCAnimation *animation = [self animationForName:@"idle0"];
    NSArray *frames = animation.frames;
    CCSpriteFrame *frame = [frames objectAtIndex:0];
    return frame.texture;
}

#pragma mark - DZDataLoaderDelegate 

-(void)dataLoaded:(NSData *)data forToken:(DZDataLoadToken)token
{
    // Which spritesheet is this?
    NSNumber *key = [NSNumber numberWithInteger:token];
    NSString *name = [self.imageTokens objectForKey:key];
    if (name)
    {
        NSString *path = [self.avatarDataDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
        [self.fileManager createFileAtPath:path contents:data attributes:nil];
		
        GlitchSpriteSheet *ss = [self.animationSet.spritesheets objectForKey:name];
        CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)data);
        CGImageRef imageRef = CGImageCreateWithPNGDataProvider(dataProvider, NULL, false, kCGRenderingIntentDefault);
        size_t sheetHeight = CGImageGetHeight(imageRef);
        size_t sheetWidth = CGImageGetWidth(imageRef);
        size_t frameHeight = sheetHeight/ss.rows;
        size_t frameWidth = sheetWidth/ss.columns;
        
        [self.spritesheets setObject:[NSValue valueWithPointer:CGImageRetain(imageRef)] forKey:name];

        int row = 0;
        int col = 0;
        for (NSNumber *frameNumber in ss.frames)
        {
            // Work out which rectangle of the image is needed for the frame and store it for later use
            CGRect f = CGRectMake(col * frameWidth, row * frameHeight, frameWidth, frameHeight);
            [self.frames setObject:[GlitchAvatarAnimationFrame frameWithSheetName:name frameNumber:frameNumber frame:f] forKey:frameNumber];
            
            if (++col >= ss.columns)
            {
                col = 0;
                row++;
            }
        }
        CGDataProviderRelease(dataProvider);
        CGImageRelease(imageRef);
        [self.imageTokens removeObjectForKey:key];
        [self checkIfAllSpriteSheetsLoaded];
    }
}

-(void)dataLoadFailedWithError:(NSError *)error forToken:(DZDataLoadToken)token
{
    // TODO - Need to report the error
    NSNumber *key = [NSNumber numberWithInteger:token];
    [self.imageTokens removeObjectForKey:key];
    [self checkIfAllSpriteSheetsLoaded];
}


@end
