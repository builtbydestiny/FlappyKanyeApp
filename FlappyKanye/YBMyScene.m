//
//  YBMyScene.m
//  YeezyBird
//
//  Created by APPENGINE on 02/08/2014.
//  Copyright (c) 2014 Builtby Destiny. All rights reserved.
//

#import "YBMyScene.h"

@interface YBMyScene () <SKPhysicsContactDelegate>
@end

typedef NS_ENUM(int, Layer)
{
    LayerBG,
    LayerScore,
    LayerObstacle,
    LayerFG,
    LayerPlayer,
    LayerUI
};

typedef NS_OPTIONS(int, EntityCategory)
{
    EntityCategoryPlayer = 1 << 0,
    EntityCategoryObstacle = 1 << 1,
    EntityCategoryGround = 1 << 2
};

// Gameplay - Movement
static const float kGravity = -1500.0;
static const float kImpulse = 400;
static const int kNumberofFG = 2;
static const int kNumberOfBirdFrames = 4;
static const float kAngularVelocity = 100;

// Gameplay - max tap frequency
static const float kGroundSpeed = 150.0f;

static const float kGapMultiplier = 2.4;
static const float kBottomObstacleMinFraction = 0.1;
static const float kBottomObstacleMaxFraction = 0.6;

// Looping Methods
static const float kLoopFirstObstacleDelay = 1.75;
static const float kLoopEveryObstacleDelay = 1.5;

// UI Constants
static const int kNumForegrounds = 2;
static const float kMargin = 20.0;
static NSString *kFontName = @"AmericanTypewriter-Bold";
static const float kAnimDelay = 0.3;
static const float kDegreesMin = -90;
static const float kDegreesMax = 25;

// Appstore Id
static const int APP_STORE_ID = 909008591;


@implementation YBMyScene
{
    SKNode *_globalNode;
    
    SKSpriteNode *_player;
    SKSpriteNode *_sombrero;
    
    CGPoint _playerVelocity;
    float _playerAngularVelocity;
    
    NSTimeInterval _lastTouchTime;
    float _lastTouchY;
    
    float _playStart;
    float _playHeight;
    
    // Time intervals
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    
    // GameState
    gameState _gameState;
    BOOL _hitGround;
    BOOL _hitObstacle;
    
    // Gamescore
    SKLabelNode *_scoreLabel;
    int _gameScore;
    
    // Sounds
    SKAction * _dingAction;
    SKAction * _flapAction;
    SKAction * _whackAction;
    SKAction * _fallingAction;
    SKAction * _hitGroundAction;
    SKAction * _popAction;
    SKAction * _coinAction;
    SKAction *_introSong;
    
}

-(id)initWithSize:(CGSize)size delegate:(id<YBMySceneDelegate>)delegate state:(gameState)state {
    
    if (self = [super initWithSize:size]) {

        _delegate = delegate;
        
        _globalNode = [SKNode node];
        
        [self addChild:_globalNode];
        
        //self.backgroundColor = [SKColor colorWithRed:0.816 green:0.824 blue:0.843 alpha:1.0];
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        if (state == gameStateMainMenu) {
            [self switchToMainMenu];
        } else if (state == gameStateTutorial) {
            [self switchToTutorial];
        }
    }
    return self;
}

#pragma mark - Setup Methods

- (void)setupBG
{
   SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"landscape"];
    bg.anchorPoint = CGPointMake(0.5, 1);
    bg.position = CGPointMake(self.size.width / 2, self.size.height);
    bg.zPosition = LayerBG;
    [_globalNode addChild:bg];
    
    _playStart = self.size.height - bg.size.height;
    _playHeight = bg.size.height;
    
    CGPoint lowerLeft = CGPointMake(0,_playStart);
    CGPoint lowerRight = CGPointMake(self.size.width, _playStart);
    
    self.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:lowerLeft toPoint:lowerRight];
    [self skt_attachDebugLineFromPoint:lowerLeft toPoint:lowerRight
                                 color:[UIColor clearColor]];
    
    self.physicsBody.categoryBitMask = EntityCategoryGround;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = EntityCategoryPlayer;
}

