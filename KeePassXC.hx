package;

import haxe.ds.Option;

using api.IdeckiaApi;

typedef Props = {
	@:editable("The path to the database")
	@:shared
	var database_path:String;
	@:editable("The name of the entry to retrieve")
	var entry_name:String;
	@:editable("Writes 'username'->key_after_user->'password'->'enter'", 'tab', ['tab', 'enter'])
	var key_after_user:String;
	@:editable("Milliseconds to wait between username and password", 0)
	var user_pass_delay:UInt;
	@:editable("Cache KeePassXC response in memory on initialization.", true)
	var cache_on_init:Bool;
	@:editable("Ask for KeePassXC password every time.", false)
	var ask_keepass_password_every_time:Bool;
}

@:name("keepassxc")
@:description("Get entries from keepassxc application")
class KeePassXC extends IdeckiaAction {
	static var cached_keepassxc_password:Map<String, String> = [];

	var actionLogin:ActionLogin;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		if (props.cache_on_init) {
			loadEntry(initialState).catchError(error -> server.log.error('Error getting [${props.entry_name}] entry: $error'));
		}

		return super.init(initialState);
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			loadEntry(currentState).then(actionLogin -> actionLogin.execute(currentState).then(s -> resolve(s)).catchError(e -> reject(e)));
		});
	}

	override public function onLongPress(currentState:ItemState):js.lib.Promise<ItemState> {
		actionLogin = null;
		cached_keepassxc_password.remove(props.database_path);
		return execute(currentState);
	}

	function loadEntry(currentState:ItemState):js.lib.Promise<ActionLogin> {
		return new Promise<ActionLogin>((resolve, reject) -> {
			if (!props.ask_keepass_password_every_time && actionLogin != null) {
				resolve(actionLogin);
				return;
			}

			var args = [];
			args.push('show');
			args.push('-q');
			args.push('-sa username');
			args.push('-sa password');
			args.push(props.database_path);
			args.push(props.entry_name);
			var cp = js.node.ChildProcess.spawn('keepassxc-cli', args, {shell: true});

			var data = '';
			var error = '';

			getKeePassXCPassword().then(password -> {
				cp.stdin.write(password + '\n');

				cp.stdout.on('data', d -> data += d);
				cp.stdout.on('end', d -> {
					var lineBreakEreg = ~/\r?\n/g;
					var cleanData = lineBreakEreg.replace(data, '');
					if (error != '' || cleanData.length == 0)
						reject(error);
					else {
						var cleanArray = lineBreakEreg.split(data);
						var userPass = if (cleanArray.length == 1) {
							{username: '', password: cleanArray[0]};
						} else {
							{username: cleanArray[0], password: cleanArray[1]}
						};

						server.log.debug('Got [${props.entry_name}] entry correctly. [$userPass]');
						try {
							actionLogin = new ActionLogin();
							actionLogin.setup({
								username: userPass.username,
								password: userPass.password,
								key_after_user: props.key_after_user,
								user_pass_delay: props.user_pass_delay,
							}, server);
							actionLogin.init(currentState);

							resolve(actionLogin);
						} catch (e:Any) {
							server.dialog.error('KeePassXC action',
								'Could not load the action "log-in" from actions folder. You can download it from https://github.com/ideckia/action_log-in/releases/tag/v1.0.0');
						}
					}
				});
				cp.stderr.on('data', e -> error += e);
				cp.stderr.on('end', e -> {
					if (error != '')
						reject(error);
				});

				cp.on('error', (error) -> {
					reject(error);
				});
			}).catchError(reject);
		});
	}

	function getKeePassXCPassword() {
		return new js.lib.Promise((resolve, reject) -> {
			if (!props.ask_keepass_password_every_time && cached_keepassxc_password.exists(props.database_path)) {
				resolve(cached_keepassxc_password.get(props.database_path));
				return;
			}
			server.dialog.password('KeePassXC [${props.database_path}] file password', 'Write the KeePassXC [${props.database_path}] file password, please')
				.then(resp -> {
					switch resp {
						case Some(v):
							cached_keepassxc_password.set(props.database_path, v.password);
							resolve(v.password);
						case None:
							reject('No password provided');
					}
				});
		});
	}
}

typedef UserPass = {
	var username:String;
	var password:String;
}
