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


#import "GlitchSpriteSheet.h"

@implementation GlitchSpriteSheet

@synthesize name = _name;
@synthesize columns = _columns;
@synthesize rows = _rows;
@synthesize frames = _frames;
@synthesize url = _url;

- (id)init
{
    self = [super init];
    if (self) 
    {
        // Initialization code here.
    }
    
    return self;
}

-(void)dealloc
{
    [_name release];
    _name = nil;
    
    [_frames release];
    _frames = nil;
    
    [_url release];
    _url = nil;
    
    [super dealloc];
}

@end
