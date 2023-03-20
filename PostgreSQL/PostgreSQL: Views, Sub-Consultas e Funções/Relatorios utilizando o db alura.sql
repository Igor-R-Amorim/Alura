  SELECT aluno.primeiro_nome,
         aluno.ultimo_nome,
		 COUNT(aluno_curso.curso_id) AS numero_cursos
	FROM aluno
	JOIN aluno_curso ON aluno_curso.aluno_id = aluno.id
	GROUP BY 1, 2
	ORDER BY numero_cursos DESC
    LIMIT 1;
   
SELECT curso.nome,
  	   COUNT(aluno_curso.aluno_id) numero_alunos
    FROM curso
	JOIN aluno_curso ON aluno_curso.curso_id = curso.id
	GROUP BY 1
	ORDER BY 2 DESC
    LIMIT 1;

-- Relembrando Subqueries com strings
SELECT * FROM curso WHERE categoria_id IN(1, 2);

SELECT * FROM curso WHERE categoria_id IN(
	SELECT id FROM categoria WHERE nome NOT LIKE '% %'
);

SELECT curso.nome FROM curso WHERE categoria_id IN(
	SELECT id FROM categoria WHERE nome LIKE '% de %'
);

-- Utilizando as subqueries nos relatorios
SELECT categoria,
       numero_cursos
    FROM (
            SELECT categoria.nome AS categoria,
                   COUNT(curso.id) AS numero_cursos
            FROM categoria
            JOIN curso ON curso.categoria_id = categoria.id
        	GROUP BY categoria
    	 ) AS categoria_cursos
	WHERE numero_cursos > 3;

-- no exemplo acima uma forma de não se utilziar a subquery
-- seria utilizar o comando having do agrupamento (group by)

SELECT curso.nome,
       COUNT(aluno_curso.aluno_id) numero_alunos
	FROM curso
    JOIN aluno_curso ON aluno_curso.curso_id = curso.id
	GROUP BY 1
    HAVING COUNT(aluno_curso.aluno_id) > 2
	ORDER BY numero_alunos DESC;

CREATE VIEW vw_cursos_por_cateogria AS
	(
		SELECT categoria.nome AS categoria,
			   COUNT(curso.id) AS numero_cursos
		FROM categoria
		JOIN curso ON curso.categoria_id = categoria.id
		GROUP BY categoria
    )

SELECT * FROM vw_cursos_por_cateogria;

CREATE VIEW vw_cursos_programacao AS SELECT nome FROM curso WHERE categoria_id = 2;

SELECT * FROM vw_cursos_programacao;