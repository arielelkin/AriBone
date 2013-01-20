//
//  ViewController.m
//  AriBone
//
//  Created by Ariel Elkin on 19/01/2013.
//  Copyright (c) 2013 ariel. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

#import "mo_audio.h"

#import "ObjectAL.h"

id refToSelf;

@interface ViewController ()

@property float echoLength;
@property IBOutlet UISlider *accelSlider;
@property IBOutlet UISlider *accelSliderTwo;
@property IBOutlet UISlider *accelSliderThree;

@property IBOutlet UIButton *lowerButton;

@property CMMotionManager *motionManager;

@property NSArray *acapellaList;

@property ALBuffer *drumLoopOne;
@property ALSource *drumLoopOnePlayer;

@property ALBuffer *drumLoopTwo;
@property ALSource *drumLoopTwoPlayer;

@property ALSource *currentDrumLoop;

@property ALBuffer *chorusPad;
@property ALSource *chorusPadPlayer;

@property ALBuffer *rockinBuffer;
@property ALSource *rockinPlayer;

@end

#define SRATE 22050
#define FRAMESIZE 128
#define NUMCHANNELS 2

int onsetDecay = 500;
int onset = onsetDecay;

float theIn = 0;
float moogFreq = 600;

float freq = 0;

float accelX = 0;
float accelY = 0;
float accelZ = 0;

int nextDrum = 0;

bool muteRockin;
bool objectALisPlaying = false;
bool fxOn = false;

bool lowerButtonDown = false;

void audioCallback( Float32 * buffer, UInt32 framesize, void* userData)
{
    AudioData *data = (AudioData*) userData;
    
    for(int i=0; i<framesize; i++)
    {
        SAMPLE in = buffer[2*i];
        
        theIn = in;
        
        if(true){
            in = data->filterOne->tick(in);
            
            in = in + (in * data->sineOne->tick());
            
            
    //        in = in + data->chorus->tick(in) * 0.7;
            if(!objectALisPlaying)in = in + (data->reverb->tick(in) * 0.4);
        }
        
        
        SAMPLE out = in;
        
        buffer[2*i] = buffer[2*i+1] = out;
    }
}


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    [OALSimpleAudio sharedInstance].reservedSources = 2;
    [self setupAudio];
    [self setupSamples];
    [self setupAccel];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(checkButton) userInfo:nil repeats:YES];
}

-(void)checkButton{
//    NSLog(@"in: %.5f", theIn);
    if (self.lowerButton.isTouchInside) {
        self.chorusPadPlayer.gain = 0.5;
    } else{
        self.chorusPadPlayer.gain = 0;
    }
    
    float peak = audioData.filterTwo->tick(fabs(theIn));
    [self.chorusPadPlayer setPitch:peak > 0.01 ? 1.5 : 1];
    
    if(peak > 0.02 && !muteRockin){
        [self.rockinPlayer play:self.rockinBuffer];
    } else {
        [self.rockinPlayer rewind];
    }
}


-(IBAction)nextDrum{
    nextDrum ++;
    if(nextDrum % 2 == 1){
        [self.drumLoopOnePlayer play:self.drumLoopOne gain:0.4 pitch:1 pan:1 loop:YES];
        self.currentDrumLoop = self.drumLoopOnePlayer;
        objectALisPlaying = true;
    } else if(nextDrum % 2 == 0){
        [self.drumLoopOnePlayer stop];
        [self.drumLoopOnePlayer rewind];
        objectALisPlaying = false;
    }
}

-(IBAction)toggleFX{
    if(fxOn) fxOn = false;
    else fxOn = true;
}

-(IBAction)sliderMoved:(UISlider *)sender{
    [self pitchUp:sender.value];
}

-(void)pitchUp:(float)value{
    if(value > 0) {
        [self.currentDrumLoop setPitch:value];
    }
}

-(void)setupSamples{
    
    self.drumLoopOne = [[OpenALManager sharedInstance] bufferFromFile:@"clubBeat1.caf"];
    self.drumLoopOnePlayer = [ALSource source];
    
    self.drumLoopTwo = [[OpenALManager sharedInstance] bufferFromFile:@"percBeat1.caf"];
    self.drumLoopTwoPlayer = [ALSource source];
    
    self.chorusPad = [[OpenALManager sharedInstance] bufferFromFile:@"chorusPadB.caf"];
    self.chorusPadPlayer = [ALSource source];
    self.chorusPadPlayer.gain = 0;
    [self.chorusPadPlayer play:self.chorusPad loop:YES];
    
    self.rockinBuffer = [[OpenALManager sharedInstance] bufferFromFile:@"rockin.caf"];
    self.rockinPlayer = [ALSource source];
    self.rockinPlayer.gain = 0.6;

}

-(void)setupAudio{
    
    Stk::setSampleRate(SRATE);
    
    audioData.chorus = new Chorus();
//    audioData.chorus->setModDepth(0.6);
    audioData.chorus->setEffectMix(1);
    
    audioData.echoOne = new Echo(0.3 * 44100.0);
    audioData.echoOne->setEffectMix(0.8);
    
    audioData.sineOne = new SineWave();
    audioData.sineOne->setFrequency(600);
    
    audioData.reverb = new NRev();
    audioData.reverb->setEffectMix(0.6);
    
    audioData.pitShift = new PitShift();
    audioData.pitShift->setShift(0.6);
    
    audioData.filterOne = new MoOnePole();
    audioData.filterOne->setGain(4);
    audioData.filterTwo = new MoOnePole();
    audioData.filterThree = new MoOnePole();
    audioData.filterFour = new MoOnePole();
        
    
//    const char *path = [[[NSBundle mainBundle] pathForResource:@"percBeat1" ofType:@"wav"] UTF8String];
    
    bool result = MoAudio::init(SRATE, FRAMESIZE, NUMCHANNELS);
    
    if (!result)
    {
        NSLog(@"cannot initialize real-time audio!");
        return;
    }
    
    // start the audio layer, registering a callback method
    result = MoAudio::start( audioCallback, &audioData);
    if (!result)
    {
        NSLog(@"cannot start real-time audio!");
        return;
    }
}

-(void)setupAccel{
    UIAccelerometer*  theAccelerometer = [UIAccelerometer sharedAccelerometer];
    theAccelerometer.updateInterval = 1 / 50.0;
    theAccelerometer.delegate = self;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    UIAccelerationValue x, y, z;
    x = acceleration.x;
    y = acceleration.y;
    z = acceleration.z;
    
    z = audioData.filterThree->tick(fabs(z));
    
    
    audioData.sineOne->setFrequency(z * 500.0);
    audioData.reverb->setT60(z);
    
//    NSLog(@"z: %.1f, size: %.1f", z, z * 500.0);
    
    if (z > 0.7) muteRockin = false;
    else muteRockin = true;
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(BOOL)shouldAutorotate{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortraitUpsideDown;
}



@end