- (void)setupFG
{
    for (int i = 0; i < kNumberofFG; ++i) {
        SKSpriteNode *fg = [SKSpriteNode spriteNodeWithImageNamed:@"foreGround"];
        fg.anchorPoint = CGPointMake(0, 1);
        fg.position = CGPointMake(i * self.size.width, _playStart);
        fg.zPosition = LayerFG;
        fg.name = @"Foreground";
        [_globalNode addChild:fg];
    }
}

- (void)setupPlayer
{
    _player = [SKSpriteNode spriteNodeWithImageNamed:@"bird1"];
    _player.position = CGPointMake(self.size.width * 0.2, _playHeight * 0.4 + _playStart);
    _player.zPosition = LayerPlayer;
    [_globalNode addChild:_player];
    
    CGFloat offsetX = _player.frame.size.width * _player.anchorPoint.x;
    CGFloat offsetY = _player.frame.size.height * _player.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 16 - offsetX, 33 - offsetY);
    CGPathAddLineToPoint(path, NULL, 2 - offsetX, 27 - offsetY);
    CGPathAddLineToPoint(path, NULL, 3 - offsetX, 23 - offsetY);
    CGPathAddLineToPoint(path, NULL, 0 - offsetX, 21 - offsetY);
    CGPathAddLineToPoint(path, NULL, 18 - offsetX, 11 - offsetY);
    CGPathAddLineToPoint(path, NULL, 32 - offsetX, 1 - offsetY);
    CGPathAddLineToPoint(path, NULL, 44 - offsetX, 2 - offsetY);
    CGPathAddLineToPoint(path, NULL, 48 - offsetX, 12 - offsetY);
    CGPathAddLineToPoint(path, NULL, 52 - offsetX, 25 - offsetY);
    CGPathAddLineToPoint(path, NULL, 54 - offsetX, 27 - offsetY);
    CGPathAddLineToPoint(path, NULL, 53 - offsetX, 30 - offsetY);
    CGPathAddLineToPoint(path, NULL, 51 - offsetX, 32 - offsetY);
    CGPathAddLineToPoint(path, NULL, 48 - offsetX, 40 - offsetY);
    CGPathAddLineToPoint(path, NULL, 43 - offsetX, 44 - offsetY);
    
    CGPathCloseSubpath(path);
    
    _player.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    
    _player.physicsBody.categoryBitMask = EntityCategoryPlayer;
    _player.physicsBody.collisionBitMask = 0;
    _player.physicsBody.contactTestBitMask = EntityCategoryObstacle | EntityCategoryGround;
    
    SKAction *moveUp = [SKAction moveByX:0 y:10 duration:0.4];
    moveUp.timingMode = SKActionTimingEaseInEaseOut;
    SKAction *moveDown = [moveUp reversedAction];
    SKAction *sequence = [SKAction sequence:@[moveUp, moveDown]];
    SKAction *repeat = [SKAction repeatActionForever:sequence];
    [_player runAction:repeat withKey:@"Wobble"];
    
}

- (void)updateForeground
{
    [_globalNode enumerateChildNodesWithName:@"Foreground"
                                  usingBlock:^(SKNode *node, BOOL *stop) {
        
        SKSpriteNode *foreground = (SKSpriteNode *)node;
        CGPoint moveAmt = CGPointMake(-kGroundSpeed * _dt,0);
        foreground.position = CGPointAdd(foreground.position, moveAmt);
        
        if (foreground.position.x < -foreground.size.width) {
            foreground.position = CGPointAdd(foreground.position, CGPointMake(foreground.size.width * kNumForegrounds, 0));
        }
    }];
}

- (void)setupMainMenu
{
    SKSpriteNode *logo = [SKSpriteNode spriteNodeWithImageNamed:@"Logo"];
    logo.position = CGPointMake(self.size.width/2, self.size.height - (kMargin * 5));
    logo.zPosition = LayerUI;
    [_globalNode addChild:logo];
    
    // Play button
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"play"];
    playButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.24);
    playButton.zPosition = LayerUI;
    [_globalNode addChild:playButton];
    
    // Rate button
    
    SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"rate"];
    rateButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.12);
    rateButton.zPosition = LayerUI;
    [_globalNode addChild:rateButton];
    
