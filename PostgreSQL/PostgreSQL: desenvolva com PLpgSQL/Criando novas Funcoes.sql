/*----------------------------------------------------
	PRIMEIRA FUNCAO
  ----------------------------------------------------*/

CREATE FUNCTION primeira_funcao() RETURNS INTEGER AS '
	SELECT (5-3) * 2
' LANGUAGE SQL;

-- como ele retorna um unico valor, a função pode 
-- ser usada como atributo nesse caso
SELECT primeira_funcao() AS "numero";


/*----------------------------------------------------
	SEGUNDA FUNCAO
  ----------------------------------------------------*/
 
CREATE FUNCTION soma_dois_numeros(numero1 INTEGER, numero2 INTEGER) RETURNS INTEGER AS '
	SELECT numero1 + numero2
' LANGUAGE SQL;

SELECT soma_dois_numeros(14, 6) AS "soma";

CREATE FUNCTION soma_dois_numeros_aprimorada(numero1 INTEGER, numero2 INTEGER) RETURNS INTEGER AS '
	SELECT $1 + $2
' LANGUAGE SQL;

SELECT soma_dois_numeros_aprimorada(14, 6) AS "soma";


/*----------------------------------------------------
	TERCEIRA FUNCAO
  ----------------------------------------------------*/
  
CREATE TABLE IF NOT EXISTS aa (nome VARCHAR(255) NOT NULL);
CREATE OR REPLACE FUNCTION cria_a (nome VARCHAR) RETURNS VARCHAR AS '
 	INSERT INTO aa(nome) VALUES(cria_a.nome);
	SELECT nome;
 ' LANGUAGE SQL;
 
SELECT cria_a('Vinicius Dias');
SELECT * FROM aa;

-- Trocando o delimitador da função para usar as ' ' das strings
CREATE OR REPLACE FUNCTION cria_aa (nome VARCHAR) RETURNS VOID AS $$
 	INSERT INTO aa(nome) VALUES('Patricia')
 $$ LANGUAGE SQL;
 
SELECT cria_aa('Vinicius Dias');
SELECT * FROM aa;


/*----------------------------------------------------
	EXPLICITANDO PARAMETROS DE ENTRADA E SAIDA
  ----------------------------------------------------*/

CREATE FUNCTION soma_e_produto (IN numero_1 INTEGER, IN numero_2 INTEGER, OUT soma INTEGER, OUT produto INTEGER) AS $$
	SELECT numero_1 + numero_2 AS soma, numero_1 * numero_2 AS produto;
$$ LANGUAGE SQL;

SELECT * FROM soma_e_produto(3,3);

-- utilizando outra logica para criar a mesma função
DROP FUNCTION soma_e_produto;
CREATE TYPE dois_valores AS (soma INTEGER, produto INTEGER);
CREATE FUNCTION soma_e_produto (IN numero_1 INTEGER, IN numero_2 INTEGER) RETURNS dois_valores AS $$
	SELECT numero_1 + numero_2 AS soma, numero_1 * numero_2 AS produto;
$$ LANGUAGE SQL;

SELECT * FROM soma_e_produto(3,3);


/*----------------------------------------------------
	CRIANDO NOSSA PRIMEIRA PL
  ----------------------------------------------------*/

CREATE OR REPLACE FUNCTION primeira_pl() RETURNS INTEGER AS $$ 
	BEGIN
		--Diferente da language SQL a agora saida já nao é mais o ultimo comando SQL
		RETURN 1;
		--SELECT 1;
	END
$$ LANGUAGE plpgsql;

SELECT primeira_pl();


/*----------------------------------------------------
	UTILIZANDO VARIAVEIS EM NOSSA PL
  ----------------------------------------------------*/

CREATE OR REPLACE FUNCTION primeira_pl() RETURNS INTEGER AS $$ 
	DECLARE
		primeira_var INTEGER DEFAULT 3;
		--primeira_var INTEGER := 3;
	BEGIN
		-- para atribuir usa-se essa notação :=, o = tambem funciona mas
		-- complica a vida na hora de olhar se é atribuição ou comparacao
		primeira_var := primeira_var*2;
		--Varios comandos em SQL
		RETURN primeira_var;
	END
