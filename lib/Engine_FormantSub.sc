// a subtractive polysynth engine
// and near drop-in replacement for PolySub

Engine_FormantSub : CroneEngine {
    
    classvar <polyDef;
    classvar <paramDefaults;
    classvar <maxNumVoices;

    var <ctlBus; // collection of control busses
    var <mixBus; // audio bus for mixing synth voices
    var <gr; // parent group for voice nodes
    var <voices; // collection of voice nodes
    
    *initClass {
      maxNumVoices = 16;
      StartUp.add{
        polyDef = SynthDef.new(\formantSub, {
          arg out, gate = 1, hz, level = 0.2,
          slope = 0.5,
          formant = 400.0,
          hzToFormant = 1.0,
          sub = 0.4,
          noise = 0.0,
          cut = 8.0,
          ampAtk = 0.05, ampDec = 0.1, ampSus = 1.0, ampRel = 1.0, ampCurve = -1.0,
          cutAtk = 0.0, cutDec = 0.0, cutSus = 1.0, cutRel = 1.0, cutCurve = -1.0, cutEnvAmt = 0.0,
          fgain = 0.0,
          detune = 0,
          width = 0.5,
          hzLag = 0.1;

          var osc, snd, freq, del, aenv, fenv;

          detune = Lag.kr(detune);
          slope = Lag.kr(slope);
          formant = Lag.kr(formant);
          hzToFormant = Lag.kr(hzToFormant);
          fgain = Lag.kr(fgain.min(4.0));
          cut = Lag.kr(cut);
          width = Lag.kr(width);
          detune = detune / 2;
          hz = Lag.kr(hz, hzLag);
          freq = [hz + detune, hz - detune];
          formant = formant + (hz * hzToFormant);
          osc = LeakDC.ar(FormantTriPTR.ar(freq:freq, formant:formant, width:slope));
          snd = osc + ((SinOsc.ar(hz / 2) * sub).dup);
          aenv = EnvGen.ar(
            Env.adsr(ampAtk, ampDec, ampSus, ampRel, 1.0, ampCurve),
            gate, doneAction:2);
          fenv = EnvGen.ar(Env.adsr(cutAtk, cutDec, cutSus, cutRel, 1.0, cutCurve), gate);
          cut = SelectX.kr(cutEnvAmt, [cut, cut * fenv]);
          cut = (cut * hz).min(SampleRate.ir * 0.5 - 1);

          snd = SelectX.ar(noise, [snd, [PinkNoise.ar, PinkNoise.ar]]);
          snd = MoogFF.ar(snd, cut, fgain) * aenv;

          Out.ar(out, level * SelectX.ar(width, [Mix.new(snd).dup, snd]))
        });

        CroneDefs.add(polyDef);

        paramDefaults = Dictionary.with(
          \level -> -12.dbamp,
          \slope -> 0.5,
          \formant -> 400.0,
          \hzToFormant -> 1.0,
          \sub -> 0.4,
          \noise -> 0.0,
          \cut -> 8.0,
          \ampAtk -> 0.05, \ampDec -> 0.1, \ampSus -> 1.0, \ampRel -> 1.0, \ampCurve -> -1.0,
          \cutAtk -> 0.0, \cutDec -> 0.0, \cutSus -> 1.0, \cutRel -> 1.0, \cutCurve -> -1.0,
          \cutEnvAmt -> 0.0, \fgain -> 0.0, \detune -> 0, \width -> 0.5, \hzLag -> 0.1
        );
      }
    }

    *new { arg context, callback;
      ^super.new(context, callback);
    }

    alloc{
      gr = ParGroup.new(context.xg);

      voices = Dictionary.new;
      ctlBus = Dictionary.new;
      polyDef.allControlNames.do({ arg ctl;
        var name = ctl.name;
        postln("control name: " ++ name);
        if((name != \gate) && (name != \hz) && (name != \out), {
          ctlBus.add(name -> Bus.control(context.server));
          ctlBus[name].set(paramDefaults[name]);
        });
      });

      ctlBus.postln;

      ctlBus[\level].setSynchronous(0.2);

      this.addCommand(\start, "if", { arg msg;
        this.addVoice(msg[1], msg[2], false);
      });

      this.addCommand(\stop, "i", { arg msg;
        this.removeVoice(msg[1]);
      });

      this.addCommand(\stopAll, "", {
        gr.set(\gate, 0);
        voices.clear;
      });

      ctlBus.keys.do({ arg name;
        this.addCommand(name, "f", { arg msg; ctlBus[name].setSynchronous(msg[1]); });
      });

      postln("FormantSub: init callback");
    }
    
    addVoice { arg id, hz, map=true;
      var params = List.with(\out, context.out_b.index, \hz, hz);
      var numVoices = voices.size;

      if(voices[id].notNil, {
        voices[id].set(\gate, 1);
        voices[id].set(\hz, hz);
      }, {
        if(numVoices < maxNumVoices, {
          ctlBus.keys.do({ arg name;
            params.add(name);
            params.add(ctlBus[name].getSynchronous);
          });
          
          voices.add(id -> Synth.new(\formantSub, params, gr));
          NodeWatcher.register(voices[id]);
          voices[id].onFree({
            voices.removeAt(id);
          });
          
          if(map, {
            ctlBus.keys.do({ arg name;
              voices[id].map(name, ctlBus[name]);
            });
          });
        });
      });
    }

    removeVoice { arg id;
      if(true, {
        voices[id].set(\gate, 0);
      });
    }

    free {
      gr.free;
      ctlBus.do({ arg bus, i; bus.free; });
      mixBus.do({ arg bus, i; bus.free; });
    }
} // class
