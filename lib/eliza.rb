# frozen_string_literal: true

module Eliza
  SCRIPT_DIR = File.expand_path('../scripts/ruby', __dir__)

  def self.default_script(locale)
    case locale
    when :en
      File.read(File.join(SCRIPT_DIR, 'default_en.script'))
    when :pt
      File.read(File.join(SCRIPT_DIR, 'default_pt.script'))
    else
      raise ArgumentError, "Unsupported locale: #{locale}"
    end
  end

  class Script
    Rule = Struct.new(:keyword, :precedence, :substitute, :transforms, keyword_init: true)
    Transform = Struct.new(:decomposition, :reassemblies, keyword_init: true)
    MemoryRule = Struct.new(:keyword, :transforms, keyword_init: true)

    attr_reader :greeting, :rules, :none_rule, :memory_rule, :substitutions

    def self.parse(text)
      new(text).parse
    end

    def initialize(text = nil, greeting: nil, rules: nil, none_rule: nil, memory_rule: nil,
                   substitutions: nil)
      @text = text
      @greeting = greeting
      @rules = rules
      @none_rule = none_rule
      @memory_rule = memory_rule
      @substitutions = substitutions
    end

    def parse
      forms = Sexp.parse(@text)
      raise ArgumentError, 'Script must have at least greeting and one rule' if forms.size < 2

      greeting_tokens = forms.shift
      greeting = greeting_tokens.join(' ')

      forms.shift if forms.first == 'START'

      rules = {}
      substitutions = {}
      none_rule = nil
      memory_rule = nil

      forms.each do |form|
        keyword = form[0]
        case keyword
        when 'MEMORY'
          memory_rule = parse_memory_rule(form)
        when 'NONE'
          none_rule = parse_keyword_rule(form)
        else
          rule = parse_keyword_rule(form)
          rules[rule.keyword] = rule
          substitutions[rule.keyword] = rule.substitute if rule.substitute
        end
      end

      raise ArgumentError, 'Script missing NONE rule' unless none_rule

      self.class.new(
        nil,
        greeting: greeting,
        rules: rules,
        none_rule: none_rule,
        memory_rule: memory_rule,
        substitutions: substitutions
      )
    end

    private

    def parse_keyword_rule(form)
      keyword = form[0]
      index = 1
      substitute = nil
      precedence = 0

      if form[index] == '='
        substitute = form[index + 1]
        index += 2
      end
      if form[index].is_a?(String) && form[index].match?(/^\d+$/)
        precedence = form[index].to_i
        index += 1
      end

      transforms = []
      while index < form.size
        transform_form = form[index]
        index += 1
        next unless transform_form.is_a?(Array)

        decomposition = transform_form[0]
        reassemblies = transform_form[1..] || []
        transforms << Transform.new(decomposition: decomposition, reassemblies: reassemblies)
      end

      Rule.new(
        keyword: keyword,
        precedence: precedence,
        substitute: substitute,
        transforms: transforms
      )
    end

    def parse_memory_rule(form)
      keyword = form[1]
      transforms = form[2..].map do |pair|
        eq = pair.index('=')
        decomposition = pair[0...eq]
        reassembly = pair[(eq + 1)..]
        Transform.new(decomposition: decomposition, reassemblies: [reassembly])
      end
      MemoryRule.new(keyword: keyword, transforms: transforms)
    end
  end

  module Sexp
    module_function

    def parse(source)
      tokens = tokenize(source)
      forms = []
      forms << read(tokens) until tokens.empty?
      forms
    end

    def tokenize(source)
      content = source
                .lines
                .map { |line| line.sub(/;.*/, '') }
                .join
      content.scan(/\(|\)|[^\s()]+/)
    end

    def read(tokens)
      token = tokens.shift
      return token if token != '('

      list = []
      until tokens.first == ')'
        raise ArgumentError, 'Unbalanced script parentheses' if tokens.empty?

        list << read(tokens)
      end
      tokens.shift
      list
    end
  end

  class Bot
    REFLECTIONS = {
      en: {
        'I' => 'YOU', 'ME' => 'YOU', 'MY' => 'YOUR', 'AM' => 'ARE',
        'YOU' => 'I', 'YOUR' => 'MY', 'ARE' => 'AM'
      },
      pt: {
        'EU' => 'VOCE', 'ME' => 'VOCE', 'MEU' => 'SEU', 'MINHA' => 'SUA',
        'SOU' => 'E', 'VOCE' => 'EU', 'SEU' => 'MEU', 'SUA' => 'MINHA'
      }
    }.freeze

    def self.from_script(text, locale: :en)
      new(script: Script.parse(text), locale: locale)
    end

    def self.default(locale: :en)
      from_script(Eliza.default_script(locale), locale: locale)
    end

    def initialize(script:, locale: :en)
      raise ArgumentError, "Unsupported locale: #{locale}" unless REFLECTIONS.key?(locale)

      @script = script
      @locale = locale
      @response_index = Hash.new(0)
      @limit = 1
      @memory_stack = []
    end

    attr_reader :script

    def reply(input)
      raw_words = normalize(input.to_s)
      @limit = (@limit % 4) + 1
      return maybe_memory_or_none(raw_words) if raw_words.empty?

      words, keywords = scan_input(raw_words)
      return maybe_memory_or_none(words) if keywords.empty?

      keywords.each do |keyword|
        maybe_create_memory(words, keyword)
        response = apply_rule(@script.rules[keyword], words)
        return response if response
      end

      apply_rule(@script.none_rule, words) || 'PLEASE CONTINUE'
    end

    private

    def normalize(text)
      text.upcase.gsub(/[^A-Z0-9'\s]/, ' ').gsub(/\s+/, ' ').strip.split
    end

    def scan_input(raw_words)
      words = []
      keystack = []
      top_rank = 0

      raw_words.each do |raw_word|
        substituted_word = @script.substitutions.fetch(raw_word, raw_word)
        words << substituted_word

        [raw_word, substituted_word].uniq.each do |candidate|
          rule = @script.rules[candidate]
          next unless rule && !rule.transforms.empty?
          next if keystack.include?(candidate)

          if rule.precedence > top_rank
            keystack.unshift(candidate)
            top_rank = rule.precedence
          else
            keystack << candidate
          end
        end
      end

      [words, keystack]
    end

    def maybe_create_memory(words, keyword)
      memory = @script.memory_rule
      return unless memory && memory.keyword == keyword

      memory.transforms.each do |transform|
        captures = match_decomposition(transform.decomposition, words)
        next unless captures

        @memory_stack << assemble(transform.reassemblies.first, captures)
        break
      end
    end

    def maybe_memory_or_none(words)
      return @memory_stack.shift if @limit == 4 && !@memory_stack.empty?

      apply_rule(@script.none_rule, words) || 'PLEASE CONTINUE'
    end

    def apply_rule(rule, words)
      rule.transforms.each do |transform|
        captures = match_decomposition(transform.decomposition, words)
        next unless captures

        template = rotate(rule.keyword, transform.reassemblies)
        if template == ['NEWKEY']
          return nil
        elsif template.first == '=' || (template.size == 1 && template.first.start_with?('='))
          linked_key = if template.first == '='
                         template[1]
                       else
                         template.first[1..]
                       end
          linked = @script.rules[linked_key]
          return apply_rule(linked, words) if linked

          next
        end

        return assemble(template, captures)
      end
      nil
    end

    def rotate(key, options)
      index = @response_index[key] % options.size
      @response_index[key] += 1
      options[index]
    end

    def assemble(template, captures)
      out = template.flat_map do |token|
        if token.match?(/^\d+$/)
          idx = token.to_i - 1
          segment = captures[idx] || []
          reflect_words(segment)
        else
          [token]
        end
      end
      out.join(' ').gsub(/\s+/, ' ').strip
    end

    def reflect_words(words)
      words.map { |w| REFLECTIONS[@locale].fetch(w, w) }
    end

    def match_decomposition(pattern, words)
      backtrack_match(pattern, 0, words, 0, [])
    end

    def backtrack_match(pattern, pi, words, wi, captures)
      if pi == pattern.size
        return wi == words.size ? captures : nil
      end

      token = pattern[pi]
      if token.match?(/^\d+$/)
        count = token.to_i
        if count.zero?
          (wi..words.size).each do |end_index|
            c = captures + [words[wi...end_index]]
            result = backtrack_match(pattern, pi + 1, words, end_index, c)
            return result if result
          end
          nil
        else
          return nil if wi + count > words.size

          c = captures + [words[wi...(wi + count)]]
          backtrack_match(pattern, pi + 1, words, wi + count, c)
        end
      else
        return nil if wi >= words.size || words[wi] != token

        c = captures + [[token]]
        backtrack_match(pattern, pi + 1, words, wi + 1, c)
      end
    end
  end
end
