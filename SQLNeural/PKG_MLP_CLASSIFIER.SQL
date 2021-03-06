/*
----------------------------------------------------------------------------
 Classification with Multi Layer Perceptron and  Oracle PLSQL
   Compile this Package and run:
begin
   PKG_MLP_CLASSIFIER.execute; 
end;
----------------------------------------------------------------------------
*/

CREATE OR REPLACE PACKAGE PKG_MLP_CLASSIFIER IS

     TYPE T_WEIGHT IS TABLE OF NUMERIC(20, 10) INDEX BY BINARY_INTEGER;
     TYPE T_INPUTS IS TABLE OF NUMERIC(10) INDEX BY BINARY_INTEGER;
     TYPE T_STRUCTURE IS RECORD(
          WEIGHT T_WEIGHT,
          INPUT  NUMERIC(20, 10),
          DELTA  NUMERIC(20, 10),
          OUTPUT NUMERIC(20, 10));
     TYPE T_NODE IS TABLE OF T_STRUCTURE INDEX BY BINARY_INTEGER;
     TYPE T_NETWORK IS TABLE OF T_NODE INDEX BY BINARY_INTEGER;
		 Type T_RETORNO is RECORD (
		 			 VALUE     NUMERIC(20,10),
           INDICE    NUMERIC(5)
		  );

     procedure execute;

