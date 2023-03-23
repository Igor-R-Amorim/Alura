/*--------------------------------------------------------------
	FUNCAO CRIADA NO ULTIMO CURSO:
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
-- ESSA FUNÇÃO AO SER EXECUTADA ASSIM TRAZIA UM PROBLEMA
-- CASO FOSSE INSERIDO UM INSERT SIMPLES, ELE NAO GERARIA LOG


/*--------------------------------------------------------------
	CURSO SOBRE TRIGGERS
	Executando o trigger ao inserir um instrutor
 --------------------------------------------------------------*/

SELECT * FROM instrutor;
SELECT cria_instrutor('Mais uma pessoa',1200);
SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

DROP FUNCTION IF EXISTS cria_instrutor;
-- DROP FUNCTION IF EXISTS public.cria_log_instrutor;

CREATE OR REPLACE FUNCTION public.cria_log_instrutor()
    RETURNS TRIGGER
    COST 100
    VOLATILE NOT LEAKPROOF
	AS $$
 	
	DECLARE
		media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
	
	BEGIN
		SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor WHERE id <> NEW.id;
		
		IF NEW.salario > media_salarial THEN
			INSERT INTO log_instrutores (informacao) VALUES (NEW.nome || ' recebe acima da média');
		END IF;
		
		FOR salario IN SELECT instrutor.salario FROM instrutor WHERE id <> NEW.id LOOP
			total_instrutores := total_instrutores+1;
			IF NEW.salario > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct = instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		INSERT INTO log_instrutores (informacao) 
			VALUES (CONCAT(NEW.nome, ' recebe mais do que ', pct, '% da grade de instrutores'));
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

--DROP TRIGGER IF EXISTS criar_log_novos_instrutores ON instrutor;
CREATE TRIGGER criar_log_novos_instrutores AFTER INSERT ON instrutor
	FOR EACH ROW EXECUTE FUNCTION cria_log_instrutor();

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

INSERT INTO instrutor (nome, salario) VALUES ('Outra pessoa de novo', 600);

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;
-- Agora os logs sao gerados de forma automatica em cada insert


/*--------------------------------------------------------------
	Modificando o trigger para inserir o maior salario caso o 
	percentual seja maior que 100% da grade de instrutores
 --------------------------------------------------------------*/
 
DROP TRIGGER IF EXISTS criar_log_novos_instrutores ON instrutor;
DROP FUNCTION IF EXISTS public.cria_log_instrutor;


CREATE OR REPLACE FUNCTION cria_log_instrutor() 
	RETURNS TRIGGER
    VOLATILE NOT LEAKPROOF
	AS $$
    
	DECLARE
    	maior_salario DECIMAL;
    	media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
	
	BEGIN
        SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor;
		SELECT MAX (instrutor.salario) FROM instrutor INTO maior_salario;
		
		IF NEW.salario <= maior_salario THEN
            NEW.salario := NEW.salario;
        ELSE
            NEW.salario := maior_salario;
        END IF;
		
		FOR salario IN SELECT instrutor.salario FROM instrutor WHERE id <> NEW.id LOOP
			total_instrutores := total_instrutores+1;
			IF NEW.salario > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct = instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		INSERT INTO log_instrutores (informacao) 
			VALUES (CONCAT(NEW.nome, ' recebe mais do que ', pct, '% da grade de instrutores'));
		RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER criar_log_novos_instrutores BEFORE INSERT ON instrutor
    FOR EACH ROW EXECUTE FUNCTION cria_log_instrutor();

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

INSERT INTO instrutor (nome, salario) VALUES ('Mais uma vez outra pessoa de novo', 2000);

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;


/*--------------------------------------------------------------
	utilizando Rollback nos triggers
 --------------------------------------------------------------*/
 
 -- uma função faz parte da transação de qual ela é chamada
 -- por exemplo caso quisessimos dar um rollback na função 
 -- SELECT cria_instrutor('Fulado de tal',1000);
 -- basta dar inicio a transação na chamda da função.
 -- assim caso um erro ocorra, nada sera feito na hora de chmar a função
 -- o mesmo exeplo podemos usar no commit
 
 
SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

BEGIN
INSERT INTO instrutor (nome, salario) VALUES ('Mais uma vez outra pessoa de novo', 2000);
SELECT * FROM instrutor;
ROLLBACK

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;


/*--------------------------------------------------------------
	Tratando erroes e exceçoes nas funcoes
 --------------------------------------------------------------*/
 
DROP TRIGGER IF EXISTS criar_log_novos_instrutores ON instrutor;
DROP FUNCTION IF EXISTS public.cria_log_instrutor;

