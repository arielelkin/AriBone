//
//  ViewController.h
//  AriBone
//
//  Created by Ariel Elkin on 19/01/2013.
//  Copyright (c) 2013 ariel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#include "Stk.h"
#include "Echo.h"
#include "SineWave.h"
#include "PitShift.h"
#include "NRev.h"
#include "Chorus.h"
#include "mo_filter.h"


using namespace stk;
struct AudioData{
	Echo *echoOne;
    SineWave *sineOne;
    PitShift *pitShift;
    NRev *reverb;
    Chorus *chorus;
    MoOnePole *filterOne;
    MoOnePole *filterTwo;
    MoOnePole *filterThree;
    MoOnePole *filterFour;
};


@interface ViewController : UIViewController<UIAccelerometerDelegate>{
    struct AudioData audioData;
}

@end