// Setup Social Buttons
//    SKSpriteNode *twitterButton = [SKSpriteNode spriteNodeWithImageNamed:@"twitterBttn"];
//    twitterButton.position = CGPointMake(self.size.width * 0.3,self.size.height * 0.1);
//    twitterButton.zPosition = LayerUI;
//    [_globalNode addChild:twitterButton];
//
//    SKSpriteNode *facebookButton = [SKSpriteNode spriteNodeWithImageNamed:@"facebookBttn"];
//    facebookButton.position = CGPointMake(self.size.width * 0.5,self.size.height * 0.1);
//    facebookButton.zPosition = LayerUI;
//    [_globalNode addChild:facebookButton];
//    
//    SKSpriteNode *instagramButton = [SKSpriteNode spriteNodeWithImageNamed:@"instagramBttn"];
//    instagramButton.position = CGPointMake(self.size.width * 0.7,self.size.height * 0.1);
//    instagramButton.zPosition = LayerUI;
//    [_globalNode addChild:instagramButton];
    
// Bounce button
//    SKAction *scaleUp = [SKAction scaleTo:1.02 duration:0.75];
//    scaleUp.timingMode = SKActionTimingEaseInEaseOut;
//    SKAction *scaleDown = [SKAction scaleTo:0.98 duration:0.75];
//    scaleDown.timingMode = SKActionTimingEaseInEaseOut;
//    
//    [learn runAction:[SKAction repeatActionForever:[SKAction sequence:@[scaleUp, scaleDown]]]];
}

#pragma mark - Game Sounds

- (void)setupSounds
{
    _dingAction = [SKAction playSoundFileNamed:@"ding.wav" waitForCompletion:NO];
    _flapAction = [SKAction playSoundFileNamed:@"flapping.wav" waitForCompletion:NO];
    _whackAction = [SKAction playSoundFileNamed:@"whack.wav" waitForCompletion:NO];
    _fallingAction = [SKAction playSoundFileNamed:@"falling.wav" waitForCompletion:NO];
    _hitGroundAction = [SKAction playSoundFileNamed:@"hitGround.wav" waitForCompletion:NO];
    _popAction = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
    _coinAction = [SKAction playSoundFileNamed:@"coin.wav" waitForCompletion:NO];
    _introSong = [SKAction playSoundFileNamed:@"intro.wav" waitForCompletion:NO];
}

#pragma mark - Gameplay

- (SKSpriteNode *)createObstacle
{
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"obstacle"];
    sprite.zPosition = LayerObstacle;
    sprite.userData = [NSMutableDictionary dictionary];
    
    CGFloat offsetX = sprite.frame.size.width * sprite.anchorPoint.x;
    CGFloat offsetY = sprite.frame.size.height * sprite.anchorPoint.y;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, 19 - offsetX, 315 - offsetY);
    CGPathAddLineToPoint(path, NULL, 41 - offsetX, 311 - offsetY);
    CGPathAddLineToPoint(path, NULL, 42 - offsetX, 282 - offsetY);
    CGPathAddLineToPoint(path, NULL, 54 - offsetX, 1 - offsetY);
    CGPathAddLineToPoint(path, NULL, 54 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 1 - offsetX, 0 - offsetY);
    CGPathAddLineToPoint(path, NULL, 2 - offsetX, 296 - offsetY);
    CGPathAddLineToPoint(path, NULL, 10 - offsetX, 312 - offsetY);
    
    CGPathCloseSubpath(path);
    
    sprite.physicsBody = [SKPhysicsBody bodyWithPolygonFromPath:path];
    [sprite skt_attachDebugFrameFromPath:path color:[SKColor redColor]];
    
    sprite.physicsBody.categoryBitMask = EntityCategoryObstacle;
    sprite.physicsBody.collisionBitMask = 0;
    sprite.physicsBody.contactTestBitMask = EntityCategoryPlayer;
    
    return sprite;
}

