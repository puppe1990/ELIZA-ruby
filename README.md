# ELIZA em Ruby

Reescrita em Ruby do ELIZA com uma versão em inglês e uma adaptação em português, guiada por testes com `minitest`.

O projeto mantém a ideia central do ELIZA original:
- leitura de regras em formato parecido com S-expressions
- seleção de palavras-chave por precedência
- decomposição e remontagem de frases
- mecanismo de memória

## Estrutura

- [lib/eliza.rb](/Users/matheuspuppe/Desktop/Projetos/github/ELIZA-ruby/lib/eliza.rb): implementação principal
- [bin/eliza](/Users/matheuspuppe/Desktop/Projetos/github/ELIZA-ruby/bin/eliza): interface de linha de comando
- [test/eliza_test.rb](/Users/matheuspuppe/Desktop/Projetos/github/ELIZA-ruby/test/eliza_test.rb): suíte de testes
- [scripts/ruby/default_pt.script](/Users/matheuspuppe/Desktop/Projetos/github/ELIZA-ruby/scripts/ruby/default_pt.script) e [scripts/ruby/default_en.script](/Users/matheuspuppe/Desktop/Projetos/github/ELIZA-ruby/scripts/ruby/default_en.script): scripts padrão carregados pela aplicação

## Requisitos

- Ruby 3.1+ (testado aqui com Ruby 4.0.2)

## Instalação

```bash
bundle install
```

Se você não quiser usar Bundler, também pode rodar diretamente com `ruby`, porque este projeto usa apenas biblioteca padrão.

## Uso

Inglês:

```bash
ruby bin/eliza en
```

Português:

```bash
ruby bin/eliza pt
```

Exemplo:

```text
$ ruby bin/eliza pt
OLA COMO VOCE ESTA CONTE SEU PROBLEMA
> meu pai e rigido
SEU PAI SOU RIGIDO
> x
POR FAVOR, CONTINUE
> x
VAMOS DISCUTIR MAIS POR QUE SEU PAI SOU RIGIDO
```

Para encerrar:
- envie uma linha vazia
- ou use `Ctrl+D`

## Testes

Com Ruby direto:

```bash
ruby test/eliza_test.rb
```

Com Bundler:

```bash
bundle exec ruby test/eliza_test.rb
```

Ou via `rake`:

```bash
bundle exec rake test
```

## Estado atual

Pronto para uso local:
- CLI funcional
- testes cobrindo parsing, precedência, substituições, memória e português
- sem dependências externas obrigatórias

Melhorias possíveis:
- expandir o script em português para soar mais natural
- permitir escolher um script customizado por argumento
- publicar como gem
