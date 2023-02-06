# Action for [ideckia](https://ideckia.github.io/): keepassxc

## Description

Get entries from [KeePassXC](https://keepassxc.org/) application.

Action ['action_log-in'](http://github.com/ideckia/action_log-in) is required.

When the action is initialized, it will get the entry content and will keep it in memory. If you want to reload the entry (if you have updated it), do it with a long press.

## Properties

| Name | Type | Description | Shared | Default | Possible values |
| ----- |----- | ----- | ----- | ----- | ----- |
| database_path | String | The path to the database | true | null | null |
| entry_name | String | The name of the entry to retrieve | false | null | null |
| key_after_user | String | Writes 'username'->key_after_user->'password'->'enter' | false | 'tab' | [tab,enter] |
| user_pass_delay | UInt | Milliseconds to wait between username and password | false | 0 | null |
| cache_response | Bool | Cache KeePassXC response in memory on retrieve. | false | true | null |

## On single click

Writes the username and the password from the entry of keepassxc.

## On long press

Reload the entry value.

## Test the action

There is a script called `test_action.js` to test the new action. Set the `props` variable in the script with the properties you want and run this command:

```
node test_action.js
```

## Example in layout file

```json
{
    "state": {
        "text": "keepassxc action example",
        "actions": [
            {
                "name": "keepassxc",
                "props": {
                    "database_path": "/path/to/database.kdbx",
                    "entry_name": "my_keepassxc_entry",
                    "key_after_user": "tab",
                    "user_pass_delay": 0,
                    "cache_response": true
                }
            }
        ]
    }
}
```