- (void)showObstacle
{
    SKSpriteNode *bottomObstacle = [self createObstacle];
    float startX = self.size.width + bottomObstacle.size.width / 2.0;
    
    float bottomObstacleMin = (_playStart - bottomObstacle.size.height / 2.0)
          + _playHeight * kBottomObstacleMinFraction;
    float bottomObstacleMax = (_playStart - bottomObstacle.size.height / 2.0)
          + _playHeight * kBottomObstacleMaxFraction;
    bottomObstacle.position = CGPointMake(startX,RandomFloatRange(bottomObstacleMin, bottomObstacleMax));
    bottomObstacle.name = @"bottomObstacle";
    [_globalNode addChild:bottomObstacle];
    
    SKSpriteNode *topObstacle = [self createObstacle];
    topObstacle.zRotation = DegreesToRadians(180);
    topObstacle.position = CGPointMake(startX,bottomObstacle.position.y + bottomObstacle.size.height / 2.0 + topObstacle.size.height / 2.0 + _player.size.height * kGapMultiplier);
    topObstacle.name = @"topObstacle";
    [_globalNode addChild:topObstacle];
    
    float moveX = self.size.width + topObstacle.size.width;
    float moveDuration = moveX / kGroundSpeed;
    SKAction *sequence = [SKAction sequence:@[
         [SKAction moveByX:-moveX y:0 duration:moveDuration],
         [SKAction removeFromParent]
    ]];
    
    [topObstacle runAction:sequence];
    [bottomObstacle runAction:sequence];
}

- (void)loopObstacle
{
    SKAction *InitialDelay = [SKAction waitForDuration:kLoopFirstObstacleDelay];
    SKAction *loop = [SKAction performSelector:@selector(showObstacle) onTarget:self];
    SKAction *everyDelay = [SKAction waitForDuration:kLoopEveryObstacleDelay];
    SKAction *loopSequence = [SKAction sequence:@[loop,everyDelay]];
    SKAction *repeatLoop = [SKAction repeatActionForever:loopSequence];
    SKAction *obstacleSequence = [SKAction sequence:@[InitialDelay,repeatLoop]];
    
    [self runAction:obstacleSequence withKey:@"loop"];
}

- (void)stopGameLoop
{
    [self removeActionForKey:@"loop"];
    [_globalNode enumerateChildNodesWithName:@"topObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
    
    [_globalNode enumerateChildNodesWithName:@"bottomObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeAllActions];
    }];
}

- (void)flapPlayer
{
    // Play Sounds
    [self runAction:_flapAction];
    
    _playerVelocity = CGPointMake(0, kImpulse);
    _playerAngularVelocity = DegreesToRadians(kAngularVelocity);
    _lastTouchTime = _lastUpdateTime;
    _lastTouchY = _player.position.y;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    switch (_gameState) {
        case gameStateMainMenu:
            if (touchLocation.y < self.size.height * 0.2) {
                [self rateApp];
            } else if (touchLocation.y > self.size.width * 0.2) {
                [self switchToNewGame:gameStateTutorial];
            }
            break;
        case gameStateTutorial:
            [self switchToPlay];
            break;
        case gameStatePlay:
            [self flapPlayer];
            break;
        case gameStateFalling:
            break;
        case gameStateShowingScore:
            break;
        case gameStateGameOver:
            if (touchLocation.x < self.size.width * 0.6) {
                [self switchToNewGame:gameStateMainMenu];
            } else {
                [self shareScore];
            }
            break;
    }
}

- (void)rateApp {
    
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
}
#pragma mark - Game States

- (void)switchToFalling {
    _gameState = gameStateFalling;
    
    // Screen shake
    SKAction *shake =
    [SKAction skt_screenShakeWithNode:_globalNode  amount:CGPointMake(0, 7.0)
                         oscillations:10 duration:1.0];
    [_globalNode  runAction:shake];
    
    // Flash
    SKSpriteNode *whiteNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:self.size];
    whiteNode.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
    //whiteNode.zPosition = LayerFlash;
    [_globalNode  addChild:whiteNode];
    [whiteNode runAction:[SKAction sequence:@[
                                              [SKAction waitForDuration:0.01],
                                              [SKAction removeFromParent]
                                              ]]];
    
    // Transition code...
    [self runAction:[SKAction sequence:@[
                                         _whackAction,
                                         [SKAction waitForDuration:0.1],
                                         _fallingAction]]];
    
    [_player removeAllActions];
    [self stopGameLoop];
}

