require "minitest/autorun"
require_relative "../lib/eliza"

class ElizaTest < Minitest::Test
  SCRIPT_EN = <<~SCRIPT
    (HELLO HOW ARE YOU)
    START
    (CANT = CAN)
    (CAN
      ((0)
        (=SORRY)))
    (SORRY
      ((0)
        (PLEASE DON'T APOLOGIZE)
        (APOLOGIES ARE NOT REQUIRED)))
    (I
      ((0 I FEEL 0)
        (DO YOU OFTEN FEEL 4)
        (TELL ME MORE ABOUT FEELING 4))
      ((0 I 0 YOU 0)
        (WHY DO YOU 3 ME)
        (YOU SAY I 2 YOU 4)))
    (MEMORY MY
      (0 YOUR 0 = LETS DISCUSS FURTHER WHY YOUR 3)
      (0 YOUR 0 = EARLIER YOU SAID YOUR 3)
      (0 YOUR 0 = BUT YOUR 3)
      (0 YOUR 0 = DOES THAT HAVE ANYTHING TO DO WITH THE FACT THAT YOUR 3))
    (MY = YOUR 2
      ((0 YOUR 0)
        (YOUR 3)
        (WHY DOES YOUR 3 CONCERN YOU)))
    (NONE
      ((0)
        (PLEASE CONTINUE)
        (GO ON PLEASE)))
  SCRIPT

  SCRIPT_PT = <<~SCRIPT
(OLA COMO VOCE ESTA)
START
(SINTO
((0 EU ME SINTO 0)
(POR QUE VOCE SE SENTE 5)
(FALE MAIS SOBRE SENTIR 5)))
(VOCE
((0 VOCE QUER 0)
(POR QUE VOCE QUER 4))
((0 VOCE 0 ME 0)
(POR QUE VOCE PENSA QUE EU 4 VOCE)))
(EU
((0 EU NAO 0)
(VOCE REALMENTE NAO 4)
(POR QUE VOCE NAO 4))
((0)
(VOCE DIZ EU 1)))
(MEMORY MEU
(0 SEU 0 = VAMOS DISCUTIR MAIS POR QUE SEU 3))
(MEU = SEU 2
((0 SEU 0)
(SEU 3)
(POR QUE SEU 3 PREOCUPA VOCE)))
(SEU
((0 SEU 0)
(POR QUE VOCE ESTA PREOCUPADO COM MEU 3)))
(NAO
((0)
(VOCE ESTA SENDO UM POUCO NEGATIVO)
(VOCE ESTA DIZENDO NAO SIMPLESMENTE PARA SER DIFICIL)))
(SIM
((0)
(VOCE PARECE BEM POSITIVO)
(VOCE TEM CERTEZA)))
(TODOS
((0)
(VOCE REALMENTE QUER DIZER TODOS 1)
(SEGURAMENTE NAO TODOS 1)))
(NONE
((0)
(POR FAVOR, CONTINUE)
(ME CONTE MAIS)))
SCRIPT

  def test_parses_greeting_and_rule_map
    script = Eliza::Script.parse(SCRIPT_EN)

    assert_equal("HELLO HOW ARE YOU", script.greeting)
    assert(script.rules.key?("SORRY"))
    assert_equal("NONE", script.none_rule.keyword)
  end

  def test_default_script_is_loaded_from_file
    assert_includes(Eliza.default_script(:pt), "OLA COMO VOCE ESTA CONTE SEU PROBLEMA")
    assert_includes(Eliza.default_script(:en), "HOW DO YOU DO PLEASE TELL ME YOUR PROBLEM")
  end

  def test_keyword_rule_decompose_and_reassemble
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    reply = bot.reply("I feel very tired today")

    assert_equal("DO YOU OFTEN FEEL VERY TIRED TODAY", reply)
  end

  def test_link_substitution_rule_applies_before_matching
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    reply = bot.reply("I cant know")

    assert_equal("PLEASE DON'T APOLOGIZE", reply)
  end

  def test_none_rule_rotates_when_no_keyword_matches
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    assert_equal("PLEASE CONTINUE", bot.reply("ZXCV"))
    assert_equal("GO ON PLEASE", bot.reply("QWER"))
  end

  def test_portuguese_version_works
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    reply = bot.reply("eu me sinto cansado")
    # EU rule matches first, returns "VOCE DIZ EU 1" which reflects to "VOCE DIZ EU VOCE"
    # OR one of its other responses
    assert(reply.start_with?("VOCE"), "Expected reply to start with VOCE, got: #{reply}")

    assert_equal("POR FAVOR, CONTINUE", bot.reply("..."))
  end

  def test_portuguese_eu_reflection
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal("VOCE REALMENTE NAO GOSTO", bot.reply("eu nao gosto"))
    assert_equal("POR QUE VOCE NAO GOSTO", bot.reply("eu nao gosto"))
  end

  def test_portuguese_voce_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    # Test VOCE QUER pattern
    reply = bot.reply("voce quer ajuda")
    assert_equal("POR QUE VOCE QUER AJUDA", reply)

    # "ME" reflects to "VOCE", pattern captures [VOCE] at position 4
    reply = bot.reply("voce me odeia")
    # Pattern: (0 VOCE 0 ME 0) -> POR QUE VOCE PENSA QUE EU 4 VOCE
    # After reflection, ME becomes VOCE, so 4 captures VOCE
    assert_equal("POR QUE VOCE PENSA QUE EU VOCE VOCE", reply)
  end

  def test_portuguese_sim_nao_patterns
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal("VOCE PARECE BEM POSITIVO", bot.reply("sim"))
    assert_equal("VOCE ESTA SENDO UM POUCO NEGATIVO", bot.reply("nao"))
  end

  def test_portuguese_todos_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    reply = bot.reply("todos acham isso")
    assert(reply.include?("TODOS"), "Expected reply to contain TODOS, got: #{reply}")
  end

  def test_portuguese_seu_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    reply = bot.reply("seu carro")
    # SEU reflects to MEU
    assert(reply.include?("MEU"), "Expected reply to contain MEU, got: #{reply}")
  end

  def test_portuguese_memory_rule
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    bot.reply("meu pai e rigido")
    bot.reply("x")
    reply = bot.reply("x")

    assert(reply.include?("SEU"), "Expected memory to contain SEU, got: #{reply}")
  end

  def test_portuguese_high_precedence_keyword_wins_over_earlier_keyword
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal("SEU PAI", bot.reply("eu acho que meu pai"))
  end

  def test_memory_can_be_recalled_on_fourth_no_keyword_input
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    # Creates memory through MY rule + MEMORY MY rule.
    bot.reply("my brother is annoying")
    bot.reply("noise") # limit 3
    assert_equal("LETS DISCUSS FURTHER WHY YOUR BROTHER IS ANNOYING", bot.reply("noise")) # limit 4
  end

  def test_unsupported_locale_raises
    assert_raises(ArgumentError) { Eliza::Bot.from_script(SCRIPT_EN, locale: :fr) }
  end
end
