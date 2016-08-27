package states;

import extension.notifications.Notifications;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.events.Event;

class PlayState extends FlxState {
	private var eventText:FlxText; // Event log text in top left of screen
	private var notificationButtons:Array<BigButton> = []; // Buttons to manage/cancel notifications in top right of the screen
	
	/**
	 * Setup the demo state
	 */
	override public function create():Void {
		super.create();
		bgColor = FlxColor.BLACK;
		
		eventText = new FlxText();
		add(eventText);
		
		addText("Will setup bindings...");
		#if (android || ios)
		Notifications.init();
		#end
		addText("Did setup bindings...");
		
		Lib.current.stage.addEventListener(Event.ACTIVATE, function(p:Dynamic):Void {
			addText("App received ACTIVATE event");
			#if (android || ios)
			addText("Current badge count is reported as: " + Notifications.getApplicationIconBadgeNumber());
			#end
		});
		Lib.current.stage.addEventListener(Event.DEACTIVATE, function(p:Dynamic):Void {
			addText("App received DEACTIVATE event");
		});
		
		var addNotificationButton = new BigButton("Add Notification", addNotification);
		addNotificationButton.screenCenter(FlxAxes.X);
		addNotificationButton.y = FlxG.height - addNotificationButton.height - 20;
		add(addNotificationButton);
		
		var clearLogButton = new BigButton("Clear Log", clearLog);
		clearLogButton.x = 100;
		clearLogButton.y = FlxG.height - clearLogButton.height - 20;
		add(clearLogButton);
		
		var clearNotificationsButton = new BigButton("Clear Notifications", cancelAllNotifications);
		clearNotificationsButton.x = FlxG.width - clearNotificationsButton.width - 100;
		clearNotificationsButton.y = FlxG.height - clearNotificationsButton.height - 20;
		add(clearNotificationsButton);
		
		var setRandomBadgeCountButton = new BigButton("Set Random Badge Count", function() {
			#if (android || ios)
			var count:Int = Std.int(Math.random() * 10);
			var success = Notifications.setApplicationIconBadgeNumber(count);
			if (success) {
				addText("Set application icon badge count to: " + count);
			} else {
				addText("Failed to set application icon badge count to: " + count);
				addText("Library issue or unsupported device?");
			}
			#end
		});
		setRandomBadgeCountButton.screenCenter(FlxAxes.XY);
		setRandomBadgeCountButton.x -= 150;
		add(setRandomBadgeCountButton);
		
		var clearBadgeCountButton = new BigButton("Clear Badge Count", function() {
			#if (android || ios)
			var success = Notifications.setApplicationIconBadgeNumber(0);
			if (success) {
				addText("Cleared application icon badge count");
			} else {
				addText("Failed to clear application icon badge count");
				addText("ShortcutBadger issue, or unsupported device?");
			}
			#end
		});
		clearBadgeCountButton.screenCenter(FlxAxes.XY);
		clearBadgeCountButton.x += 150;
		add(clearBadgeCountButton);
	}
	
	/**
	 * Create and schedule a new notification
	 */
	private function addNotification():Void {
		var notification = new Notification(180000);
		notification.schedule();
		addText("Added notification '" + notification.message + "' will fire in " + notification.delay + " milliseconds");
		
		var button = new BigButton(notification.message, function() {
			#if (android || ios)
			addText("Cancelled notification slot: " + notification.id);
			Notifications.cancelLocalNotification(notification.id);
			#end
		});
		notificationButtons.push(button);
		add(button);
	}
	
	/**
	 * Cancel all scheduled notifications
	 */
	private function cancelAllNotifications():Void {
		for (button in notificationButtons) {
			remove(button);
		}
		notificationButtons = [];
		
		#if (android || ios)
		Notifications.cancelLocalNotifications();
		#end
	}
	
	/**
	 * Update the state
	 */
	override public function update(dt:Float):Void {
		super.update(dt);
		
		for (i in 0...notificationButtons.length) {
			notificationButtons[i].x = FlxG.width - notificationButtons[i].width - 20;
			notificationButtons[i].y = i * (notificationButtons[i].height + 5);
		}
	}
	
	/**
	 * Add a message to the text event log
	 */
	private function addText(text:String):Void {
		eventText.text = text + "\n" + eventText.text;
	}
	
	/**
	 * Clear the event log
	 */
	private function clearLog():Void {
		eventText.text = "Waiting...";
	}
}

/**
 * Class to wrap notification data and local notification library methods
 */
class Notification {
	private static var notificationsCreated:Int = 0;
	
	// Maximum notification slot index.
	// Android note - see the haxelib's AndroidManifest.xml - by default we only define 0 through <action android:name="::APP_PACKAGE::.Notification9"/> on Android
	private static inline var MAX_NOTIFICATION_SLOTS:Int = 10;
	
	public var id(default, null):Int; // Unique id for counting the notifications created so far
	public var slot(default, null):Int; // Notification slot id
	public var message(default, null):String; // The notification message to display to the user
	public var delay(default, null):Int; // The delay in milliseconds between scheduling the notification and firing it
	
	/**
	 * Create a new notification
	 */
	public function new(delay:Int) {
		this.id = notificationsCreated;
		this.slot = notificationsCreated % MAX_NOTIFICATION_SLOTS;
		this.message = "Id: " + notificationsCreated + ", Slot: " + Std.string(notificationsCreated % MAX_NOTIFICATION_SLOTS) + " - " + messages[notificationsCreated % messages.length];
		this.delay = delay;
		notificationsCreated++;
	}
	
	/**
	 * Schedule the notification
	 */
	public function schedule():Void {
		#if android
		Notifications.scheduleLocalNotification(slot, delay, "Notifications Demo Android", message, "Demo Subtitle Text", "Demo Ticker Text", true);
		#elseif ios
		Notifications.scheduleLocalNotification(slot, delay, "Notifications Demo iOS", message, "Demo Action Button Text", true);
		#end
	}
	
	/**
	 * Cancel the notification
	 */
	public function cancel():Void {
		#if (android || ios)
		Notifications.cancelLocalNotification(slot);
		#end
	}
	
	// Notification messages, to say "hello" in lots of languages
	private static var messages = [
		"Albanian – Përshëndetje",
		"Armenian – Barev Dzez",
		"Bulgarian – Zdraveĭte",
		"Croatian – Bok",
		"Czech – Ahoj",
		"Danish – Hej",
		"Dutch – Hallo",
		"English – Hello",
		"Estonian – Tere",
		"Finnish – Hei",
		"French – Bonjour",
		"Georgian – Komentari",
		"German – Guten tag",
		"Greek – Geia sas",
		"Hungarian – Jó napot",
		"Icelandic – Góðan dag",
		"Italian – Ciao",
		"Latin – Salve",
		"Lithuanian – Sveiki",
		"Macedonian – Zdravo",
		"Maltese – Bonjour",
		"Norwegian – Hallo",
		"Polish – Cześć",
		"Romanian – Salut",
		"Russian – Zdravstvuyte",
		"Serbian – Zdravo",
		"Slovak – Ahoj",
		"Slovenian – Živjo",
		"Spanish – Hola",
		"Swedish – Hallå",
		"Turkish – Merhaba",
		"Ukrainian – Dobriy den"
	];
}

class BigButton extends FlxButton {
	public function new(text:String, onPress:Void->Void) {
		super(text, onPress);
		scale.set(2, 2);
		updateHitbox();
	}
}