- (void)switchToShowScore {
    
    _gameState = gameStateShowingScore;
    
    [_player removeAllActions];
    [self stopGameLoop];
    
    [self setupScoreCard];
    
}

- (void)switchToNewGame:(gameState)state {
    
    [self runAction:_popAction];
    
    SKScene *newScene = [[YBMyScene alloc] initWithSize:self.size delegate:_delegate state:state];
    SKTransition *transition = [SKTransition fadeWithColor:[SKColor blackColor] duration:0.5];
    [self.view presentScene:newScene transition:transition];
}

- (void)switchToGameOver {
    _gameState = gameStateGameOver;
}

- (void)switchToTutorial {
    
    _gameState = gameStateTutorial;
    [self setupBG];
    [self setupFG];
    [self setupPlayer];
    [self setupSounds];
    [self setupScoreLabel];
    [self setupTutorial];
    [self animateBirdWings];
    
}

- (void)setupTutorial {
    SKSpriteNode *tutorial = [SKSpriteNode spriteNodeWithImageNamed:@"Tutorial"];
    tutorial.position = CGPointMake((int)self.size.width * 0.5, (int)_playHeight * 0.4 + _playStart);
    tutorial.name = @"Tutorial";
    tutorial.zPosition = LayerUI;
    [_globalNode addChild:tutorial];
    
    SKSpriteNode *ready = [SKSpriteNode spriteNodeWithImageNamed:@"tapToStart"];
    ready.position = CGPointMake(self.size.width * 0.5, _playHeight * 0.7 + _playStart);
    ready.name = @"Tutorial";
    ready.zPosition = LayerUI;
    [_globalNode addChild:ready];
    
}

- (void)switchToPlay {
    
    // Set state
    _gameState = gameStatePlay;
    
    // Remove tutorial
    [_globalNode  enumerateChildNodesWithName:@"Tutorial" usingBlock:^(SKNode *node, BOOL *stop) {
        [node runAction:[SKAction sequence:@[
              [SKAction fadeOutWithDuration:0.5],[SKAction removeFromParent]]]];
    }];
    
    // Remove wobble
    [_player removeActionForKey:@"Wobble"];
    [_player removeActionForKey:@"introSong"];
    
    // Start spawning
    [self loopObstacle];
    
    // Move player
    [self flapPlayer];
    
}

- (void)switchToMainMenu {
    
    _gameState = gameStateMainMenu;
    [self setupBG];
    [self setupFG];
    [self setupPlayer];
    [self setupMainMenu];
    [self setupSounds];
    [self animateBirdWings];
    
}

#pragma mark - Updates

- (void)checkHitObstacle
{
    if (_hitObstacle) {
        _hitObstacle = NO;
        [self switchToFalling];
    }
}

- (void)checkHitGround
{
    if (_hitGround) {
        _hitGround = NO;
        _playerVelocity = CGPointZero;
        _player.zRotation = DegreesToRadians(-90);
        _player.position = CGPointMake(_player.position.x, _playStart + _player.size.width /2.0);
        [self runAction:_hitGroundAction];
        [self switchToShowScore];
    }
}

