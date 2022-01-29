//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                  Ribelo VSA Pattern.mq4                                   |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2012 Ribelo"
#property link      "email:   trankvilecko@gmail.com"



//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |
//+-------------------------------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_buffers 4

#property indicator_color2  C'255,213,98'
#property indicator_color3  C'233,63,105'

#property indicator_width2  2
#property indicator_width3  2

#define  is.bull.wrb 1
#define  is.bear.wrb -1
#define  is.bull.wrb.hg 2
#define  is.bear.wrb.hg -2
#define  is.bull.wrb.shadow 3
#define  is.bear.wrb.shadow -3

#define  i.name "r.vsa.p"
#define  short.name "Ribelo VSA Pattern"

//Global External Inputs
extern color bull.pattern.color = C'255,213,98';
extern color bear.pattern.color = C'233,63,105';
extern int bar.width = 2;
extern int average.period = 20;

//Global Buffers & Other Inputs
double normal[], average.volume[], bull.pattern[], bear.pattern[];
int last.bear.pattern, last.bull.pattern;
//+-------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                  |
//+-------------------------------------------------------------------------------------------+
int init() {

   SetIndexBuffer ( 0, normal );
   SetIndexStyle ( 0, DRAW_NONE, 0 );
   SetIndexBuffer ( 1, bull.pattern );
   SetIndexStyle ( 1, DRAW_HISTOGRAM, 0, bar.width, bull.pattern.color );
   SetIndexLabel ( 1, "Bull Pattern" );
   SetIndexBuffer ( 2, bear.pattern );
   SetIndexStyle ( 2, DRAW_HISTOGRAM, 0, bar.width, bear.pattern.color );
   SetIndexLabel ( 2, "Bear Pattern" );
   SetIndexBuffer ( 3, average.volume );
   SetIndexStyle ( 3, DRAW_NONE, 0 );
   

   return ( 0 );
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit() {
   for ( int d = ObjectsTotal() - 1; d >=0; d-- ) {
      string name = ObjectName(d);
      if ( StringSubstr(name,0,3) == i.name ) {
         ObjectDelete(name);
      }
   }
   return ( 0 );
}

//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start() {
   if ( !isNewBar() ) {
      return;
   }
   int i, limit;
   int counted.bars=IndicatorCounted();
   if(counted.bars>0) counted.bars--;
   limit=Bars-counted.bars;
   for ( i = limit; i >= 0; i-- ) { 
      normal[i] = Volume[i];
      average.volume[i] = SineWMA ( Volume, average.period, i );
      
      //RaiseEffort1( i + 1 );
      //FallEffort1( i + 1 );
      //RaiseEffort2( i + 1 );
      //FallEffort2( i + 1 );
      //RaiseEffort3( i + 1 );
      //FallEffort3( i + 1 );
      //RaiseEffort4( i + 1 );
      //FallEffort4( i + 1 );
      //RaiseEffort5( i + 1 );
      //FallEffort5( i + 1 );
      
      if ( !noDemand_1( i + 1 ) ) {
         noSupply_6( i + 1 );
         noSupply_7( i + 1 );
         noSupply_8( i + 1 ); 
         noSupply_9( i + 1 );  
         noSupply_10( i + 1 );  
      }
      if ( !noSupply_1( i + 1 ) ) {
         noDemand_6( i + 1 );
         noDemand_7( i + 1 );
         noDemand_8( i + 1 );
         noDemand_9( i + 1 );
         noDemand_10( i + 1 );
      }
      
      if ( !noDemand_2( i + 1 ) ) {
         noSupply_3( i + 1 );
         noSupply_4( i + 1 );
         noSupply_5( i + 1 );
      }
      
      if ( !noSupply_2( i + 1 ) ) {
         noDemand_3( i + 1 );
         noDemand_4( i + 1 );
         noDemand_5( i + 1 );
      }
      
   }
   return ( 0 );
}

bool isNewBar() {
   static datetime time;
   if ( Time[0] != time ) {
      time = Time[0];
      return(true);
   } else {
      return(false);
   }
} 


