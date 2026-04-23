# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/eliza'

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
    (OLA PODE ME CONTAR O QUE ESTA ACONTECENDO)
    START
    (DESCULPA = DESCULPE)
    (DESCULPE
    ((0)
    (NAO PRECISA PEDIR DESCULPAS)
    (TUDO BEM PODE CONTINUAR)))
    (TO = ESTOU)
    (SINTO 5
    ((0 EU ME SINTO 0)
    (DESDE QUANDO VOCE SE SENTE 5)
    (FALE MAIS SOBRE SE SENTIR 5)))
    (ESTOU 4
    ((0 EU ESTOU 0)
    (COMO E PARA VOCE ESTAR 4)
    (DESDE QUANDO VOCE ESTA 4)))
    (QUERO 4
    ((0 EU QUERO 0)
    (O QUE MUDARIA SE VOCE CONSEGUISSE 4)
    (POR QUE ISSO E IMPORTANTE PARA VOCE)))
    (PAI 6
    ((0)
    (COMO E SUA RELACAO COM SEU PAI)
    (SEU PAI PARECE IMPORTANTE NISSO QUE VOCE ESTA TRAZENDO)))
    (MEMORY MEU
    (0 SEU PAI 0 = ANTES VOCE FALOU DO SEU PAI)
    (0 SEU 0 = VOCE DISSE QUE SEU 3))
    (MEU = SEU 8
    ((0 SEU PAI 0)
    (COMO E SUA RELACAO COM SEU PAI)
    (O QUE NO SEU PAI MAIS TE AFETA))
    ((0 SEU 0)
    (QUER ME CONTAR MAIS SOBRE SEU 3)
    (COMO VOCE SE SENTE EM RELACAO A SEU 3))))
    (MINHA = SUA 8
    ((0 SUA 0)
    (QUER ME CONTAR MAIS SOBRE SUA 3)))
    (SEU
    ((0 SEU 0)
    (O QUE SOBRE MEU 3 CHAMOU SUA ATENCAO)))
    (NAO
    ((0)
    (O QUE TE LEVA A DIZER NAO)
    (POR QUE A RESPOSTA FOI NAO)))
    (SIM
    ((0)
    (ENTENDO)
    (O QUE FAZ VOCE TER TANTA CERTEZA)))
    (TODOS
    ((0)
    (QUANDO VOCE DIZ TODOS QUEM EXATAMENTE VEM A SUA CABECA)
    (TEM ALGUEM ESPECIFICO QUE VOCE ESTA INCLUINDO EM TODOS)))
    (EU
    ((0 EU SOU 0)
    (COMO E PARA VOCE SER 4)
    (DESDE QUANDO VOCE E 4))
    ((0)
    (FALE MAIS SOBRE VOCE)))
    (NONE
    ((0)
    (PODE ME CONTAR MAIS)
    (QUERO ENTENDER MELHOR)))
  SCRIPT

  def test_parses_greeting_and_rule_map
    script = Eliza::Script.parse(SCRIPT_EN)

    assert_equal('HELLO HOW ARE YOU', script.greeting)
    assert(script.rules.key?('SORRY'))
    assert_equal('NONE', script.none_rule.keyword)
  end

  def test_default_script_is_loaded_from_file
    assert_includes(Eliza.default_script(:pt), 'OLA PODE ME CONTAR O QUE ESTA ACONTECENDO')
    assert_includes(Eliza.default_script(:en), 'HOW DO YOU DO PLEASE TELL ME YOUR PROBLEM')
  end

  def test_keyword_rule_decompose_and_reassemble
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    reply = bot.reply('I feel very tired today')

    assert_equal('DO YOU OFTEN FEEL VERY TIRED TODAY', reply)
  end

  def test_link_substitution_rule_applies_before_matching
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    reply = bot.reply('I cant know')

    assert_equal("PLEASE DON'T APOLOGIZE", reply)
  end

  def test_none_rule_rotates_when_no_keyword_matches
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    assert_equal('PLEASE CONTINUE', bot.reply('ZXCV'))
    assert_equal('GO ON PLEASE', bot.reply('QWER'))
  end

  def test_portuguese_version_works
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    reply = bot.reply('eu me sinto cansado')
    assert(reply.include?('SENTE CANSADO'), "Expected feeling response, got: #{reply}")

    assert_equal('PODE ME CONTAR MAIS', bot.reply('...'))
  end

  def test_portuguese_estou_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal('COMO E PARA VOCE ESTAR CANSADO', bot.reply('eu estou cansado'))
    assert_equal('DESDE QUANDO VOCE ESTA CANSADO', bot.reply('eu estou cansado'))
  end

  def test_portuguese_quero_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal('O QUE MUDARIA SE VOCE CONSEGUISSE AJUDA', bot.reply('eu quero ajuda'))
    assert_equal('POR QUE ISSO E IMPORTANTE PARA VOCE', bot.reply('eu quero ajuda'))
  end

  def test_portuguese_sim_nao_patterns
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal('ENTENDO', bot.reply('sim'))
    assert_equal('O QUE TE LEVA A DIZER NAO', bot.reply('nao'))
  end

  def test_portuguese_todos_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    reply = bot.reply('todos acham isso')
    assert(reply.include?('TODOS'), "Expected reply to contain TODOS, got: #{reply}")
  end

  def test_portuguese_seu_pattern
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    reply = bot.reply('seu carro')
    assert(reply.include?('MEU'), "Expected reply to contain MEU, got: #{reply}")
  end

  def test_portuguese_memory_rule
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    bot.reply('meu pai')
    bot.reply('x')
    reply = bot.reply('x')

    assert(reply.include?('SEU PAI'), "Expected memory to contain SEU PAI, got: #{reply}")
  end

  def test_portuguese_high_precedence_keyword_wins_over_earlier_keyword
    bot = Eliza::Bot.from_script(SCRIPT_PT, locale: :pt)

    assert_equal('COMO E SUA RELACAO COM SEU PAI', bot.reply('eu acho que meu pai'))
  end

  def test_portuguese_reflection_keeps_e_in_possessive_memory_phrases
    bot = Eliza::Bot.default(locale: :pt)

    assert_equal('COMO E SUA RELACAO COM SEU PAI', bot.reply('meu pai e rigido'))
  end

  def test_memory_can_be_recalled_on_fourth_no_keyword_input
    bot = Eliza::Bot.from_script(SCRIPT_EN, locale: :en)

    # Creates memory through MY rule + MEMORY MY rule.
    bot.reply('my brother is annoying')
    bot.reply('noise') # limit 3
    assert_equal('LETS DISCUSS FURTHER WHY YOUR BROTHER IS ANNOYING', bot.reply('noise')) # limit 4
  end

  def test_unsupported_locale_raises
    assert_raises(ArgumentError) { Eliza::Bot.from_script(SCRIPT_EN, locale: :fr) }
  end
end