- (void)updatePlayer
{
    // Add Gravity
    CGPoint gravity = CGPointMake(0,kGravity);
    CGPoint gravityStep = CGPointMultiplyScalar(gravity,_dt);
    _playerVelocity = CGPointAdd(_playerVelocity, gravityStep);
    
    // Apply Velocity
    CGPoint velocityStep = CGPointMultiplyScalar(_playerVelocity, _dt);
    _player.position = CGPointAdd(_player.position, velocityStep);
    _player.position = CGPointMake(_player.position.x, MIN(_player.position.y, self.size.height));
    
    // Halt when hits ground
    if (_player.position.y - _player.size.height / 2 <= _playStart) {
        _player.position = CGPointMake(_player.position.x, _playStart + _player.size.height / 2);
    }
    
    if (_player.position.y < _lastTouchY) {
        _playerAngularVelocity = -DegreesToRadians(kAngularVelocity);
    }
    
    // Rotate player
    float angularStep = _playerAngularVelocity * _dt;
    _player.zRotation += angularStep;
    _player.zRotation = MIN(MAX(_player.zRotation,DegreesToRadians(kDegreesMin)),
                            DegreesToRadians(kDegreesMax));
}

-(void)update:(CFTimeInterval)currentTime
{
    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    
    _lastUpdateTime = currentTime;
    
    switch (_gameState) {
        case gameStateMainMenu:
            break;
        case gameStateTutorial:
            break;
        case gameStatePlay:
            // Gameplay
            [self updateForeground];
            [self updatePlayer];
            [self updateScore];
            [self checkHitGround];
            [self checkHitObstacle];
            break;
        case gameStateFalling:
            // Check hit ground
            [self checkHitGround];
            [self updatePlayer];
            break;
        case gameStateShowingScore:
            break;
        case gameStateGameOver:
            break;
    }
}

#pragma mark - Special 

- (void)shareScore
{
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8",APP_STORE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    UIImage *screenshot = [self.delegate screenshot];
    
    NSString *initialTextString = [NSString stringWithFormat:@"Amma let you Finnish.. but I just score %d in Flappy Kanye!", _gameScore];
    [self.delegate shareString:initialTextString url:url image:screenshot];
}

#pragma mark - Game Score

- (NSInteger)bestScore
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"];
}

- (void)setBestScore:(int)bestScore
{
    [[NSUserDefaults standardUserDefaults]setInteger:bestScore forKey:@"BestScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setupScoreLabel
{
    _scoreLabel = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    _scoreLabel.fontColor = [SKColor colorWithRed:0.439 green:0.455 blue:0.510 alpha:1];
    _scoreLabel.position = CGPointMake(self.size.width/2.0,self.size.height - kMargin * 2.8);
    _scoreLabel.text = @"0";
    _scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    _scoreLabel.zPosition = LayerScore;

    [_globalNode addChild:_scoreLabel];
}

- (void)setupScoreCard
{
    if (_gameScore > [self bestScore]) {
        [self setBestScore:_gameScore];
    }
    
    // Scorecard Background Sprite
    SKSpriteNode *scoreCard = [SKSpriteNode spriteNodeWithImageNamed:@"scoreCard"];
    scoreCard.position = CGPointMake(self.size.width * 0.5,self.size.height * 0.5);
    scoreCard.name = @"ShowScore";
    scoreCard.zPosition = LayerUI;
    [_globalNode addChild:scoreCard];
    
    SKLabelNode *lastScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    lastScore.fontColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
    lastScore.position = CGPointMake(-scoreCard.size.width * 0.25, -scoreCard.size.height * 0.3);
    lastScore.text = [NSString stringWithFormat:@"%d",_gameScore];
    [scoreCard addChild:lastScore];
    
    SKLabelNode *bestScore = [[SKLabelNode alloc] initWithFontNamed:kFontName];
    bestScore.fontColor = [SKColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.9];
    bestScore.position = CGPointMake(scoreCard.size.width * 0.25, -scoreCard.size.height * 0.3);
    bestScore.text = [NSString stringWithFormat:@"%ld", (long)[self bestScore]];
    [scoreCard addChild:bestScore];
    
    // Game Over Sprite
    SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithImageNamed:@"gameOver"];
    gameOver.position = CGPointMake(self.size.width/2, self.size.height/2 + scoreCard.size.height/2 + kMargin + gameOver.size.height/2);
    gameOver.zPosition = LayerUI;
    [_globalNode addChild:gameOver];

    SKSpriteNode *okButton = [SKSpriteNode spriteNodeWithImageNamed:@"okayButton"];
    okButton.position = CGPointMake(self.size.width * 0.25, self.size.height/2 - scoreCard.size.height/2 - kMargin - okButton.size.height/2);
    okButton.zPosition = LayerUI;
    [_globalNode addChild:okButton];
    
    SKSpriteNode *shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"shareButton"];
    shareButton.position = CGPointMake(self.size.width * 0.75, self.size.height/2 - scoreCard.size.height/2 - kMargin - shareButton.size.height/2);
    shareButton.zPosition = LayerUI;
    [_globalNode addChild:shareButton];
    
    
    gameOver.scale = 0;
    gameOver.alpha = 0;
    SKAction *group = [SKAction group:@[
            [SKAction fadeInWithDuration:kAnimDelay],
            [SKAction scaleTo:1.0 duration:kAnimDelay] ]];
    
    group.timingMode = SKActionTimingEaseInEaseOut;
    [gameOver runAction:[SKAction sequence:@[
              [SKAction waitForDuration:kAnimDelay],group ]]];

    
    scoreCard.position = CGPointMake(self.size.width * 0.5,-scoreCard.size.height/2);
    SKAction *moveTo = [SKAction moveTo:CGPointMake(self.size.width/2, self.size.height/2) duration:kAnimDelay];
    moveTo.timingMode = SKActionTimingEaseInEaseOut;
    [scoreCard runAction:[SKAction sequence:@[
               [SKAction waitForDuration:kAnimDelay*2], moveTo ]]];
    
    okButton.alpha = 0;
    shareButton.alpha = 0;
    SKAction *fadeIn = [SKAction sequence:@[
      [SKAction waitForDuration:kAnimDelay*3],
      [SKAction fadeInWithDuration:kAnimDelay] ]];
   
    [okButton runAction:fadeIn];
    [shareButton runAction:fadeIn];
    
    SKAction *pops = [SKAction sequence:@[
                 [SKAction waitForDuration:kAnimDelay],_popAction,
                 [SKAction waitForDuration:kAnimDelay],_popAction,
                 [SKAction waitForDuration:kAnimDelay],_popAction,
             [SKAction runBlock:^{
        [self switchToGameOver];
    }] ]];
    [self runAction:pops];
}