END PKG_MLP_CLASSIFIER;
/
CREATE OR REPLACE PACKAGE BODY PKG_MLP_CLASSIFIER IS

     SUBTYPE DEC_20_10 IS NUMERIC(20,
                                  10);
     G_INPUTS  INTEGER;
     G_OUTPUTS INTEGER;
     V_NETWORK T_NETWORK;
     V_DATASET T_NETWORK;

     PROCEDURE INITIALIZE_NETWORK
     (
          N_INPUTS  INTEGER, -- NUMERO DE NEURONIOS ENTRADA
          N_HIDDEN  INTEGER, -- NUMERO DE NEURONIOS CAMADA OCULTA
          N_OUTPUTS INTEGER -- NUMERO DE CLASSES DE SAIDA
          
     ) IS
          OUTPUT_LAYER T_NODE;
     BEGIN
          DBMS_OUTPUT.PUT_LINE('===========================================================');
          DBMS_OUTPUT.PUT_LINE('     [ Rede Neural ] MLP com ORACLE 12g (versão 1.0)');
          DBMS_OUTPUT.PUT_LINE('Aprendizado Supervisionado de Rede Perceptron Multicamadas ');
          DBMS_OUTPUT.PUT_LINE('com retropropagação via SQL para problema de Classificação');
          DBMS_OUTPUT.PUT_LINE(' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
          DBMS_OUTPUT.PUT_LINE('Autor: Israel de oliveira - 2019 (Licenca Apache v2)');
          DBMS_OUTPUT.PUT_LINE('https://www.linkedin.com/in/israeloliveira2035/');
          DBMS_OUTPUT.PUT_LINE('https://computacaocognitiva.blogspot.com/');
          DBMS_OUTPUT.PUT_LINE('Use livremente, mantenha a autoria. :) ');
          DBMS_OUTPUT.PUT_LINE('===========================================================');
          DBMS_OUTPUT.PUT_LINE('');
          
          FOR HIDDEN_NEURON IN 0 .. N_HIDDEN - 1
          LOOP
               FOR CONEXAO_NEURON IN 0 .. N_INPUTS - 1
               LOOP
                    V_NETWORK(0)(HIDDEN_NEURON).WEIGHT(CONEXAO_NEURON) := DBMS_RANDOM.VALUE;
               END LOOP;
          END LOOP;
          -- poderia ser um valor sequencial, 1 ou 0 - os valores serao ajustados ao delta
          FOR OUTPUT_NEURON IN 0 .. N_OUTPUTS - 1
          LOOP
               FOR CONEXAO_NEURON IN 0 .. N_HIDDEN - 1
               LOOP
                    OUTPUT_LAYER(OUTPUT_NEURON).WEIGHT(CONEXAO_NEURON) := DBMS_RANDOM.VALUE;
               END LOOP;
          END LOOP;
          V_NETWORK(1) := OUTPUT_LAYER;
     END;


     FUNCTION ACTIVATE
     (
          WEIGHTS T_WEIGHT,
          INPUTS  T_WEIGHT
     ) RETURN DEC_20_10 IS
          ACTIVATION DEC_20_10;
     BEGIN
          ACTIVATION := WEIGHTS(WEIGHTS.COUNT - 1);
          FOR I IN 0 .. WEIGHTS.COUNT - 1
          LOOP
               ACTIVATION := ACTIVATION + WEIGHTS(I) * INPUTS(I);
          END LOOP;
          RETURN(ACTIVATION);
     END;

     -- 
     FUNCTION TRANSFER(ACTIVATION DEC_20_10) RETURN DEC_20_10 IS
     BEGIN
          RETURN(1.0 / (1.0 + EXP(-ACTIVATION)));
     END;

     FUNCTION FORWARD_PROPAGATE(ROW T_WEIGHT) RETURN T_WEIGHT IS
          NEW_INPUTS T_WEIGHT;
          INPUTS     T_WEIGHT;
          ACTIVATION DEC_20_10;
     BEGIN
          INPUTS := ROW;
          FOR I IN 0 .. V_NETWORK.COUNT - 1
          LOOP
               NEW_INPUTS.DELETE();
               FOR J IN 0 .. V_NETWORK(I).COUNT - 1
               LOOP
                    ACTIVATION := ACTIVATE(V_NETWORK(I) (J).WEIGHT,
                                           INPUTS);
                    V_NETWORK(I)(J).OUTPUT := TRANSFER(ACTIVATION);
                    NEW_INPUTS(J) := V_NETWORK(I) (J).OUTPUT;
               END LOOP;
               INPUTS := NEW_INPUTS;
          END LOOP;
          RETURN NEW_INPUTS;
     END;


     -- CALCULATE THE DERIVATIVE OF AN NEURON OUTPUT     
     FUNCTION TRANSFER_DERIVATIVE(OUTPUT DEC_20_10) RETURN DEC_20_10 IS
     BEGIN
          RETURN OUTPUT *(1.0 - OUTPUT);
     END;


     -- BACKPROPAGATE ERROR AND STORE IN NEURONS
     PROCEDURE BACKWARD_PROPAGATE_ERROR(EXPECTED T_WEIGHT) IS
          ERRORS T_WEIGHT;
          ERROR  DEC_20_10;
     BEGIN
          FOR I IN REVERSE 0 .. V_NETWORK.COUNT - 1
          LOOP
               ERRORS.DELETE();
               IF I != V_NETWORK.COUNT - 1 THEN
                    FOR J IN 0 .. V_NETWORK(I).COUNT - 1
                    LOOP
                         ERROR := 0.0;
                         FOR N IN 0 .. V_NETWORK(I + 1).COUNT - 1
                         LOOP
                              ERROR := ERROR +
                                       (V_NETWORK(I + 1) (N).WEIGHT(J) * V_NETWORK(I + 1) (N).DELTA);
                         END LOOP;
                         ERRORS(ERRORS.COUNT) := ERROR;
                    END LOOP;
               ELSE
                    FOR J IN 0 .. V_NETWORK(I).COUNT - 1
                    LOOP
                         ERRORS(ERRORS.COUNT) := EXPECTED(J) - V_NETWORK(I) (J).OUTPUT;
                    END LOOP;
               END IF;
          
               FOR J IN 0 .. V_NETWORK(I).COUNT - 1
               LOOP
                    V_NETWORK(I)(J).DELTA := ERRORS(J) *
                                             TRANSFER_DERIVATIVE(V_NETWORK(I) (J).OUTPUT);
               END LOOP;
          END LOOP;
     END;

     PROCEDURE PRINTPESOS IS
     BEGIN
          DBMS_OUTPUT.PUT_LINE(chr(10)||'-----------------[ PESOS ] -------------------------'); 
          FOR N IN 0 .. V_NETWORK.COUNT - 1
          LOOP
               FOR L IN 0 .. V_NETWORK(N).COUNT - 1
               LOOP
                    FOR W IN 0 .. V_NETWORK(N).COUNT - 1
                    LOOP
                         DBMS_OUTPUT.PUT_LINE('> N = ' || TO_CHAR(N) || ', L = ' ||
                                              TO_CHAR(L) || ', W = ' || TO_CHAR(W) || ', CNX = > ' ||
                                              TO_CHAR(V_NETWORK(N) (L).WEIGHT(W)) || ', OUT = > ' ||
                                              TO_CHAR(V_NETWORK(N) (L).OUTPUT));
                    END LOOP;
               END LOOP;
          END LOOP;
     END;


     PROCEDURE UPDATE_WEIGHTS
     (
          ROW    T_WEIGHT,
          L_RATE NUMBER
     ) IS
          INPUTS T_WEIGHT;
          -- NEURON T_STRUCTURE;
     BEGIN
          -- PRINTPESOS;
          FOR I IN 0 .. V_NETWORK.COUNT - 1
          LOOP
               IF I = 0 THEN
                    -- PRIMEIRA CAMADA
                    FOR Z IN 0 .. ROW.COUNT - 2 -- NAO INCLUIR O ULTIMO
                    LOOP
                         INPUTS(Z) := ROW(Z);
                    END LOOP;
               ELSIF I != 0 THEN
                    -- OUTRAS CAMADAS
                    FOR Z IN 0 .. V_NETWORK(I - 1).COUNT - 2
                    LOOP
                         INPUTS(Z) := V_NETWORK(I - 1) (Z).OUTPUT;
                    END LOOP;
               END IF;
          
          
               FOR Z IN 0 .. V_NETWORK(I).COUNT - 1
               LOOP
                    FOR J IN 0 .. INPUTS.COUNT - 1
                    LOOP
                         V_NETWORK(I)(Z).WEIGHT(J) := V_NETWORK(I) (Z)
                                                     .WEIGHT(J) + L_RATE * V_NETWORK(I) (Z)
                                                     .DELTA * INPUTS(J);
                    END LOOP;
               
                    V_NETWORK(I)(Z).WEIGHT(V_NETWORK(I)(Z).WEIGHT.COUNT - 1) := V_NETWORK(I) (Z)
                                                                               .WEIGHT(V_NETWORK(I) (Z)
                                                                                       .WEIGHT.COUNT - 1) +
                                                                                L_RATE *
                                                                                V_NETWORK(I) (Z)
                                                                               .DELTA;
               END LOOP;
          END LOOP;
     END;

     PROCEDURE TRAIN_NETWORK
     (
          L_RATE    NUMERIC,
          N_EPOCH   NUMERIC,
          N_OUTPUTS NUMERIC
     ) IS
          ROW       T_WEIGHT;
          SUM_ERROR DEC_20_10;
          OUTPUTS   T_WEIGHT;
          EXPECTED  T_WEIGHT;
     BEGIN
 				  DBMS_OUTPUT.PUT_LINE('-----------[ TREINAMENTO ]---------- ');
 				  DBMS_OUTPUT.PUT_LINE('    EPOCA      TAXA        ERRO  ');
          FOR EPOCH IN 0 .. N_EPOCH - 1
          LOOP
          
               SUM_ERROR := 0;
               FOR R IN 0 .. V_DATASET.COUNT - 1
               LOOP
                    FOR Q IN 0 .. V_DATASET(R).COUNT - 1
                    LOOP
                         ROW(Q) := V_DATASET(R) (Q).INPUT;
                    END LOOP;
                    OUTPUTS := FORWARD_PROPAGATE(ROW);
                    EXPECTED.DELETE;
                    FOR Z IN 0 .. N_OUTPUTS - 1
                    LOOP
                         EXPECTED(Z) := 0;
                    END LOOP;
               
                    EXPECTED(ROW(ROW.COUNT - 1)) := 1;
                    SUM_ERROR := 0;
                    FOR Z IN 0 .. EXPECTED.COUNT - 1
                    LOOP
                         SUM_ERROR := SUM_ERROR + POWER(EXPECTED(Z) - OUTPUTS(Z),
                                                        2);
                    END LOOP;
               
                    BACKWARD_PROPAGATE_ERROR(EXPECTED);
                    UPDATE_WEIGHTS(ROW,
                                   L_RATE);
               END LOOP;
               if EPOCH = 0 or EPOCH = N_EPOCH -1 or mod(EPOCH,10) = 0 then
								 DBMS_OUTPUT.PUT_LINE(' > ' || rpad(TO_CHAR(EPOCH),10) || 
            																		rpad(TO_CHAR(L_RATE,
																							'0.000'),10) || 
																			rpad(TO_CHAR(SUM_ERROR,
																							'0.00000'),12));
					     end if;
          END LOOP;
     END;

     PROCEDURE LOAD_DATASET IS
          LINE T_NODE;
     BEGIN
          /*
             TODAS AS COLUNAS DEVEM SER DO TIPO NUMERIC
             A ULTIMA COLUNA DEVE SER DO TIPO NUMERIC(X,0)
          */
          -- DATASET SAMPLE FROM HTTPS://ARCHIVE.ICS.UCI.EDU/ML/DATASETS/
          LINE(0).INPUT := 2.7810836;
          LINE(1).INPUT := 2.550537003;
          LINE(2).INPUT := 0;
          V_DATASET(0) := LINE; -- [ DATOS  DADOS  CLASSE ]
          LINE(0).INPUT := 1.465489372;
          LINE(1).INPUT := 2.362125076;
          LINE(2).INPUT := 0;
          V_DATASET(1) := LINE;
          LINE(0).INPUT := 3.396561688;
          LINE(1).INPUT := 4.400293529;
          LINE(2).INPUT := 0;
          V_DATASET(2) := LINE;
          LINE(0).INPUT := 1.38807019;
          LINE(1).INPUT := 1.850220317;
          LINE(2).INPUT := 0;
          V_DATASET(3) := LINE;
          LINE(0).INPUT := 3.06407232;
          LINE(1).INPUT := 3.005305973;
          LINE(2).INPUT := 0;
          V_DATASET(4) := LINE;
          LINE(0).INPUT := 7.627531214;
          LINE(1).INPUT := 2.759262235;
          LINE(2).INPUT := 1;
          V_DATASET(5) := LINE;
          LINE(0).INPUT := 5.332441248;
          LINE(1).INPUT := 2.088626775;
          LINE(2).INPUT := 1;
          V_DATASET(6) := LINE;
          LINE(0).INPUT := 6.922596716;
          LINE(1).INPUT := 1.77106367;
          LINE(2).INPUT := 1;
          V_DATASET(7) := LINE;
          LINE(0).INPUT := 8.675418651;
          LINE(1).INPUT := -0.242068655;
          LINE(2).INPUT := 1;
          V_DATASET(8) := LINE;
          LINE(0).INPUT := 7.673756466;
          LINE(1).INPUT := 3.508563011;
          LINE(2).INPUT := 1;
          V_DATASET(9) := LINE;
          G_INPUTS  := V_DATASET(0).COUNT; -- NUMERO INSTANCIAS (3)
          G_OUTPUTS := 2; -- NUMERO DE CLASSES 
     END;
		 
    --  Realiza predicoes baseadas no aprendizado
    function predict(ROW T_WEIGHT) return T_RETORNO is
       OUTPUTS   T_WEIGHT;
			 VALUE     NUMERIC(20,10);
			 INDICE    NUMERIC(5);
			 V_RETORNO T_RETORNO;
		begin
        OUTPUTS := FORWARD_PROPAGATE(ROW);
				INDICE := -1;
				VALUE := -1;
		    FOR J IN 0 .. OUTPUTS.COUNT -1
				LOOP
					 if OUTPUTS(j) > VALUE then
					    INDICE := J;
							VALUE := OUTPUTS(j);
					 END IF;
				END LOOP;
				V_RETORNO.INDICE := INDICE;
				V_RETORNO.VALUE := VALUE;
				RETURN(V_RETORNO);
		end;
		
			 

     PROCEDURE EXECUTE IS
          TEST_RETURN T_WEIGHT;
					x T_RETORNO;
     BEGIN
          DBMS_OUTPUT.ENABLE(500000);
          LOAD_DATASET;
     
          INITIALIZE_NETWORK(N_INPUTS  => 3,
                             N_HIDDEN  => 2,
                             N_OUTPUTS => G_OUTPUTS);
     
          TRAIN_NETWORK(L_RATE    => 2.1,
                        N_EPOCH   => 200,
                        N_OUTPUTS => G_OUTPUTS);
          PRINTPESOS;
     
     
          TEST_RETURN(0) := 1.332441248;
          TEST_RETURN(1) := 1.088626775;
          TEST_RETURN(2) := -1;
					x := predict(test_return);
 				  DBMS_OUTPUT.PUT_LINE(chr(10)||'-----------[ TESTE ]---------- ');
					DBMS_OUTPUT.PUT_LINE('Classe provavel : '||to_char(x.INDICE));
					DBMS_OUTPUT.PUT_LINE('Classe probabilidade : '||to_char(x.VALUE * 100 ));
     END;

END PKG_MLP_CLASSIFIER;
/
