/* ----------------------------- 
Explorando funcoes de strings
----------------------------- */
SELECT (primeiro_nome || ' ' || ultimo_nome) AS nome_completo FROM aluno;

-- Esse operador tem uma limitação:
SELECT ('Vinicius' || ' ' || NULL);

-- Para esses casos o postgre conta coma função concat
SELECT CONCAT('Vinicius', ' ', NULL);

SELECT UPPER( CONCAT(' ', 'Vinicius', ' ', NULL, ' '));
SELECT TRIM( CONCAT(' ', 'Vinicius', ' ', NULL, ' '));

/* ----------------------------- 
Explorando funcoes de data 
----------------------------- */

SELECT (primeiro_nome || ultimo_nome) AS nome_completo, 
		NOW(), 
		data_nascimento 
	FROM aluno;

-- convertendo a data que aparecia como timestamp para apenas data
SELECT (primeiro_nome || ultimo_nome) AS nome_completo, 
		NOW()::DATE, 
		data_nascimento 
	FROM aluno;

-- calculando a idade em dias
SELECT (primeiro_nome || ultimo_nome) AS nome_completo,
       (NOW()::DATE - data_nascimento) AS "idade em dias"
  FROM aluno;

-- calculando a idade em anos
SELECT (primeiro_nome || ultimo_nome) AS nome_completo,
       (NOW()::DATE - data_nascimento)/365 AS idade
  FROM aluno;

-- Utilizando a função especifica
SELECT (primeiro_nome || ultimo_nome) AS nome_completo,
    	AGE(data_nascimento) AS idade
  FROM aluno;

-- extraindo apenas a parte de ano da coluna
SELECT (primeiro_nome || ultimo_nome) AS nome_completo,
    	EXTRACT(YEAR FROM AGE(data_nascimento)) AS idade
  FROM aluno;
  
/* ----------------------------- 
Explorando funcoes aritmeticas
----------------------------- */

SELECT pi();

SELECT @ -1723482814;

SELECT @ 1723482814;

-- acesse a documentação para saber mais.

-- de funcoes trigonometricas a calculos mais complicados
-- tem de quase tudo.

/* ----------------------------- 
Explorando funcoes de conversão
----------------------------- */

SELECT TO_CHAR(NOW(),'DD/MM/YYYY');
SELECT TO_CHAR(NOW(), 'DD, MONTH, YYYY');
SELECT TO_CHAR(NOW(),'DD/MM/yyyy');
SELECT TO_CHAR(NOW(),'MM');
SELECT TO_CHAR(NOW(),'dd');

SELECT 128.3::REAL;
SELECT TO_CHAR(128.3::REAL, '999D99');

-- Para mais funcoes acesse: 
-- https://www.postgresql.org/docs/current/functions.html


