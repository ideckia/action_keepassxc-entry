package;

using api.IdeckiaApi;

typedef Props = {
	@:shared('keepassxc.database_path')
	@:editable("prop_database_path")
	var database_path:String;
	var database_password:String;
	@:editable("prop_entry_name")
	var entry_name:String;
	@:editable("prop_key_after_user", 'tab', ['tab', 'enter'])
	var key_after_user:String;
	@:editable("prop_user_pass_delay", 0)
	var user_pass_delay:UInt;
	@:editable("prop_cache_response", true)
	var cache_response:Bool;
}

@:name("keepassxc-entry")
@:description("action_description")
@:localize
class KeePassXCEntry extends IdeckiaAction {
	static var cached_keepassxc_password:Map<String, String> = [];

	var actionLogin:ActionLogin;

	override function init(initialState:ItemState):js.lib.Promise<ItemState> {
		if (props.database_password != null)
			cached_keepassxc_password.set(props.database_path, props.database_password);

		return super.init(initialState);
	}

	public function execute(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		core.log.debug('executing ${props.entry_name}');
		return new js.lib.Promise((resolve, reject) -> {
			loadEntry(currentState).then(actionLogin -> actionLogin.execute(currentState).then(s -> resolve(s)).catchError(e -> reject(e)))
				.catchError(e -> reject(e));
		});
	}

	override public function onLongPress(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		actionLogin = null;
		cached_keepassxc_password.remove(props.database_path);
		return execute(currentState);
	}

	function loadEntry(currentState:ItemState):js.lib.Promise<ActionLogin> {
		return new Promise<ActionLogin>((resolve, reject) -> {
			core.log.debug('loadEntry ${props.entry_name}');
			if (props.cache_response && actionLogin != null) {
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
					if (cleanData.length == 0)
						reject(error);
					else {
						var cleanArray = lineBreakEreg.split(data);
						var userPass = if (cleanArray.length == 1) {
							{username: '', password: cleanArray[0]};
						} else {
							{username: cleanArray[0], password: cleanArray[1]}
						};

						core.log.debug('Got [${props.entry_name}] entry correctly.');
						try {
							actionLogin = new ActionLogin();
							actionLogin.setup({
								username: userPass.username,
								password: userPass.password,
								key_after_user: props.key_after_user,
								user_pass_delay: props.user_pass_delay,
							}, core);
							actionLogin.init(currentState);

							resolve(actionLogin);
						} catch (e:Any) {
							core.dialog.error(Loc.error_title.tr(), Loc.error_body.tr());
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
			if (props.cache_response && cached_keepassxc_password.exists(props.database_path)) {
				resolve(cached_keepassxc_password.get(props.database_path));
				return;
			}

			core.dialog.password(Loc.write_password_title.tr(), Loc.write_password_body.tr([props.database_path])).then(resp -> {
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
