require "ipaddr"

module Rack
  module Throttle
    class Rules < TimeWindow
      ##
      # @param  [#call]                  app
      # @param  [Hash{Symbol => Object}] options
      # @option options [Integer] :max   (1)
      def initialize(app, options = {})
        super
      end

      def rules
        @rules ||= begin
          rs = options[:rules]
          rs.sort_by { |r| [r[:proc].to_s, r[:path].to_s] }.reverse
        end
      end

      def retry_after
        @min ||= (options[:min] || 3600)
      end

      def default_limit
        @default_limit ||= options[:default] || 1_000_000_000
      end

      def ips
        @ips ||= (options[:ip_whitelist] || []).map { |ip| IPAddr.new(ip) } || []
      end

      def whitelisted?(request)
        return true if ip_whitelisted?(IPAddr.new(ip(request)))
        return true if rule_whitelisted?(request)
        false
      end

      def ip_whitelisted?(request_ip)
        !!ips.find { |ip| ip.include?(request_ip) }
      end

      def rule_whitelisted?(request)
        rule = rule_for(request)
        rule ? rule[:whitelisted] : false
      end

      def rule_for(request)
        rules.find do |rule|
          next unless rule[:method] == request.request_method.to_s
          next if rule[:proc] && rule[:proc].call(request) == false
          next if rule[:path] && !path_matches?(rule, request.path.to_s)
          rule
        end
      end

      def path_matches?(rule, path)
        return true unless rule[:path]
        return true if     path.to_s.gsub(%r{/+}, "/").match(rule[:path])
        false
      end

      def max_per_window(request)
        rule = rule_for(request)
        rule ? rule[:limit] : default_limit
      end

      def client_identifier(request)
        if (rule = rule_for(request))
          client_identifier_for_rule(request, rule)
        else
          ip(request)
        end
      end

      def client_identifier_for_rule(request, rule)
        if rule[:proc]
          "#{rule[:method]}_#{rule[:proc].call(request)}"
        elsif rule[:path]
          "#{ip(request)}_#{rule[:method]}_#{rule[:path]}"
        elsif rule[:method]
          "#{ip(request)}_#{rule[:method]}"
        else
          raise NotImplementedError
        end
      end

      def ip(request)
        request.ip.to_s
      end

      def cache_key(request)
        [super, Time.now.strftime(time_string)].join(':')
      end

      def time_string
        @time_string ||= case options[:time_window]
          when :second then '%Y-%m-%dT%H:%M:%S'
          when :minute then '%Y-%m-%dT%H:%M'
          when :hour   then '%Y-%m-%dT%H'
          when :day    then '%Y-%m-%d'
          else              '%Y-%m-%dT%H:%M:%S'
        end
      end
    end
  end
end

