using api.IdeckiaApi;

@:jsRequire("../log-in", "IdeckiaAction")
extern class ActionLogin {
	function new();
	function setup(props:Any, core:IdeckiaCore):Any;
	function init(state:Any):js.lib.Promise<ItemState>;
	function execute(state:Any):js.lib.Promise<ActionOutcome>;
}
