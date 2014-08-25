//
//  YBMyScene.h
//  YeezyBird
//

//  Copyright (c) 2014 Builtby Destiny. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@protocol YBMySceneDelegate
- (UIImage *)screenshot;
- (void)shareString:(NSString *)string url:(NSURL*)url image:(UIImage *)screenshot;
@end

typedef NS_ENUM(int, gameState)
{
    gameStateMainMenu,
    gameStateTutorial,
    gameStatePlay,
    gameStateFalling,
    gameStateShowingScore,
    gameStateGameOver
};

@interface YBMyScene : SKScene

-(id)initWithSize:(CGSize)size delegate:(id<YBMySceneDelegate>)delegate state:(gameState)state;

@property (strong, nonatomic) id<YBMySceneDelegate> delegate;

@end
