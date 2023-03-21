/*--------------------------------------------------------------
	recebendo um tipo composto
 --------------------------------------------------------------*/
 
-- observe que na função foi usado o tipo "instrutor" como parametro de entrada
CREATE OR REPLACE FUNCTION dobro_do_salario (instrutor) RETURNS DECIMAL as $$
	SELECT $1.salario *2 AS dobro;
$$ LANGUAGE SQL;

SELECT nome, dobro_do_salario(public.instrutor.*) AS "Salario Desejado" 
FROM public.instrutor;

/*--------------------------------------------------------------
	Retornando linhas inteiras (tipo composto)
 --------------------------------------------------------------*/
 
CREATE OR REPLACE FUNCTION cria_instrutor_falso() RETURNS instrutor AS $$
	SELECT 22 as id, 'Nome Dummy', 200::DECIMAL;
$$ LANGUAGE SQL;

SELECT * FROM cria_instrutor_falso();

/*--------------------------------------------------------------
	Retornando um conjunto de linhas
 --------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION instrutores_bem_pagos(valor_salario DECIMAL) RETURNS SETOF instrutor AS $$
	SELECT * FROM instrutor WHERE salario > valor_salario;
$$ LANGUAGE SQL;

SELECT * FROM instrutores_bem_pagos(300);

/*--------------------------------------------------------------
	Definindo quais colunas eu quero de saida
 --------------------------------------------------------------*/
-- dê preferencia por criar os tipos explicitos ao inves de usar o out nos parametros da função

DROP FUNCTION instrutores_bem_pagos;

CREATE OR REPLACE FUNCTION instrutores_bem_pagos(valor_salario DECIMAL, 
												 OUT nome VARCHAR, 
												 OUT salario DECIMAL) RETURNS SETOF RECORD AS $$
	SELECT nome, salario FROM instrutor WHERE salario > valor_salario;
$$ LANGUAGE SQL;

SELECT * FROM instrutores_bem_pagos(300);

/*---------------------------------------------------------------
	Refazendo a função de criar instrutor falso com PL/pgSQL
 ---------------------------------------------------------------*/
 
 -- 1ª forma de retornar usando pl/pgsql
CREATE OR REPLACE FUNCTION cria_instrutor_falso() RETURNS instrutor AS $$
	BEGIN
		RETURN ROW (22, 'Nome Dummy', 200::DECIMAL)::instrutor;
	END;
$$ LANGUAGE plpgsql;

SELECT * FROM cria_instrutor_falso();

 -- 2ª forma de retornar usando pl/pgsql
CREATE OR REPLACE FUNCTION cria_instrutor_falso() RETURNS instrutor AS $$
	DECLARE
		retorno instrutor;
	BEGIN
		SELECT 22, 'Nome Dummy', 200::DECIMAL INTO retorno;
		RETURN retorno;
	END;
$$ LANGUAGE plpgsql;

SELECT * FROM cria_instrutor_falso();


/*--------------------------------------------------------------
	Refazendo a função de instrutores bem pagos com PL/pgSQL
 --------------------------------------------------------------*/

DROP FUNCTION instrutores_bem_pagos;

CREATE OR REPLACE FUNCTION instrutores_bem_pagos(valor_salario DECIMAL) RETURNS SETOF instrutor AS $$
	BEGIN
		RETURN QUERY SELECT * FROM instrutor WHERE salario > valor_salario;
	END;
$$ LANGUAGE plpgsql;

SELECT * FROM instrutores_bem_pagos(300);

/*--------------------------------------------------------------
	Resolvendo os instrutores bem pagos, retornando apenas
	o nome e o salario com PL/pgSQL
 --------------------------------------------------------------*/

CREATE TYPE nome_salario AS (nome_instrutor VARCHAR,salario_instrutor DECIMAL);

CREATE OR REPLACE FUNCTION bem_pagos(valor_salario DECIMAL) RETURNS SETOF nome_salario AS $$
    BEGIN
        RETURN QUERY SELECT nome, salario FROM instrutor WHERE salario > valor_salario ;
    END;
$$ LANGUAGE plpgsql; 

SELECT * FROM bem_pagos(300);

DROP TYPE nome_salario CASCADE;


/*--------------------------------------------------------------
	Retornando mensagens para buscas condicionadas a uma regra
 --------------------------------------------------------------*/
 
 -- se o salario do instrutor for maior que 200, está ok
 -- se nao, pode aumentar
CREATE OR REPLACE FUNCTION salario_ok(professor instrutor) RETURNS VARCHAR AS $$
    BEGIN
		IF professor.salario > 200 THEN
			RETURN 'Salario esta ok';
		ELSE
			RETURN 'Salario pode aumentar';
		END IF;
    END;
$$ LANGUAGE plpgsql; 

SELECT nome, salario_ok(instrutor) FROM instrutor;

