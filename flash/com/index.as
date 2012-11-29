package com
{

	import com.WAVWriter;
	import fr.kikko.lab.ShineMP3Encoder;
	import flash.events.SampleDataEvent;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.utils.getTimer;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;

	public class index extends MovieClip
	{
		private var isRecording:Boolean = false;
		var mp3encoder:ShineMP3Encoder;
		var microphone:Microphone;
		var soundRecording:ByteArray = new ByteArray();
		var timeStamp:Number = 0;
		
		public function index()
		{
			record_btn.addEventListener(MouseEvent.CLICK,recordBtnPressed);
			encode_btn.addEventListener(MouseEvent.CLICK,encodeBtnPressed);
			save_btn.addEventListener(MouseEvent.CLICK,saveMP3);
		}
		private function log(txt)
		{
			_debugger.appendText(txt+"\n");
		}
		private function recordBtnPressed(e:MouseEvent)
		{
			if(!isRecording)
			{
				record_btn.gotoAndStop(2);
				isRecording = true;
				startMicRecording()
			}
			else
			{
				record_btn.gotoAndStop(1);
				isRecording = false;
				stopMicRecording()
			}
		}
		///////////////////////////
		function startMicRecording():void 
		{
			soundRecording = new ByteArray();
			microphone=Microphone.getMicrophone();
			microphone.rate=44;
			microphone.gain = 50;
			microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
			log("BEGIN RECORDING");
		}
		function encodeBtnPressed(e:MouseEvent)
		{
			if(soundRecording.length > 0)
			{
				encode_btn.gotoAndStop(2);
				convert2MP3();
			}
			else log("Nothing to encode");
		}
		function stopMicRecording():void {
		
			isRecording=false;
			microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
			soundRecording.position=0;
			microphone.gain = 0;
		}
		
		
		function gotMicData(micData:SampleDataEvent):void 
		{
			soundRecording.writeBytes(micData.data);
		}
		
		function convert2MP3():void
		{
			timeStamp = getTimer();
			var wavWrite:WAVWriter = new WAVWriter();
			wavWrite.numOfChannels=1;
			wavWrite.sampleBitRate=16;
			wavWrite.samplingRate=44100;
			
			var wav:ByteArray = new ByteArray();
		
			wavWrite.processSamples(wav, soundRecording, 44100,1);
			wav.position=0;		
			mp3encoder=new ShineMP3Encoder(wav);
			mp3encoder.addEventListener(Event.COMPLETE, onEncoded);
			mp3encoder.start();
		}
		
		function onEncoded(e:Event):void 
		{
			encode_btn.gotoAndStop(1);
			mp3encoder.mp3Data.position=0;
			log("Encoding took: "+(getTimer() - timeStamp)+" milliseconds");
			log("MP3 Data length: "+mp3encoder.mp3Data.length);
		}
		
		private function saveMP3(e:MouseEvent)
		{
			if(mp3encoder && mp3encoder.mp3Data)
			{
				var loader:URLLoader = new URLLoader();
				var Request:URLRequest = new URLRequest("save_song.php");
				Request.method = URLRequestMethod.POST;
				Request.contentType = 'application/octet-stream';					
				Request.data = mp3encoder.mp3Data;
				loader.addEventListener(IOErrorEvent.IO_ERROR,dataFail);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,dataFail);
				loader.addEventListener(Event.COMPLETE,dataSent);
				loader.load(Request);
			}
			else log("Nothing to save");
		}
		private function dataFail(e:Event)
		{
			log("fail"+e.toString());
		}
		private function dataSent(e:Event)
		{
			var returnedVars:URLVariables = new URLVariables(e.currentTarget.data);
			log("Return Status: "+returnedVars.status+" and the audio saved as: "+returnedVars.filename);
		}
	}
}