$$ LANGUAGE plpgsql;

SELECT primeira_pl();


/*----------------------------------------------------
	entendendo sub-blocos
  ----------------------------------------------------*/

CREATE OR REPLACE FUNCTION primeira_pl() RETURNS INTEGER AS $$ 
	DECLARE
		primeira_var INTEGER DEFAULT 3;
	BEGIN
		primeira_var := primeira_var*2;
			
			DECLARE
				primeira_var INTEGER;
			BEGIN
				primeira_var := 7;
			END;

		RETURN primeira_var;
	END
$$ LANGUAGE plpgsql;

SELECT primeira_pl();
-- OBS: 
-- as variaveis definidas dentro dos sub-blocos são locais, elas não interferem no bloco pai.
-- mas se nos retirarmos a declaração teremos o resultado desejado pois os blocos aninhados
-- tem acesso aos blocos pais.

CREATE OR REPLACE FUNCTION primeira_pl() RETURNS INTEGER AS $$ 
	DECLARE
		primeira_var INTEGER DEFAULT 3;
	BEGIN
		primeira_var := primeira_var*2;
			
			BEGIN
				primeira_var := 7;
			END;

		RETURN primeira_var;
	END
$$ LANGUAGE plpgsql;

SELECT primeira_pl();

-- por boas praticas, evite a todo custo definir variaveis com nomes iguais.
-- isso causa confusão na posterior leitura do codigo

/*----------------------------------------------------
	Fazendo a terceira função do SQL em PL/pgSQL
  ----------------------------------------------------*/

-- Trocando o delimitador da função para usar as ' ' das strings
CREATE OR REPLACE FUNCTION cria_aa (nome VARCHAR) RETURNS VOID AS $$
 	BEGIN
		INSERT INTO aa(nome) VALUES('Patricia');
	END;
$$ LANGUAGE plpgsql;
 
SELECT cria_aa('Vinicius Dias');
SELECT * FROM aa;

/*----------------------------------------------------
	Estruturas de repetição
  ----------------------------------------------------*/

-- Estamos querendo agora fazer uma função que nos retorna a tabuada de um determinado numero

CREATE OR REPLACE FUNCTION tabuada (numero INTEGER) RETURNS SETOF VARCHAR AS $$
 	DECLARE
		
	BEGIN
		RETURN NEXT ('1x' || numero || ' = ' || numero * 1);
		RETURN NEXT ('2x' || numero || ' = ' || numero * 2);
		RETURN NEXT ('3x' || numero || ' = ' || numero * 3);
		RETURN NEXT ('4x' || numero || ' = ' || numero * 4);
		RETURN NEXT ('5x' || numero || ' = ' || numero * 5);
		RETURN NEXT ('6x' || numero || ' = ' || numero * 6);
		RETURN NEXT ('7x' || numero || ' = ' || numero * 7);
		RETURN NEXT ('8x' || numero || ' = ' || numero * 8);
		RETURN NEXT ('9x' || numero || ' = ' || numero * 9);
	END;
$$ LANGUAGE plpgsql;
 
SELECT tabuada(9);

-- porem caso eu quisesse fazer mais alteraçoes eu teria 
-- que manualmente adicionar mais linhas, portanto
-- essa solução nao eh uma solucção otimizada.
-- para deixar o codigo mais versatil temos que usar
-- uma ferramenta de repetição.

CREATE OR REPLACE FUNCTION tabuada (numero INTEGER) RETURNS SETOF VARCHAR AS $$
 	DECLARE
		mult INTEGER DEFAULT 1;
	BEGIN
		LOOP
			RETURN NEXT (mult|| 'x' || numero || ' = ' || numero * mult);
			mult := mult + 1;
			EXIT WHEN mult = 10;
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

SELECT tabuada(9);

-- Substituindo o loop pelo while

CREATE OR REPLACE FUNCTION tabuada (numero INTEGER) RETURNS SETOF VARCHAR AS $$
 	DECLARE
	BEGIN
		FOR mult IN 1..9 LOOP
			RETURN NEXT (mult|| 'x' || numero || ' = ' || numero * mult);
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

SELECT tabuada(9);