int isWRB ( int i ) {
   double max.body.size = 0;
   double body.size = 0;
   for ( int y = i + 1; y <= ( i + 3 ); y++ ) {
      max.body.size = MathMax ( max.body.size, MathAbs ( Close[y] - Open[y] ) );
   }
   body.size = MathAbs(Close[i] - Open[i]);   
   if ( body.size > max.body.size ) {
      if ( Close[i] > Open[i] ) {
         if ( Close[i] > iHigh( Symbol(), 0, iHighest( Symbol(), 0, MODE_HIGH, 3, i+1 ) ) ) {
            if ( MathMax(High[i+1], Open[i]) < MathMin(Low[i-1], Close[i] ) ) {
               return(is.bull.wrb.hg);
            } else {
               return(is.bull.wrb);
            }
         }
      }
      if ( Close[i] < Open[i] ) {
         if ( Close[i] < iLow( Symbol(), 0, iLowest( Symbol(), 0, MODE_LOW, 3, i+1 ) ) ) {
            if ( MathMin(Low[i+1], Open[i]) > MathMax(High[i-1], Close[i]) ) {
               return(is.bear.wrb.hg);
            } else {
               return(is.bear.wrb);
            }
         }
      }  
   }
   return(false);
}


bool RaiseEffort1( int i ) {
   if ( High[i] > High[i+1] ) {
      if ( Low[i] >= Low[i+1] ) {
         if ( High[i] - Low[i] == High[i+1] - Low[i+1] ) {
            if ( Open[i] <= Low[i] + ( High[i] - Low[i] ) * 0.1 ) {
               if ( Close[i] >= Low[i] + ( High[i] - Low[i] ) * 0.9 ) {
                  if ( Close[i] > Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) >= High[i+1] ) {
                        if ( Volume[i] > Volume[i+1] ) {
                           if ( Volume[i] > average.volume[i] && Volume[i] <= 2*average.volume[i] ) {
                              if ( isWRB( i ) >= is.bull.wrb ) {
                                 bull.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}                                

bool FallEffort1( int i ) {
   if ( Low[i] < Low[i+1] ) {
      if ( High[i] <= High[i+1] ) {
         if ( High[i] - Low[i] == High[i+1] - Low[i+1] ) {
            if ( Open[i] >= Low[i] + ( High[i] - Low[i] ) * 0.9 ) {
               if ( Close[i] <= Low[i] + ( High[i] - Low[i] ) * 0.1 ) {
                  if ( Close[i] < Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) <= Low[i+1] ) {
                        if ( Volume[i] > Volume[i+1] ) {
                           if ( Volume[i] > average.volume[i] && Volume[i] <= 2*average.volume[i] ) {
                              if ( isWRB( i ) <= is.bear.wrb ) {
                                 bear.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}   

bool RaiseEffort2( int i ) {
   if ( High[i] > High[i+1] ) {
      if ( Low[i] >= Low[i+1] ) {
         if ( High[i] - Low[i] > High[i+1] - Low[i+1] ) {
            if ( Open[i] <= Low[i] + ( High[i] - Low[i] ) * 0.2 ) {
               if ( Close[i] >= Low[i] + ( High[i] - Low[i] ) * 0.8 ) {
                  if ( Close[i] > Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) >= High[i+1] ) {
                        if ( Volume[i] > Volume[i+1] ) {
                           if ( Volume[i] > 2*average.volume[i] && Volume[i] <= 4*average.volume[i] ) {
                              if ( isWRB( i ) >= is.bull.wrb ) {
                                 bull.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}    

bool FallEffort2( int i ) {
   if ( Low[i] < Low[i+1] ) {
      if ( High[i] <= High[i+1] ) {
         if ( High[i] - Low[i] > High[i+1] - Low[i+1] ) {
            if ( Open[i] >= Low[i] + ( High[i] - Low[i] ) * 0.8 ) {
               if ( Close[i] <= Low[i] + ( High[i] - Low[i] ) * 0.2 ) {
                  if ( Close[i] < Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) <= Low[i+1] ) {
                        if ( Volume[i] > Volume[i+1] ) {
                           if ( Volume[i] > 2*average.volume[i] && Volume[i] <= 4*average.volume[i] ) {
                              if ( isWRB( i ) <= is.bear.wrb ) {
                                 bear.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}     

bool RaiseEffort3( int i ) {
   if ( High[i] > High[i+1] ) {
      if ( Low[i] >= Low[i+1] ) {
         if ( High[i] - Low[i] == High[i+1] - Low[i+1] ) {
            if ( Open[i] <= Low[i] + ( High[i] - Low[i] ) * 0.1 ) {
               if ( Close[i] >= Low[i] + ( High[i] - Low[i] ) * 0.9 ) {
                  if ( Close[i] > Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) >= High[i+1] ) {
                        if ( Volume[i] > Volume[i+1] ) {
                           if ( Volume[i] > 2*average.volume[i] && Volume[i] <= 4*average.volume[i] ) {
                              if ( isWRB( i ) >= is.bull.wrb ) {
                                 bull.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}                             

bool FallEffort3( int i ) {
   if ( Low[i] < Low[i+1] ) {
      if ( High[i] <= High[i+1] ) {
         if ( High[i] - Low[i] == High[i+1] - Low[i+1] ) {
            if ( Open[i] >= Low[i] + ( High[i] - Low[i] ) * 0.9 ) {
               if ( Close[i] <= Low[i] + ( High[i] - Low[i] ) * 0.1 ) {
                  if ( Close[i] < Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) <= Low[i+1] ) {
                        if ( Volume[i] > Volume[i+1] ) {
                           if ( Volume[i] > 2*average.volume[i] && Volume[i] <= 4*average.volume[i] ) {
                              if ( isWRB( i ) <= is.bear.wrb ) {
                                 bear.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}    

bool RaiseEffort4( int i ) {
   if ( High[i] > High[i+1] ) {
      if ( Low[i] >= Low[i+1] ) {
         if ( High[i] - Low[i] > High[i+1] - Low[i+1] ) {
            if ( Open[i] <= Low[i] + ( High[i] - Low[i] ) * 0.2 ) {
               if ( Close[i] >= Low[i] + ( High[i] - Low[i] ) * 0.8 ) {
                  if ( Close[i] > Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) >= High[i+1] ) {
                        if ( Volume[i] > Volume[i+1] && Volume[i] > Volume[i+2] ) {
                           if ( Volume[i] < average.volume[i] ) {
                              if ( isWRB( i ) >= is.bull.wrb ) {
                                 bull.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}             

bool FallEffort4( int i ) {
   if ( Low[i] < Low[i+1] ) {
      if ( High[i] <= High[i+1] ) {
         if ( High[i] - Low[i] > High[i+1] - Low[i+1] ) {
            if ( Open[i] >= Low[i] + ( High[i] - Low[i] ) * 0.8 ) {
               if ( Close[i] <= Low[i] + ( High[i] - Low[i] ) * 0.2 ) {
                  if ( Close[i] < Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) <= Low[i+1] ) {
                        if ( Volume[i] > Volume[i+1] && Volume[i] > Volume[i+2] ) {
                           if ( Volume[i] < average.volume[i] ) {
                              if ( isWRB( i ) <= is.bear.wrb ) {
                                 bear.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}    

bool RaiseEffort5( int i ) {
   if ( High[i] > High[i+1] ) {
      if ( Low[i] >= Low[i+1] ) {
         if ( High[i] - Low[i] == High[i+1] - Low[i+1] ) {
            if ( Open[i] <= Low[i] + ( High[i] - Low[i] ) * 0.1 ) {
               if ( Close[i] >= Low[i] + ( High[i] - Low[i] ) * 0.9 ) {
                  if ( Close[i] > Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) >= High[i+1] ) {
                        if ( Volume[i] > Volume[i+1] && Volume[i] > Volume[i+2] ) {
                           if ( Volume[i] > average.volume[i] ) {
                              if ( isWRB( i ) >= is.bull.wrb ) {
                                 bull.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
} 

bool FallEffort5( int i ) {
   if ( Low[i] < Low[i+1] ) {
      if ( High[i] <= High[i+1] ) {
         if ( High[i] - Low[i] == High[i+1] - Low[i+1] ) {
            if ( Open[i] >= Low[i] + ( High[i] - Low[i] ) * 0.9 ) {
               if ( Close[i] <= Low[i] + ( High[i] - Low[i] ) * 0.1 ) {
                  if ( Close[i] < Close[i+1] ) {
                     if ( 0.5 * ( High[i] + Low[i] ) <= Low[i+1] ) {
                        if ( Volume[i] > Volume[i+1] && Volume[i] > Volume[i+2] ) {
                           if ( Volume[i] > average.volume[i] ) {
                              if ( isWRB( i ) <= is.bear.wrb ) {
                                 bear.pattern[i] = Volume[i];
                                 return(true);
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }
}            

bool noDemand_1( int i ) {
   if ( Close[i] < Close[i+1] ) {
      if ( High[i] < High[i+1] ) {
         if ( High[i+1] > High[i+2] ) {
            if ( Low[i+1] >= Low[i+2] ) {
               if ( High[i+1] - Low[i+1] <= High[i+2] - Low[i+2] ) {
                  if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                     //bear.pattern[i+1] = Volume[i+1];
                     return(true);
                  }
               }
            }
         }
      }
   }
   return(false);
}
               

bool noSupply_1( int i ) {
   if ( Close[i] > Close[i+1] ) {
      if ( Low[i] > Low[i+1] ) {
         if ( Low[i+1] > Low[i+2] ) {
            if ( High[i+1] >= High[i+2] ) {
               if ( High[i+1] - Low[i+1] >= High[i+2] - Low[i+2] ) {
                  if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                     //bull.pattern[i+1] = Volume[i+1];
                     return(true);
                  }
               }
            }
         }
      }
   }
   return(false);
}

bool noDemand_2( int i ) {
   if ( High[i+1] > High[i+2] ) {
      if ( Low[i+1] >= Low[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == Open[i+1] ) {
               if ( Close[i+1] > Close[i] ) {
                  if ( High[i+1] >= High[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bear.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   } 
   return(false);  
}

bool noSupply_2( int i ) {
   if ( Low[i+1] < Low[i+2] ) {
      if ( High[i+1] <= High[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == Open[i+1] ) {
               if ( Close[i+1] < Close[i] ) {
                  if ( Low[i+1] <= Low[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bull.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   } 
   return(false);
}

bool noDemand_3( int i ) {
   if ( High[i+1] > High[i+2] ) {
      if ( Low[i+1] >= Low[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == High[i+1] ) {
               if ( Close[i+1] > Close[i] ) {
                  if ( High[i+1] >= High[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bear.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   }
   return(false);  
}

bool noSupply_3( int i ) {
   if ( Low[i+1] < Low[i+2] ) {
      if ( High[i+1] <= High[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == Low[i+1] ) {
               if ( Close[i+1] < Close[i] ) {
                  if ( Low[i+1] <= Low[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bull.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   }
   return(false);  
}

bool noDemand_4( int i ) {
   if ( High[i+1] > High[i+2] ) {
      if ( Low[i+1] >= Low[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == 0.5 * ( High[i+1] + Low[i+1] ) ) {
               if ( Close[i+1] > Close[i] ) {
                  if ( High[i+1] >= High[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bear.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   }   
   return(false);  
}

bool noSupply_4( int i ) {
   if ( Low[i+1] < Low[i+2] ) {
      if ( High[i+1] <= High[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == 0.5 * ( High[i+1] + Low[i+1] ) ) {
               if ( Close[i+1] < Close[i] ) {
                  if ( Low[i+1] <= Low[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bull.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   }
   return(false);  
}

bool noDemand_5( int i ) {
   if ( High[i+1] > High[i+2] ) {
      if ( Low[i+1] >= Low[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == Low[i+1] ) {
               if ( Close[i+1] > Close[i] ) {
                  if ( High[i+1] >= High[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bear.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   }   
   return(false);  
}

bool noSupply_5( int i ) {
   if ( Low[i+1] < Low[i+2] ) {
      if ( High[i+1] <= High[i+2] ) {
         if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
            if ( Close[i+1] == High[i+1] ) {
               if ( Close[i+1] < Close[i] ) {
                  if ( Low[i+1] <= Low[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        bull.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   }
   return(false);  
}

bool noDemand_6( int i ) {
   if ( Close[i+1] > Close[i+2] ) {
      if ( High[i+1] - Low[i+1] > High[i+2] - Low[i+2] ) {
         if ( Close[i+1] > Close[i] ) {
            if ( High[i+1] >= High[i] ) {
               if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                  bear.pattern[i+1] = Volume[i+1];
                  return(true);
               }
            }
         }
      }
   }
   return(false);  
}

bool noSupply_6( int i ) {
   if ( Close[i+1] < Close[i+2] ) {
      if ( High[i+1] - Low[i+1] < High[i+2] - Low[i+2] ) {
         if ( Close[i+1] < Close[i] ) {
            if ( Low[i+1] <= Low[i] ) {
               if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                  bull.pattern[i+1] = Volume[i+1];
                  return(true);
               }
            }
         }
      }
   }
   return(false);  
}

bool noDemand_7( int i ) {
   if ( Close[i+1] > Close[i+2] ) {
      if ( High[i+1] - Low[i+1] == High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == Open[i+1] || Close[i+1] == High[i+1] ) {
            if ( Close[i+1] > Close[i] ) {
               if ( High[i+1] >= High[i] ) {
                  if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                     //bear.pattern[i+1] = Volume[i+1];
                     return(true);
                  }
               }
            }
         }
      }
   } 
   return(false);  
}

bool noSupply_7( int i ) {
   if ( Close[i+1] < Close[i+2] ) {
      if ( High[i+1] - Low[i+1] == High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == Open[i+1] || Close[i+1] == Low[i+1] ) {
            if ( Close[i+1] < Close[i] ) {
               if ( Low[i+1] <= Low[i] ) {
                  if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                     //bull.pattern[i+1] = Volume[i+1];
                     return(true);
                  }
               }
            }
         }
      }
   } 
   return(false); 
}

bool noDemand_8( int i ) {
   if ( Close[i+1] > Close[i+2] ) {
      if ( High[i+1] - Low[i+1] == High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == Low[i+1] || Close[i+1] == High[i+1] || Close[i+1] == 0.5 * ( High[i+1] + Low[i+1] ) ) {
            if ( Close[i+1] != Open[i+1] ) {
               if ( Close[i+1] > Close[i] ) {
                  if ( High[i+1] >= High[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        //bear.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   } 
   return(false);  
}

bool noSupply_8( int i ) {
   if ( Close[i+1] < Close[i+2] ) {
      if ( High[i+1] - Low[i+1] == High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == High[i+1] || Close[i+1] == Low[i+1] || Close[i+1] == 0.5 * ( High[i+1] + Low[i+1] ) ) {
            if ( Close[i+1] != Open[i+1] ) {
               if ( Close[i+1] < Close[i] ) {
                  if ( Low[i+1] <= Low[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        //bull.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   } 
   return(false); 
}


bool noDemand_9( int i ) {
   if ( Close[i+1] == Close[i+2] ) {
      if ( High[i+1] - Low[i+1] < High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == Open[i+1] ) {
            if ( Close[i+1] > Close[i] ) {
               if ( High[i+1] >= High[i] ) {
                  if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                     //bear.pattern[i+1] = Volume[i+1];
                     return(true);
                  }
               }
            }
         }
      }
   } 
   return(false);  
}

bool noSupply_9( int i ) {
   if ( Close[i+1] == Close[i+2] ) {
      if ( High[i+1] - Low[i+1] < High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == Open[i+1] ) {
            if ( Close[i+1] < Close[i] ) {
               if ( Low[i+1] <= Low[i] ) {
                  if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                     //bull.pattern[i+1] = Volume[i+1];
                     return(true);
                  }
               }
            }
         }
      }
   } 
   return(false); 
}

bool noDemand_10( int i ) { //13 14 16
   if ( Close[i+1] == Close[i+2] ) {
      if ( High[i+1] - Low[i+1] < High[i+2] - Low[i+2] ) {
         if ( Close[i+1] == High[i+1] || Close[i+1] == Low[i+1] || Close[i+1] == 0.5 * ( High[i+1] + Low[i+1] ) ) {
            if ( Close[i+1] != Open[i+1] ) {
               if ( Close[i+1] > Close[i] ) {
                  if ( High[i+1] >= High[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        //bear.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   } 
   return(false);  
}

bool noSupply_10( int i ) {//13 14 16
   if ( Close[i+1] == Close[i+2] ) {
      if ( High[i+1] - Low[i+1] < High[i+2] - Low[i+2] ) {
          if ( Close[i+1] == High[i+1] || Close[i+1] == Low[i+1] || Close[i+1] == 0.5 * ( High[i+1] + Low[i+1] ) ) {
            if ( Close[i+1] != Open[i+1] ) {
               if ( Close[i+1] < Close[i] ) {
                  if ( Low[i+1] <= Low[i] ) {
                     if ( Volume[i+1] < Volume[i+2] && Volume[i+1] < Volume[i+3] ) {
                        //bull.pattern[i+1] = Volume[i+1];
                        return(true);
                     }
                  }
               }
            }
         }
      }
   } 
   return(false); 
}

double SineWMA ( double array[], int per, int bar ) {
   double pi = 3.1415926535;
   double Sum = 0;
   double Weight = 0;
   for ( int i = 0; i < per - 1; i++ ) {
      Weight += MathSin ( pi * ( i + 1 ) / ( per + 1 ) );
      Sum += array[bar + i] * MathSin ( pi * ( i + 1 ) / ( per + 1 ) );
   }
   if ( Weight > 0 ) {
      double swma = Sum / Weight;
   } else {
      swma = 0;
   }
   return ( swma );
}

//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+

