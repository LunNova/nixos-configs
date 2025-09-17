{ config, lib, ... }:
let
  cfg = config.lun.anubis;
in
{
  options.lun.anubis = {
    enable = lib.mkEnableOption "set up an anubis config that" + "specifically gets mad at crawlers that pretend to be known crawlers " + "from an unexpected address range";
  };
  config = lib.mkIf cfg.enable {
    services.anubis.defaultOptions = {
      # Intent: Allow bots which don't lie about being bots, challenge things claiming to be browsers
      # deny if address range doesn't match published range for known bots
      # Incentivizes accurate self reporting in UA
      botPolicy = {
        bots = [
          {
            name = "well-known";
            path_regex = "^/.well-known/.*$";
            action = "ALLOW";
          }
          {
            name = "favicon";
            path_regex = "^/favicon.ico$";
            action = "ALLOW";
          }
          {
            name = "robots-txt";
            path_regex = "^/robots.txt$";
            action = "ALLOW";
          }
          {
            name = "static";
            path_regex = "(^/static/|\.(js|css|xml|rss|png|webp|jpg|jpeg|md|txt)$)";
            action = "ALLOW";
          }

          # Allow Internet Archive address ranges regardless of UA
          {
            name = "internet-archive";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./internet-archive-addresses.json);
          }

          {
            name = "googlebot";
            user_agent_regex = "\\+http\\://www\\.google\\.com/bot\\.html";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./googlebot-addresses.json);
          }
          {
            name = "googlebot-challenge";
            user_agent_regex = "\\+http\\://www\\.google\\.com/bot\\.html";
            action = "DENY";
          }

          {
            name = "bingbot";
            user_agent_regex = "\\+http\\://www\\.bing\\.com/bingbot\\.htm";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./bingbot-addresses.json);
          }
          {
            name = "bingbot-challenge";
            user_agent_regex = "\\+http\\://www\\.bing\\.com/bingbot\\.htm";
            action = "DENY";
          }

          {
            name = "duckduckbot";
            user_agent_regex = "\\+http\\://duckduckgo\\.com/duckduckbot\\.html";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./duckduckbot-addresses.json);
          }
          {
            name = "duckduckbot-challenge";
            user_agent_regex = "\\+http\\://duckduckgo\\.com/duckduckbot\\.html";
            action = "DENY";
          }

          {
            name = "qwantbot";
            user_agent_regex = "\\+https\\://help\\.qwant\\.com/bot/";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./qwantbot-addresses.json);
          }
          {
            name = "qwantbot-challenge";
            user_agent_regex = "\\+https\\://help\\.qwant\\.com/bot/";
            action = "DENY";
          }

          {
            name = "kagibot";
            user_agent_regex = "\\+https\\://kagi\\.com/bot";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./kagibot-addresses.json);
          }
          {
            name = "kagibot-challenge";
            user_agent_regex = "\\+https\\://kagi\\.com/bot";
            action = "DENY";
          }

          {
            name = "marginalia";
            user_agent_regex = "search\\.marginalia\\.nu";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./marginalia-addresses.json);
          }
          {
            name = "marginalia-challenge";
            user_agent_regex = "search\\.marginalia\\.nu";
            action = "DENY";
          }

          {
            name = "mojeekbot";
            user_agent_regex = "http\\://www\\.mojeek\\.com/bot\\.html";
            action = "ALLOW";
            remote_addresses = builtins.fromJSON (builtins.readFile ./mojeekbot-addresses.json);
          }
          {
            name = "mojeekbot-challenge";
            user_agent_regex = "http\\://www\\.mojeek\\.com/bot\\.html";
            action = "DENY";
          }

          # Challenge anything that looks like a browser, including unknown bots that both
          # identify themselves as a bot and claim to be a browser
          {
            name = "generic-browser";
            user_agent_regex = "Mozilla/";
            action = "CHALLENGE";
          }

          # {
          #   name = "generic-bot";
          #   user_agent_regex = "([bB]ot|[Ss]craper|CLI|GPT|[Ss]pider|[Cc]rawler|Scrapy)";
          #   action = "ALLOW";
          # }
        ];
        dnsbl = false;
      };
      settings.DIFFICULTY = 4;
    };
  };
}
