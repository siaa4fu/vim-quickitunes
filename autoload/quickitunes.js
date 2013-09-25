// @name         quick iTunes
// @description  quick control "iTunes for Windows"
// @author       sima
// @Last Change: 2013-09-10.

/* Execute:
 *   [cscript //nologo] quickitunes.js {command} [{argument} ...]
 */

function abort(msg){
  WScript.Echo('Error: ' + msg);
  WScript.Quit();
}
function getValue(property, value, minmax){
  return Math.min(Math.max(property + value, minmax[0]), minmax[1]);
}

var _ = WScript.CreateObject('iTunes.Application');
if(!_) abort('iTunes is not found.');
var _p = _.currentPlaylist;
var _t = _.currentTrack;

var commands = {
   'run'  : function(){ /* _.run(); */ }
//   ,'quit' : function(){ _.quit(); } // ERROR OCCURRED
  ,'play'      : function(){ _.play(); }
  ,'pause'     : function(){ _.pause(); }
  ,'playPause' : function(){ _.playPause(); } // toggle the playing/paused state
  ,'stop'      : function(){ _.stop(); }
  ,'rewind'  : function(){ _.rewind(); } // skip backwards
  ,'forward' : function(){ _.fastForward(); } // skip forward
  ,'resume'  : function(){ _.resume(); } // disable fastforward/rewind
  ,'volume' : function(value, isRelative){
    _.soundVolume = isRelative ? getValue(_.soundVolume, value, [0, 100]) : value;
    WScript.Echo('Sound volume is ' + _.soundVolume + '%.');
  }
  ,'volumeUp'   : function(){ this.volume(+10, true); }
  ,'volumeDown' : function(){ this.volume(-10, true); }
  ,'mute'       : function(){ _.Mute = !_.Mute; }
  ,'back' : function(){ _.backTrack(); } // reposition to beginning of current track or go to previous track
  ,'prev' : function(){ _.previousTrack(); }
  ,'next' : function(){ _.nextTrack(); }
};
if(_p){ // playlist commands
  commands.repeat = function(state){
    _p.songRepeat = state ? state : (_p.songRepeat + 1) % 3;
    WScript.Echo('Repeat ' + ['off', 'one', 'all'][_p.songRepeat] + '.');
  };
  commands.repeatOff = function(){ this.repeat(0); };
  commands.repeatOne = function(){ this.repeat(1); };
  commands.repeatAll = function(){ this.repeat(2); };
  commands.shuffle = function(){
    _p.shuffle = !_p.shuffle;
    WScript.Echo('Shuffle ' + ['off', 'on'][!_p.shuffle ? 0 : 1] + '.');
  };
}
if(_t){ // track commands
  function format(name){
    var properties = { // {{{
      'rating' :
        '\u2605\u2605\u2605\u2605\u2605'.slice( 5 - _t.rating / 20 ) +
        '\u2606\u2606\u2606\u2606\u2606'.slice(     _t.rating / 20 ) +
        ' [' + _t.rating + ']',
      'albumrating' :
        '\u2605\u2605\u2605\u2605\u2605'.slice( 5 - _t.albumrating / 20 ) +
        '\u2606\u2606\u2606\u2606\u2606'.slice(     _t.albumrating / 20 ) +
        ' [' + _t.albumrating + ']'
    }; // }}}
    return name in properties ? properties[name] : _t[name];
  }
  commands.rating = function(level, isRelative){
    _t.rating = isRelative ? getValue(_t.rating, level * 20, [0, 100]) : level * 20;
    WScript.Echo('Rating is ' + format('rating') + '.');
  };
  commands.ratingUp   = function(){ this.rating(+1, true) };
  commands.ratingDown = function(){ this.rating(-1, true) };
  commands.trackInfo = function(){
    var info = [];
    for(var i = 0; i < arguments.length; ++i){
      if(arguments[i] in _t) info.push(format(arguments[i]));
    }
    WScript.Echo(info.join('\n'));
  };
}

var args = WScript.Arguments;
if(args.length > 0 && args(0) in commands){
  var values = [];
  for(var i = 1; i < args.length; ++i) values.push(args(i));
  commands[args(0)].apply(commands, values);
}else{
  WScript.Echo(
    'The command ' + (args.length ? '"' + args(0) + '" ' : '') + 'is not executed.'
  );
}
