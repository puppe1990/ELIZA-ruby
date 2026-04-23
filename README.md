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

Para ativar o hook versionado de `pre-commit` neste clone:

```bash
git config core.hooksPath .githooks
```

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
OLA PODE ME CONTAR O QUE ESTA ACONTECENDO
> meu pai e rigido
COMO E SUA RELACAO COM SEU PAI
> x
PODE ME CONTAR MAIS
> x
ANTES VOCE FALOU DO SEU PAI
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

Lint:

```bash
bundle exec rake lint
```

Suite local igual ao CI:

```bash
bundle exec rake ci
```

## Estado atual

Pronto para uso local:
- CLI funcional
- testes cobrindo parsing, precedência, substituições, memória e português
- lint com RuboCop
- hook de `pre-commit` versionado
- CI no GitHub Actions

Melhorias possíveis:
- expandir o script em português para soar mais natural
- permitir escolher um script customizado por argumento
- publicar como gem
