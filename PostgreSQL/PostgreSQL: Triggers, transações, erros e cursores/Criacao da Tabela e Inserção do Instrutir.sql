--DROP TABLE IF EXISTS instrutor CASCADE;
CREATE TABLE IF NOT EXISTS instrutor(
	id SERIAL PRIMARY KEY,
	nome VARCHAR(255) NOT NULL,
	salario DECIMAL (10,2)
);

--DROP TABLE IF EXISTS log_instrutores;
CREATE TABLE IF NOT EXISTS log_instrutores(
	id SERIAL PRIMARY KEY,
	informacao VARCHAR(255),
	momento_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO instrutor (nome, salario) VALUES ('Vinicius Dias', 100);
INSERT INTO instrutor (nome, salario) VALUES ('Diogo Mascarenhas', 200);
INSERT INTO instrutor (nome, salario) VALUES ('Nico Steppat', 300);
INSERT INTO instrutor (nome, salario) VALUES ('Juliana', 400);
INSERT INTO instrutor (nome, salario) VALUES ('Priscila', 500);