CREATE OR REPLACE FUNCTION cria_log_instrutor() 
	RETURNS TRIGGER
    VOLATILE NOT LEAKPROOF
	AS $$
    
	DECLARE
    	maior_salario DECIMAL;
    	media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
	
	BEGIN
        SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor;
		SELECT MAX (instrutor.salario) FROM instrutor INTO maior_salario;
		
		IF NEW.salario <= maior_salario THEN
            NEW.salario := NEW.salario;
        ELSE
            NEW.salario := maior_salario;
        END IF;
		
		FOR salario IN SELECT instrutor.salario FROM instrutor WHERE id <> NEW.id LOOP
			total_instrutores := total_instrutores+1;
			IF NEW.salario > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct = instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		INSERT INTO log_instrutores (informacao, erro) --erro inserido propositalmente
			VALUES (CONCAT(NEW.nome, ' recebe mais do que ', pct, '% da grade de instrutores'),'');
		RETURN NEW;
	EXCEPTION
		WHEN undefined_column THEN
			RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER criar_log_novos_instrutores BEFORE INSERT ON instrutor
    FOR EACH ROW EXECUTE FUNCTION cria_log_instrutor();

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

INSERT INTO instrutor (nome, salario) VALUES ('Joao', 650);

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;
-- observe que o log nao foi inserido mas nao gerou mensagem de erro


INSERT INTO instrutor (nome, salario) VALUES ('Maria', 900);

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;
-- observe agora que mesmo maria recebendo acima da media, o log
-- o primeiro insert da função nao foi feita, pois caso a
-- funcao caia no EXCEPT, tudo que esta no BEGIN, isso é o statment
-- sera ignorado e nao executado.

-- lembrando que podemos ter varios WHEN dentro do EXCEPT para 
-- tratar diferentes erros erros e atribuir diferentes
-- saidas para cada erro


/*--------------------------------------------------------------
	Levantando mensagens de notificacao
 --------------------------------------------------------------*/
 
DROP TRIGGER IF EXISTS criar_log_novos_instrutores ON instrutor;
DROP FUNCTION IF EXISTS public.cria_log_instrutor;

CREATE OR REPLACE FUNCTION cria_log_instrutor() 
	RETURNS TRIGGER
    VOLATILE NOT LEAKPROOF
	AS $$
    
	DECLARE
    	maior_salario DECIMAL;
    	media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
	
	BEGIN
        SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor;
		SELECT MAX (instrutor.salario) FROM instrutor INTO maior_salario;
		
		IF NEW.salario <= maior_salario THEN
            NEW.salario := NEW.salario;
        ELSE
            NEW.salario := maior_salario;
        END IF;
		
		FOR salario IN SELECT instrutor.salario FROM instrutor WHERE id <> NEW.id LOOP
			total_instrutores := total_instrutores+1;
			IF NEW.salario > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct = instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		INSERT INTO log_instrutores (informacao, erro) --erro inserido propositalmente
			VALUES (CONCAT(NEW.nome, ' recebe mais do que ', pct, '% da grade de instrutores'),'');
		RETURN NEW;
	EXCEPTION
		WHEN undefined_column THEN
			RAISE NOTICE 'Algo de errado não esta certo';
			RAISE EXCEPTION 'Erro complicado de resolver';
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER criar_log_novos_instrutores BEFORE INSERT ON instrutor
    FOR EACH ROW EXECUTE FUNCTION cria_log_instrutor();

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

INSERT INTO instrutor (nome, salario) VALUES ('Maria', 5000);

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;


-- é possivel ainda pegar a excelção que eu levantei e tratar ela dentro do 
-- bloco de EXCEPTION com um novo (WHEN raise_exception THEN...) 

-- a função de raise notice pode ser usada tambem para depurar o codigo, nao  
-- apenas para levantar uma mensagem de erro.
-- pode ser facilmente usado como  o printf de outras linguagens 

/*--------------------------------------------------------------
	impedindo a adição de um instrutor que recebe 
	mais do que a media
 --------------------------------------------------------------*/
 
-- vamos pegar a função do segundo codigo para trabalhar

-- primeiramente vamos dropar o trigger e a função criados 
DROP TRIGGER IF EXISTS criar_log_novos_instrutores ON instrutor;
DROP FUNCTION IF EXISTS cria_log_instrutor;

