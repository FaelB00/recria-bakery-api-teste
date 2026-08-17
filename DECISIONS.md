# Decisões

> Preencha este arquivo e entregue junto com o código. **Máximo 1 página no total.**
>
> Respostas curtas e diretas valem mais que respostas longas. Não queremos teoria — queremos
> o raciocínio por trás do **seu** código. Se você não fez algum item, diga isso e responda
> como faria.

---

### 1. O Passo 2 exigia que o controller não tivesse `try`/`except`. Por quê? O que quebraria se você colocasse um?

Os possíveis erros de negócio são modelados como valor de retorno do service (`BusinessError`), 
não como exceção, assim, o controller nunca precisa capturar nada nesse fluxo. O tipo de retorno 
do service (`Supplier | BusinessError`) já documenta na assinatura que existem dois caminhos 
possíveis, um `try/except`ali seria redundante e esconderia e abriria espaço pra alguém futuramente 
usar raise ao invés de return pra erro de negócio, misturando dois padrões diferentes de tratamento 
de erro no mesmo projeto.

---

### 2. No seu código, onde começa e onde termina uma operação de escrita no banco? Por que nesse ponto e não em outro?

A transação abre quando a sessão é criada (get_db_session) e só é confirmada (commit) depois que toda a cadeia controller → service → repository terminar sem erro, e qualquer exceção no meio dispara rollback. O repository nunca commita sozinho, só flush. Centralizar isso na fronteira da requisição garante que operações com múltiplos passos de escrita sejam atômicas — tudo confirma junto, ou nada confirma.

---

### 3. O `store_code` chega por header. Se ele viesse no corpo da requisição, que problema apareceria?

Se store_code viesse no corpo, não haveria como identificá-lo em requisições que normalmente não carregam corpo (GET, DELETE). Além disso, store_code é a identidade de quem faz a requisição, não um dado de domínio sendo manipulado, colocá-lo no corpo misturaria essas duas coisas e obrigaria replicar o campo em todo DTO de entrada.

---

### 4. Quais opcionais do Bloco B você escolheu? E por que descartou os outros?

Escolhi D3 e D7: D3 porque é a construção de um novo endpoint, e como já vinha revisando os conceitos de camadas durante o Bloco A, pareceu o próximo passo mais natural. D7 parecia mais simples à primeira vista, mas não tinha familiaridade com as ferramentas (ruff, mypy, multi-stage build), as LLMs me ajudaram bastante e aprendi coisas novas no processo. Descartei os outros por tempo, e confesso que em alguns pontos nem saberia por onde começar.

---

### Extra (opcional): o que você deixou pela metade, ou faria diferente com mais tempo?

Tudo que me propus a fazer(Bloco A e D3, D7), realizei por completo. Durante o desenvolvimento de código me encontrei perdido com alguns conceitos, travei em código e cometi alguns erros, porém tive auxílio da IA e me senti confortável com o resultado. Se tivesse mais tempo, iria me aprofundar em mais conceitos para entender se os trechos que as LLM's me entregaram estão seguros de serem usados em uma aplicação dessa magnitude.
