require 'fluent/parser'

module Fluent
    class TextParser
        class AuditdLogParser < Parser

            Plugin.register_parser("auditd", self)
            config_param :separator, :string, :default => "_"

            def configure(conf)
                @time_parser = TimeParser.new("%s.%L")
            end

            def parse(message)
                re = '^type=([^ ]+)\s+msg=audit\((\d+\.\d+):(\d+)\):\s+(.*)'
                _, evtype, time, audit_counter, audit_msg = message.match(re).to_a

                time = @time_parser.parse(time)
                kv = parsekv(audit_msg)
                kv['event_type'] = evtype
                kv['audit_counter'] = audit_counter
                kv['message'] = audit_msg
                yield time, kv
            end

            def parsekv(message)
                kv_map = {}
                state = 0           # 0=name,1=value
                escaped = FALSE     # Flag to check if previous char was backslash
                quoted = FALSE      # Flag to check if reading quoted string
                quote = ''          # Qoute character single (') or double (")
                name = ''           # Current name
                value = ''          # Current value

                message.split("").each do |c|
                    if state == 0
                        if c == '='
                            state = 1
                        elsif c == ' '
                            name = ''
                        else
                            name.concat(c)
                        end
                    else
                        if quoted
                            if quote == c
                                quoted = FALSE
                                quote = ''
                            else
                                value.concat(c)
                            end
                        else
                            if c == ' '
                                kv_map[name] = value
                                value_kv_map = parsekv(value)
                                value_kv_map.each_pair do |k, v|
                                    kv_map[name + @separator + k] = v
                                end
                                state = 0
                                value = ''
                                name = ''
                            elsif value == "" && c == "'"
                                quoted = TRUE
                                quote = "'"
                            elsif value == "" && c == '"'
                                quoted = TRUE
                                quote = '"'
                            else
                                value.concat(c)
                            end
                        end
                    end
                end

                if state == 1
                    kv_map[name] = value
                    value_kv_map = parsekv(value)
                    value_kv_map.each_pair do |k, v|
                        kv_map[name + @separator + k] = v
                    end
                end

                return kv_map
            end
        end
    end
end