CREATE OR REPLACE FUNCTION cria_log_instrutor()
    RETURNS TRIGGER
    VOLATILE NOT LEAKPROOF
	AS $$
 	
	DECLARE
		media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
	
	BEGIN
		SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor WHERE id <> NEW.id;
		
		IF NEW.salario > media_salarial THEN
			INSERT INTO log_instrutores (informacao) VALUES (NEW.nome || ' recebe acima da média');
		END IF;
		
		FOR salario IN SELECT instrutor.salario FROM instrutor WHERE id <> NEW.id LOOP
			total_instrutores := total_instrutores+1;
			IF NEW.salario > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct := instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		/* IF pct = 100::DECIMAL THEN
			RETURN NULL
			RAISE EXCEPTION
		END IF;*/
		-- ou simplesmente
		ASSERT pct < 100::DECIMAL, 'Instrutores novos não podem receber mais do que os antigos';
		INSERT INTO log_instrutores (informacao, erro) 
			VALUES (CONCAT(NEW.nome, ' recebe mais do que ', pct, '% da grade de instrutores'),'');
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER criar_log_novos_instrutores BEFORE INSERT ON instrutor
	FOR EACH ROW EXECUTE FUNCTION cria_log_instrutor();

SELECT * FROM instrutor;
SELECT * FROM log_instrutores;

INSERT INTO instrutor (nome, salario) VALUES ('Joao', 1500);


/*--------------------------------------------------------------
	como utilizar cursores para nao trabalhar 
	com querys inteiras
 --------------------------------------------------------------*/
DROP TRIGGER IF EXISTS criar_log_novos_instrutores ON instrutor;
DROP FUNCTION IF EXISTS cria_log_instrutor;
 
CREATE OR REPLACE FUNCTION instrutores_internos(id_instrutor INTEGER)
 	RETURNS refcursor
    VOLATILE NOT LEAKPROOF
	AS $$
 	
	DECLARE
		-- cursor_salarios FOR SELECT instrutor.salario FROM instrutor WHERE id <> id_instrutor AND salario>0;
		cursor_salarios refcursor;
	BEGIN
		OPEN cursor_salarios FOR SELECT instrutor.salario 
								 FROM instrutor 
								 WHERE id <> id_instrutor 
								 AND salario>0;
		RETURN cursor_salarios;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cria_log_instrutor()
    RETURNS TRIGGER
    VOLATILE NOT LEAKPROOF
	AS $$
 	
	DECLARE
		media_salarial DECIMAL;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		total_instrutores INTEGER DEFAULT 0;
		salario DECIMAL;
		pct DECIMAL(10,2);
		cursor_salarios refcursor;
	
	BEGIN
		SELECT AVG(instrutor.salario) INTO media_salarial FROM instrutor WHERE id <> NEW.id;
		
		IF NEW.salario > media_salarial THEN
			INSERT INTO log_instrutores (informacao) VALUES (NEW.nome || ' recebe acima da média');
		END IF;
		
		SELECT instrutores_internos(NEW.id) INTO cursor_salarios;
		LOOP
			FETCH cursor_salarios INTO salario;
		EXIT WHEN NOT FOUND;
			total_instrutores := total_instrutores+1;
			IF NEW.salario > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		
		pct := instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		ASSERT pct < 100::DECIMAL, 'Instrutores novos não podem receber mais do que os antigos';
		
		INSERT INTO log_instrutores (informacao,Erro) 
			VALUES (CONCAT(NEW.nome, ' recebe mais do que ', pct, '% da grade de instrutores'),'');
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER criar_log_novos_instrutores BEFORE INSERT ON instrutor
	FOR EACH ROW EXECUTE FUNCTION cria_log_instrutor();

INSERT INTO instrutor (nome, salario) VALUES ('Joao', 1500);

/*--------------------------------------------------------------
	como utilizar funçoes efemeras para teste ou gerar 
	relatorios unicos.
 --------------------------------------------------------------*/
 
DO $$
	DECLARE
		cursor_salarios refcursor;
		salario DECIMAL;
		total_instrutores INTEGER DEFAULT 0;
		instrutores_recebem_menos INTEGER DEFAULT 0;
		pct DECIMAL(5,2);
	BEGIN
		SELECT instrutores_internos(12) INTO cursor_salarios;
		LOOP
			FETCH cursor_salarios INTO salario;
		EXIT WHEN NOT FOUND;
			total_instrutores := total_instrutores+1;
			IF 600::DECIMAL > salario THEN
				instrutores_recebem_menos := instrutores_recebem_menos+1;
			END IF;
		END LOOP;
		pct := instrutores_recebem_menos::DECIMAL/total_instrutores::DECIMAL * 100;
		RAISE NOTICE 'Percentual: % %%', pct;
	END;
$$;
 
