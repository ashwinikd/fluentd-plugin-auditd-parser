# fluentd-plugin-auditd-parser
Fluentd Parser plugin for linux's auditd logs. This plugin works with Fluentd versions 0.12 and 1.0. The parser is recursively applied to all values found in the message (See example 1 to see how this is applied).

## Installation
Copy the file `src/parser_auditd.rb` to `/etc/(fluentd|td-agent)/plugins` directory and restart the agent. And in your config use this:

```
<source>
  @type tail
  path /var/log/audit/audit.log
  pos_file /path/to/pos/file      # higly recommended
  format auditd
  separator _                     # separator to use when recursively merging the key value pairs
  tag test.auditd.tail
</source>
```

## Example

### Example 1: Recursive parsing
Following line:
```
type=USER_ERR msg=audit(1525325850.044:1413): pid=11100 uid=0 auid=4294967295 ses=4294967295 msg='op=PAM:bad_ident acct="?" exe="/usr/sbin/sshd" hostname=a.b.c.d addr=a.b.c.d terminal=ssh res=failed'
```

is parsed to following. Notice the `msg_*` keys. Here the parser has parsed the key value pairs inside the last `msg` key of the message.
```json
{
    "msg": "op=PAM:bad_ident acct=\"?\" exe=\"/usr/sbin/sshd\" hostname=a.b.c.d addr=a.b.c.d terminal=ssh res=failed",
    "ses": "4294967295",
    "auid": "4294967295",
    "msg_hostname": "a.b.c.d",
    "msg_exe": "/usr/sbin/sshd",
    "msg_acct": "?",
    "pid": "11100",
    "audit_message": "pid=11100 uid=0 auid=4294967295 ses=4294967295 msg='op=PAM:bad_ident acct=\"?\" exe=\"/usr/sbin/sshd\" hostname=a.b.c.d addr=a.b.c.d terminal=ssh res=failed'",
    "type": "my_type",
    "audit_counter": "1413",
    "message": "type=USER_ERR msg=audit(1525325850.044:1413): pid=11100 uid=0 auid=4294967295 ses=4294967295 msg='op=PAM:bad_ident acct=\"?\" exe=\"/usr/sbin/sshd\" hostname=a.b.c.d addr=a.b.c.d terminal=ssh res=failed'",
    "fluentd_tags": "test.auditd.tail",
    "audit_time": "1525325850.044",
    "uid": "0",
    "msg_terminal": "ssh",
    "@timestamp": "2018-05-03T05:37:30.043+00:00",
    "msg_addr": "a.b.c.d",
    "msg_op": "PAM:bad_ident",
    "msg_res": "failed",
    "audit_type": "USER_ERR"
}
```

### Example 2: Non key value message

```
type=DAEMON_END msg=audit(1525253262.135:1679): auditd normal halt, sending auid=0 pid=1 subj= res=success
```

```json
{
    "res": "success",
    "auid": "0",
    "pid": "1",
    "audit_message": "auditd normal halt, sending auid=0 pid=1 subj= res=success",
    "audit_counter": "1679",
    "message": "type=DAEMON_END msg=audit(1525253262.135:1679): auditd normal halt, sending auid=0 pid=1 subj= res=success",
    "type": "my_type",
    "fluentd_tags": "test.auditd.tail",
    "audit_time": "1525253262.135",
    "@timestamp": "2018-05-02T09:27:42.134+00:00",
    "subj": "",
    "audit_type": "DAEMON_END"
}
```
