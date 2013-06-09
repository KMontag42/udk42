/*=============================================================================
	AS3UnitTest.as: Unit test to verify ActionScript 3 GFx functionality.
	
	Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
=============================================================================*/
package com.scaleform.unittests
{
	// Flash imports
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.external.ExternalInterface;

	// GFx imports
	import scaleform.clik.core.UIComponent;
	import scaleform.clik.controls.ScrollBar;
	import scaleform.clik.controls.ScrollingList;
	import scaleform.clik.data.DataProvider;
	
	public class AS3UnitTest extends UIComponent
	{
		// Stage variables
		// Text showing unit test status (pass/fail)
		public var StatusText:TextField;
		
		// List of successful unit tests
		public var SuccessList:ScrollingList;
		
		// List of failed unit tests
		public var FailedList:ScrollingList;
		
		// Scroll bar for the successful unit test list
		public var SuccessScroll:ScrollBar;
		
		// Scroll bar for the failed unit tests list
		public var FailScroll:ScrollBar;
		
		// Non-stage variables
		// Array to hold the tests which are successful
		public var SuccessArray:Array = new Array();
		
		// Array to hold the tests which have failed
		public var FailArray:Array = new Array();
		
		// Function pointer that will be set via UnrealScript for testing delegate functionality
		public static var Callback_DelegateTest:Function;
		
		// UnrealScript test identifiers (AS doesn't have enums, could eventually turn all of this into an associative array with a custom class)
		public static const INT_PARAM_TEST:int = 0;								// UE3 -> AS3 Integer parameter passing
		public static const INT_PARAM_INVOKE_TEST:int = 1;						// UE3 -> AS3 Integer parameter passing via invoke
		public static const UINT_PARAM_TEST:int = 2;							// UE3 -> AS3 Unsigned integer parameter passing
		public static const UINT_PARAM_TEST_INVOKE:int = 3;						// UE3 -> AS3 Unsigned integer parameter passing via invoke
		public static const NUM_PARAM_TEST:int = 4;								// UE3 -> AS3 Number/float parameter passing
		public static const NUM_PARAM_TEST_INVOKE:int = 5;						// UE3 -> AS3 Number/float parameter passing via invoke
		public static const BOOL_PARAM_TEST:int = 6;							// UE3 -> AS3 Boolean parameter passing
		public static const BOOL_PARAM_TEST_INVOKE:int = 7;						// UE3 -> AS3 Boolean parameter passing via invoke
		public static const STRING_PARAM_TEST:int = 8;							// UE3 -> AS3 String parameter passing
		public static const STRING_PARAM_TEST_INVOKE:int = 9;					// UE3 -> AS3 String parameter passing via invoke
		public static const MIXED_PARAM_TEST:int = 10;							// UE3 -> AS3 Multiple parameter passing with multiple types
		public static const MIXED_PARAM_TEST_INVOKE:int = 11;					// UE3 -> AS3 Multiple parameter passing with multiple types via invoke
		public static const ARRAY_PARAM_TEST:int = 12;							// UE3 -> AS3 Array parameter passing
		public static const STRUCT_PARAM_TEST:int = 13;							// UE3 -> AS3 Struct parameter passing
		public static const INT_RETURN_VAL_PART1_TEST:int = 14;					// UE3 -> AS3 Integer return value verification - initial function call confirmation
		public static const INT_RETURN_VAL_PART2_TEST:int = 15;					// UE3 -> AS3 Integer return value verification - confirmation of correct return value
		public static const NUMBER_RETURN_VAL_PART1_TEST:int = 16;				// UE3 -> AS3 Number/float return value verification - initial function call confirmation
		public static const NUMBER_RETURN_VAL_PART2_TEST:int = 17;				// UE3 -> AS3 Number/float return value verification - confirmation of correct return value
		public static const STRING_RETURN_VAL_PART1_TEST:int = 18;				// UE3 -> AS3 String return value verification - initial function call confirmation
		public static const STRING_RETURN_VAL_PART2_TEST:int = 19;				// UE3 -> AS3 String return value verification - confirmation of correct return value
		public static const OBJ_RETURN_VAL_PART1_TEST:int = 20;					// UE3 -> AS3 Object return value verification - initial function call confirmation
		public static const OBJ_RETURN_VAL_PART2_TEST:int = 21;					// UE3 -> AS3 Object return value verification - confirmation of correct return value
		public static const OBJ_ARRAY_RETURN_VAL_PART1_TEST:int = 22;			// UE3 -> AS3 Array of objects return value verification - initial function call confirmation
		public static const OBJ_ARRAY_RETURN_VAL_PART2_TEST:int = 23;			// UE3 -> AS3 Array of objects return value verification - confirmation of correct return value
		public static const ARRAY_AS_OBJ_RETURN_VAL_PART1_TEST:int = 24;		// UE3 -> AS3 Array as an object return value verification - initial function call confirmation
		public static const ARRAY_AS_OBJ_RETURN_VAL_PART2_TEST:int = 25;		// UE3 -> AS3 Array as an object return value verification - confirmation of correct return value
		public static const DELEGATE_PART1_TEST:int = 26;						// UE3 -> AS3 Delegate test - setting delegate
		public static const DELEGATE_PART2_TEST:int = 27;						// UE3 -> AS3 Delegate test - confirmation of delegate called
		
		// Generous value for machine epsilon to compare floating point values
		// Note that ActionScript's Number class is double-precision, while floating-point values from GFx/UE3 are single-precision!
		public static const EPSILON:Number = 0.0001;
		
		// Array to track tests received from UnrealScript; Used to verify that all tests were successfully completed and received from the UE3 side of things
		// Corresponds directly to the test identifiers above; Should likely turn all of them to be in an associative array by ID
		public var TestReceivedArray:Array = 
		[
			{ TestName:"UEScript -> AS Parameter Passing: Integer", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Integer via Invoke", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Unsigned Integer", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Unsigned Integer via Invoke", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Number", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Number via Invoke", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Boolean", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Boolean via Invoke", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: String", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: String via Invoke", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Multiple Mixed Types", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Multiple Mixed Types via Invoke", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Array", bReceived:false },
			{ TestName:"UEScript -> AS Parameter Passing: Struct", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Integer (Function Call)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Integer (Verification)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Number (Function Call)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Number (Verification)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: String (Function Call)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: String (Verification)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Object (Function Call)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Object (Verification)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Object Array (Function Call)", bRecevied:false },
			{ TestName:"UEScript -> AS Return Value Verification: Object Array (Verification)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Array as Object (Function Call)", bReceived:false },
			{ TestName:"UEScript -> AS Return Value Verification: Array as Object (Verification)", bReceived:false },
			{ TestName:"UEScript -> AS Delegate Setting (Part One)", bReceived:false },
			{ TestName:"UEScript -> AS Delegate Setting (Part Two)", bReceived:false }
		];
		
		// Test values for various data types to check against UE3 provided values (which should be the same)
		// NOTE: If you change *any* of these, change their corresponding part in UnrealScript or unit tests will fail.
		public static const TestInt:int = -225;
		public static const TestUInt:uint = 100; 
		public static const TestNum:Number = 175.75;
		public static const TestBool:Boolean = true;
		public static const TestString:String = "Hello, World!";
		public static const TestArray:Array = new Array( 255.25, 105.2, 2.66 );
		public static const TestStruct:Object = { BoolMember1:true, BoolMember2:true, BoolMember3:true, FloatMember1:255.25, FloatMember2:105.2, FloatMember3:2.66, StringMember1:"Hello, World!" };
		public static const TestObjectArray:Array = [ {FloatMember1:255.25}, {FloatMember1:105.2}, {FloatMember1:2.66} ];
		
		/** Enable initialization callbacks on the unit test so that UnrealScript can know when it's been initialized */
		override protected function preInitialize():void
		{
			enableInitCallback = true;
			super.preInitialize();
		}
		
		/** Called via UnrealScript after initialization; Runs all of the unit tests */
		public function Callback_RunUnitTest():void
		{
			// Run the AS3 -> UE3 external interface tests
			RunExternalInterfaceTests();
			
			// Run the UE3 -> AS3 tests
			RunUnrealScriptTests();
			
			if ( FailArray.length > 0 )
			{
				StatusText.text = "FAILED";
				StatusText.textColor = 0xFF0000;
			}
			else
			{
				StatusText.text = "SUCCESS";
				StatusText.textColor = 0x00FF00;
			}
		}
		
		/** Called via UnrealScript to signify the end of the UnrealScript-based tests */
		public function Callback_EndUnrealScriptTests():void
		{
			// Verify all of the UnrealScript-based tests were received. If any are missing, the
			// unit test has failed.
			for ( var Idx:int = 0; Idx < TestReceivedArray.length; ++Idx )
			{
				if ( !TestReceivedArray[Idx].bReceived )
				{
					MarkTestFailed( TestReceivedArray[Idx].TestName );
				}
			}
			
			// Populate the lists now that the tests are complete
			FailedList.dataProvider = new DataProvider( FailArray );
			SuccessList.dataProvider = new DataProvider( SuccessArray );
		}
		
		/**
		 * Helper function to mark a specified test name as failed
		 * 
		 * @param TestName	Name of the test that failed
		 */
		public function MarkTestFailed( TestName:String ):void
		{
			var FailObj:Object = new Object();
			FailObj.label = TestName;
			FailArray.push( FailObj );
		}
		
		/**
		 * Helper function to mark a specified test name as successful
		 * 
		 * @param TestName	Name of the test that was successful
		 */
		public function MarkTestSuccessful( TestName:String ):void
		{
			var PassObj:Object = new Object();
			PassObj.label = TestName;
			SuccessArray.push( PassObj );
		}
		
		/**
		 * Helper function to validate an AS3 -> UE3 external interface call
		 * 
		 * @param TestName			Name of the text being validated
		 * @param FunctionName		Name of the function sent to the external interface
		 * @param FunctionReturnVal	Return value of the external interface call, if any
		 */
		public function ValidateExternalInterfaceTest( TestName:String, FunctionName:String, FunctionReturnVal:* ):void
		{
			var FunctionReturnValueAsBool:Boolean = false;

			// If the function returned null, then we couldn't find the function in UE3! Disaster!
			if ( FunctionReturnVal == null )
			{
				trace( "ExternalInterface.call() failed: Couldn't find function named: " + FunctionName );
			}
			// If the function did return a value, all of the external interface tests expect it to return a bool indicating success or failure
			else
			{
				FunctionReturnValueAsBool = Boolean(FunctionReturnVal);
			}
	
			if ( FunctionReturnValueAsBool )
			{
				MarkTestSuccessful( TestName );
			}
			else
			{
				MarkTestFailed( TestName ); 
			}
			
		}
		
		/** Helper function to run all of the AS3 -> UE3 external interface tests */
		public function RunExternalInterfaceTests():void
		{	
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Integer", "Callback_IntParam", ExternalInterface.call( "Callback_IntParam", TestInt ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Unsigned Integer", "Callback_UIntParam", ExternalInterface.call( "Callback_UIntParam", TestUInt ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Number", "Callback_NumParam", ExternalInterface.call( "Callback_NumParam", TestNum ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Boolean", "Callback_BoolParam", ExternalInterface.call( "Callback_BoolParam", TestBool ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: String", "Callback_StringParam", ExternalInterface.call( "Callback_StringParam", TestString ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Multiple Mixed Types", "Callback_MixedParam", ExternalInterface.call( "Callback_MixedParam", TestNum, TestBool, TestString ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Array", "Callback_ArrayParam", ExternalInterface.call( "Callback_ArrayParam", TestArray ) );
			ValidateExternalInterfaceTest( "AS -> UEScript Parameter Passing: Struct", "Callback_StructParam", ExternalInterface.call( "Callback_StructParam", TestStruct ) );
		}
		
		/**
		 * Helper function to validate a UE3 -> AS3 test
		 * 
		 * @param TestName	Name of the test being validated
		 * @param TestIdx	ID/Index of the test being validated
		 * @param Success	Whether the test was successful or not
		 */
		public function ValidateUnrealScriptTest( TestName:String, TestIdx:int, Success:Boolean ):void
		{
			// If the test is being validated, then it's been received, so it should be marked as such
			TestReceivedArray[TestIdx].bReceived = true;
			
			if ( Success )
			{
				MarkTestSuccessful( TestName );
			}
			else
			{
				MarkTestFailed( TestName );
			}
		}
		
		/**
		 * Helper function to compare two numbers against the machine epsilon value; Especially necessary due to the unavoidable single<->double precision conversion
		 * resulting from going UE3<->AS3.
		 * 
		 * @param Num1	First number to compare
		 * @param Num2	Second number to compare
		 * 
		 * @return Whether the two numbers are "equal" within the machine epsilon tolerance
		 */
		public function AreNumsEqual( Num1:Number, Num2:Number ):Boolean
		{
			return Math.abs( Num1 - Num2 ) < EPSILON;
		}
		
		/** AS3 -> UE3: Kick off all of the UnrealScript tests */
		public function RunUnrealScriptTests():void
		{
			ValidateExternalInterfaceTest( "UEScript -> AS Test Initialization", "Callback_RunUnrealScriptTests", ExternalInterface.call( "Callback_RunUnrealScriptTests" ) );
		}
		
		/** UE3 -> AS3: Forcibly call a delegate, which will later be confirmed by a separate callback (this will be called after the delegate is set in AS3) */
		public function Callback_ForceCallDelegate():void
		{
			ValidateUnrealScriptTest( TestReceivedArray[DELEGATE_PART1_TEST].TestName, DELEGATE_PART1_TEST, true );
			this["Callback_DelegateTest"]();
		}
		
		/** UE3 -> AS3: Called when the UE3 delegate function that was hooked up to AS3 is called, thereby confirming the functionality is working */
		public function Callback_DelegateReceived():void
		{
			ValidateUnrealScriptTest( TestReceivedArray[DELEGATE_PART2_TEST].TestName, DELEGATE_PART2_TEST, true );
		}
		
		/** 
		 * UE3 -> AS3: Call a function with an integer parameter to verify parameter passing
		 * 
		 * @param IntParam	Parameter to verify
		 */
		public function Callback_IntParam( IntParam:int ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[INT_PARAM_TEST].TestName, INT_PARAM_TEST, IntParam == TestInt );
		}
		
		/**
		 * UE3 -> AS3: Call a function with an integer parameter via the UE3 Invoke implementation to verify parameter passing
		 * 
		 * @param IntParam	Parameter to verify
		 */
		public function Callback_IntParamInvoke( IntParam:int ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[INT_PARAM_INVOKE_TEST].TestName, INT_PARAM_INVOKE_TEST, IntParam == TestInt );
		}
		
		/**
		 * UE3 -> AS3: Call a function with an unsigned integer parameter to verify parameter passing
		 * 
		 * @param UIntParam	Parameter to verify
		 */
		public function Callback_UIntParam( UIntParam:uint ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[UINT_PARAM_TEST].TestName, UINT_PARAM_TEST, UIntParam == TestUInt );
		}
		
		/**
		 * UE3 -> AS3: Call a function with an unsigned integer parameter via the UE3 Invoke implementation to verify parameter passing
		 * 
		 * @param UIntParam	Parameter to verify
		 */
		public function Callback_UIntParamInvoke( UIntParam:uint ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[UINT_PARAM_TEST_INVOKE].TestName, UINT_PARAM_TEST_INVOKE, UIntParam == TestUInt );
		}
		
		/**
		 * UE3 -> AS3: Call a function with a number parameter to verify parameter passing
		 * 
		 * @param NumberParam	Parameter to verify
		 */
		public function Callback_NumberParam( NumberParam:Number ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[NUM_PARAM_TEST].TestName, NUM_PARAM_TEST, AreNumsEqual( NumberParam, TestNum ) );
		}
		
		/**
		 * UE3 -> AS3: Call a function with a number parameter via the UE3 Invoke implementation to verify parameter passing
		 * 
		 * @param NumberParam	Parameter to verify
		 */
		public function Callback_NumberParamInvoke( NumberParam:Number ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[NUM_PARAM_TEST_INVOKE].TestName, NUM_PARAM_TEST_INVOKE, AreNumsEqual( NumberParam, TestNum ) );
		}
		
		/**
		 * UE3 -> AS3: Call a function with a boolean parameter to verify parameter passing
		 * 
		 * @param BoolParam	Parameter to verify
		 */
		public function Callback_BoolParam( BoolParam:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[BOOL_PARAM_TEST].TestName, BOOL_PARAM_TEST, BoolParam == TestBool );
		}
		
		/**
		 * UE3 -> AS3: Call a function with a boolean parameter via the UE3 Invoke implementation to verify parameter passing
		 * 
		 * @param BoolParam	Parameter to verify
		 */
		public function Callback_BoolParamInvoke( BoolParam:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[BOOL_PARAM_TEST_INVOKE].TestName, BOOL_PARAM_TEST_INVOKE, BoolParam == TestBool );
		}
		
		/**
		 * UE3 -> AS3: Call a function with a string parameter to verify parameter passing
		 * 
		 * @param StringParam	Parameter to verify
		 */
		public function Callback_StringParam( StringParam:String ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[STRING_PARAM_TEST].TestName, STRING_PARAM_TEST, StringParam == TestString );
		}
		
		/**
		 * UE3 -> AS3: Call a function with a string parameter via the UE3 Invoke implementation to verify parameter passing
		 * 
		 * @param StringParam	Parameter to verify
		 */
		public function Callback_StringParamInvoke( StringParam:String ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[STRING_PARAM_TEST_INVOKE].TestName, STRING_PARAM_TEST_INVOKE, StringParam == TestString );
		}
		
		/**
		 * UE3 -> AS3: Call a function with multiple, mixed-type parameters to verify parameter passing
		 * 
		 * @param NumberParam	First parameter to verify
		 * @param BoolParam		Second parameter to verify
		 * @param StringParam	Third parameter to verify
		 */
		public function Callback_MixedParam( NumberParam:Number, BoolParam:Boolean, StringParam:String ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[MIXED_PARAM_TEST].TestName, MIXED_PARAM_TEST, AreNumsEqual( NumberParam, TestNum ) && ( BoolParam == TestBool ) && ( StringParam == TestString ) );
		}
		
		/**
		 * UE3 -> AS3: Call a function with multiple, mixed-type parameters via the UE3 Invoke implementation to verify parameter passing
		 * 
		 * @param NumberParam	First parameter to verify
		 * @param BoolParam		Second parameter to verify
		 * @param StringParam	Third parameter to verify
		 */
		public function Callback_MixedParamInvoke( NumberParam:Number, BoolParam:Boolean, StringParam:String ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[MIXED_PARAM_TEST_INVOKE].TestName, MIXED_PARAM_TEST_INVOKE, AreNumsEqual( NumberParam, TestNum ) && ( BoolParam == TestBool ) && ( StringParam == TestString ) );
		}
		
		/**
		 * UE3 -> AS3: Call a function with an array parameter to verify parameter passing
		 * 
		 * @param ArrayParam	Parameter to verify
		 */
		public function Callback_ArrayParam( ArrayParam:Array ):void
		{
			var bCorrectArray:Boolean = true;
			
			if ( ArrayParam.length == TestArray.length )
			{
				for ( var Idx:int = 0; Idx < ArrayParam.length; ++Idx )
				{
					if ( !AreNumsEqual( ArrayParam[Idx], TestArray[Idx] ) )
					{
						bCorrectArray = false;
						break;
					}
				}
			}
			else
			{
				bCorrectArray = false;
			}
			
			ValidateUnrealScriptTest( TestReceivedArray[ARRAY_PARAM_TEST].TestName, ARRAY_PARAM_TEST, bCorrectArray );
		}
		
		/**
		 * UE3 -> AS3: Call a function with an object parameter to verify parameter passing
		 * 
		 * @param StructParam	Parameter to verify
		 */
		public function Callback_StructParam( StructParam:Object ):void
		{
			var bCorrectObj:Boolean = true;
			
			// Make sure the object has all the properties the UE3 side expects
			if ( StructParam == null || 
				!StructParam.hasOwnProperty( "BoolMember1" ) || 
				!StructParam.hasOwnProperty( "BoolMember2" ) ||
				!StructParam.hasOwnProperty( "BoolMember3" ) ||
				!StructParam.hasOwnProperty( "FloatMember1" ) ||
				!StructParam.hasOwnProperty( "FloatMember2" ) ||
				!StructParam.hasOwnProperty( "FloatMember3" ) ||
				!StructParam.hasOwnProperty( "StringMember1" ) )
			{
				bCorrectObj = false;
			}
			else
			{
				if ( StructParam.BoolMember1 != TestBool || StructParam.BoolMember2 != TestBool || StructParam.BoolMember3 != TestBool ||
					!AreNumsEqual( StructParam.FloatMember1, TestArray[0] ) || !AreNumsEqual( StructParam.FloatMember2, TestArray[1] ) ||
					!AreNumsEqual( StructParam.FloatMember3, TestArray[2] ) || StructParam.StringMember1 != TestString )
					{
						bCorrectObj = false;
					}
				 
			}
			
			ValidateUnrealScriptTest( TestReceivedArray[STRUCT_PARAM_TEST].TestName, STRUCT_PARAM_TEST, bCorrectObj );
		}
		
		/**
		 * UE3 -> AS3: Part one of a two-part verification of the return value of an AS3 function returning an integer. Called when UE3 uses this function
		 * with ActionScriptInt().
		 * 
		 * @return	Integer test value that will be verified on the UE3 side
		 */
		public function Callback_IntReturnVal():int
		{
			ValidateUnrealScriptTest( TestReceivedArray[INT_RETURN_VAL_PART1_TEST].TestName, INT_RETURN_VAL_PART1_TEST, true );
			return TestInt;
		}
		
		/**
		 * UE3 -> AS3: Part two of a two-part verification of the return value of an AS3 function returning an integer. Called when UE3 checks the return value
		 * of part one and sends in a parameter specifiying if the return value was verified or not.
		 * 
		 * @param ReturnValVerified	Whether the return value of part one of the test was successfully verified by UE3 or not
		 */
		public function Callback_IntReturnValVerification( ReturnValVerified:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[INT_RETURN_VAL_PART2_TEST].TestName, INT_RETURN_VAL_PART2_TEST, ReturnValVerified );
		}
		
		/**
		 * UE3 -> AS3: Part one of a two-part verification of the return value of an AS3 function returning a number. Called when UE3 uses this function with
		 * ActionScriptFloat().
		 * 
		 * @return	Number test value that will be verified on the UE3 side
		 */
		public function Callback_NumberReturnVal():Number
		{
			ValidateUnrealScriptTest( TestReceivedArray[NUMBER_RETURN_VAL_PART1_TEST].TestName, NUMBER_RETURN_VAL_PART1_TEST, true );
			return TestNum;
		}
		
		/**
		 * UE3 -> AS3: Part two of a two-part verification of the return value of an AS3 function returning a number. Called when UE3 checks the return value
		 * of part one and sends in a parameter specifying if the return value was verified or not.
		 * 
		 * @param ReturnValVerified	Whether the return value of part one of the test was successfully verified by UE3 or not
		 */
		public function Callback_NumberReturnValVerification( ReturnValVerified:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[NUMBER_RETURN_VAL_PART2_TEST].TestName, NUMBER_RETURN_VAL_PART2_TEST, ReturnValVerified );
		}
		
		/**
		 * UE3 -> AS3: Part one of a two-part verification of the return value of an AS3 function returning a string. Called when UE3 uses this function
		 * with ActionScriptString().
		 * 
		 * @return	String test value that will be verified on the UE3 side
		 */
		public function Callback_StringReturnVal():String
		{
			ValidateUnrealScriptTest( TestReceivedArray[STRING_RETURN_VAL_PART1_TEST].TestName, STRING_RETURN_VAL_PART1_TEST, true );
			return TestString;
		}
		
		/**
		 * UE3 -> AS3: Part two of a two-part verification of the return value of an AS3 function returning a string. Called when UE3 checks the return value
		 * of part one and sends in a parameter specifying if the return value was verified or not.
		 * 
		 * @param ReturnValVerified	Whether the return value of part one of the test was successfully verified by UE3 or not
		 */
		public function Callback_StringReturnValVerification( ReturnValVerified:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[STRING_RETURN_VAL_PART2_TEST].TestName, STRING_RETURN_VAL_PART2_TEST, ReturnValVerified );
		}
		
		/**
		 * UE3 -> AS3: Part one of a two-part verification of the return value of an AS3 function returning an object. Called when UE3 uses this function with
		 * ActionScriptObject().
		 * 
		 * @return Object test value that will be verified on the UE3 side
		 */
		public function Callback_ObjectReturnVal():Object
		{
			ValidateUnrealScriptTest( TestReceivedArray[OBJ_RETURN_VAL_PART1_TEST].TestName, OBJ_RETURN_VAL_PART1_TEST, true );
			return TestStruct;
		}
		
		/**
		 * UE3 -> AS3: Part two of a two-part verification of the return value of an AS3 function returning an object. Called when UE3 checks the return value of
		 * part one and sends in a parameter specifying if the return value was verified or not.
		 * 
		 * @param ReturnValVerified	Whether the return value of part one of the test was successfully verified by UE3 or not
		 */
		public function Callback_ObjectReturnValVerification( ReturnValVerified:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[OBJ_RETURN_VAL_PART2_TEST].TestName, OBJ_RETURN_VAL_PART2_TEST, ReturnValVerified );
		}
		
		/**
		 * UE3 -> AS3: Part one of a two-part verification of the return value of an AS3 function returning an object array. Called when UE3 uses this function with
		 * ActionScriptArray().
		 * 
		 * @return Object array test value that will be verified on the UE3 side
		 */
		public function Callback_ObjArrayReturnVal():Array
		{
			ValidateUnrealScriptTest( TestReceivedArray[OBJ_ARRAY_RETURN_VAL_PART1_TEST].TestName, OBJ_ARRAY_RETURN_VAL_PART1_TEST, true );
			return TestObjectArray;
		}
		
		/**
		 * UE3 -> AS3: Part two of a two-part verification of the return value of an AS3 function returning an object array. Called when UE3 checks the return value of
		 * part one and sends in a parameter specifying if the return value was verified or not.
		 * 
		 * @param ReturnValVerified	Whether the return value of part one of the test was successfully verified by UE3 or not
		 */
		public function Callback_ObjArrayReturnValVerification( ReturnValVerified:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[OBJ_ARRAY_RETURN_VAL_PART2_TEST].TestName, OBJ_ARRAY_RETURN_VAL_PART2_TEST, ReturnValVerified );
		}
		
		/**
		 * UE3 -> AS3: Part one of a two-part verification of the return value of an AS3 function returning an object which is an array. Called when UE3 uses this function with
		 * ActionScriptObject().
		 * 
		 * @return Object test value that will be verified on the UE3 side
		 */
		public function Callback_ArrayAsObjReturnVal():Array
		{
			ValidateUnrealScriptTest( TestReceivedArray[ARRAY_AS_OBJ_RETURN_VAL_PART1_TEST].TestName, ARRAY_AS_OBJ_RETURN_VAL_PART1_TEST, true );
			return TestArray;
		}
		
		/**
		 * UE3 -> AS3: Part two of a two-part verification of the return value of an AS3 function returning an object which is an array. Called when UE3 checks the return value of
		 * part one and sends in a parameter specifying if the return value was verified or not.
		 * 
		 * @param ReturnValVerified	Whether the return value of part one of the test was successfully verified by UE3 or not
		 */
		public function Callback_ArrayAsObjReturnValVerification( ReturnValVerified:Boolean ):void
		{
			ValidateUnrealScriptTest( TestReceivedArray[ARRAY_AS_OBJ_RETURN_VAL_PART2_TEST].TestName, ARRAY_AS_OBJ_RETURN_VAL_PART2_TEST, ReturnValVerified );
		}
	}
}