- (void)updateScore
{
    [_globalNode enumerateChildNodesWithName:@"bottomObstacle" usingBlock:^(SKNode *node, BOOL *stop) {
       
        SKSpriteNode *obstacle = (SKSpriteNode *)node;
        
        NSNumber *passed = obstacle.userData[@"Passed"];
        if (passed && passed.boolValue) return;
        
        if (_player.position.x > obstacle.position.x + obstacle.size.width / 2) {
            
            _gameScore++;
            _scoreLabel.text = [NSString stringWithFormat:@"%d",_gameScore];
            [self runAction:_coinAction];
            obstacle.userData[@"Passed"] = @YES;
        }
    }];
}

- (void)animateBirdWings
{
    NSMutableArray *textures = [NSMutableArray array];
    
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"assets"];
    
    for (int i = 0; i < kNumberOfBirdFrames; i++ ) {
        NSString *textureName = [NSString stringWithFormat:@"bird%d",i];
        [textures addObject:[atlas textureNamed:textureName]];
    }
    
    for (int i = kNumberOfBirdFrames - 2; i > 0; i--) {
        NSString *textureName = [NSString stringWithFormat:@"bird%d",i];
        [textures addObject:[atlas textureNamed:textureName]]; 
    }
    
    SKAction *animateWings = [SKAction animateWithTextures:textures timePerFrame:0.07];
    [_player runAction:[SKAction repeatActionForever:animateWings]];
    
    
}

#pragma mark - Collision Detection

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *object = (contact.bodyA.categoryBitMask == EntityCategoryPlayer ? contact.bodyB : contact.bodyA);
    
    if (object.categoryBitMask == EntityCategoryGround) {
        _hitGround = YES;
        return;
    }
    
    if (object.categoryBitMask == EntityCategoryObstacle) {
        _hitObstacle = YES;
        return;
    }
}

@end