-- Outra forma de fazer esse mesmo codigo, porem consumindo mais recurso computacional é:
DROP FUNCTION salario_ok;
CREATE OR REPLACE FUNCTION salario_ok(id_instrutor INTEGER) RETURNS VARCHAR AS $$
    DECLARE
		instrutor instrutor;
	BEGIN
		SELECT * FROM instrutor WHERE id = id_instrutor INTO instrutor;
		IF instrutor.salario > 200 THEN
			RETURN 'Salario esta ok';
		ELSE
			RETURN 'Salario pode aumentar';
		END IF;
    END;
$$ LANGUAGE plpgsql; 

SELECT nome, salario_ok(instrutor.id) FROM instrutor;

-- caso a condição inicial fosse com mais de duas opçoes?
-- Vamos supor que:
 -- se o salario do instrutor for maior que 300, está ok
 -- se o salario for de 300, pode aumentar
 -- caso contrario, esta defasado
 
DROP FUNCTION salario_ok;
CREATE OR REPLACE FUNCTION salario_ok(professor instrutor) RETURNS VARCHAR AS $$
	BEGIN
		CASE 
			WHEN professor.salario = 100 THEN
				RETURN 'Salario muito baixo';
			WHEN professor.salario = 200 THEN
				RETURN 'Salario baixo pode aumentar';
			WHEN professor.salario = 300 THEN
				RETURN 'Salario esta ok';
			ELSE
				RETURN 'Salario otimo';
		END CASE;
    END;
$$ LANGUAGE plpgsql; 

SELECT nome, salario_ok(instrutor) FROM instrutor;

-- uma forma de simplificar o case when é passando 
-- apenas a condição para os when subsequentes

DROP FUNCTION salario_ok;
CREATE OR REPLACE FUNCTION salario_ok(professor instrutor) RETURNS VARCHAR AS $$
	BEGIN
		CASE professor.salario
			WHEN 100 THEN
				RETURN 'Salario muito baixo';
			WHEN 200 THEN
				RETURN 'Salario baixo pode aumentar';
			WHEN 300 THEN
				RETURN 'Salario esta ok';
			ELSE
				RETURN 'Salario otimo';
		END CASE;
    END;
$$ LANGUAGE plpgsql; 

SELECT nome, salario_ok(instrutor) FROM instrutor;

/*--------------------------------------------------------------
	Utilizando estruturas de repetição em uma query
 --------------------------------------------------------------*/

CREATE OR REPLACE FUNCTION instrutor_com_salario(OUT nome VARCHAR, OUT salario_ok VARCHAR) RETURNS SETOF RECORD AS $$
 	DECLARE
	instrutor instrutor;
	BEGIN
		FOR instrutor IN SELECT * FROM instrutor LOOP
			nome := instrutor.nome;
			salario_ok := salario_ok(instrutor);
			RETURN NEXT;
		END LOOP;
	END;
$$ LANGUAGE plpgsql;

SELECT * FROM instrutor_com_salario();

/*--------------------------------------------------------------
	Inserir um novo curso  
 --------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION cria_curso(nome_curso VARCHAR, nome_categoria VARCHAR) RETURNS VOID AS $$
 	DECLARE
		id_categoria INTEGER;
	BEGIN
		SELECT id FROM categoria WHERE nome = nome_categoria INTO id_categoria;
		IF NOT FOUND THEN
			INSERT INTO categoria (nome) VALUES (nome_categoria) RETURNING id INTO id_categoria;
		END IF;
		INSERT INTO curso (nome,categoria_id) VALUES (nome_curso, id_categoria);
	END;
$$ LANGUAGE plpgsql;

SELECT cria_curso('Java', 'Programação');
SELECT * FROM curso;
SELECT * FROM categoria;

/*--------------------------------------------------------------
	Inserir um novos instrutores
 --------------------------------------------------------------*/

-- Inserir instrutor (com salarios)
-- Se o salario for maior que a média, salvar um log.
-- Salvar outro log dizendo que o instrutor recebe mais do que X% da grade de instrutores



CREATE OR REPLACE FUNCTION cria_instrutor(nome_instrutor VARCHAR, salario_instrutor DECIMAL) RETURNS VOID AS $$
 	DECLARE
		id_instrutor_inserido INTEGER;
		media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
	BEGIN
		INSERT INTO instrutor (nome, salario) VALUES (nome_instrutor, salario_instrutor) RETURNING id INTO id_instrutor_inserido;
		SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor WHERE id <> id_instrutor_inserido;
		
		IF salario_instrutor > media_salarial THEN
			INSERT INTO log_instrutores (informacao) VALUES (nome_instrutor || ' recebe acima da média');
		END IF;
		
		FOR salario IN SELECT instrutor.salario FROM instrutor WHERE id <> id_instrutor_inserido LOOP
			total_instrutores := total_instrutores+1;
			IF salario_instrutor > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct = instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		INSERT INTO log_instrutores (informacao) 
			VALUES (CONCAT(nome_instrutor, ' recebe mais do que ', pct, '% da grade de instrutores'));
	END;
$$ LANGUAGE plpgsql;

SELECT * FROM instrutor;
SELECT cria_instrutor('Fulado de tal',1000);
SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

SELECT cria_instrutor('Outra instrutora',400);
SELECT * FROM instrutor;
SELECT * FROM log_instrutores;