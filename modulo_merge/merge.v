module merge (R_bg, G_bg, B_bg, R_sp, G_sp, B_sp, R_outRegA, G_outRegA, B_outRegA, R_outRegB, G_outRegB, B_outRegB, posX_bg, posY_bg, posX_sp, posY_sp, reset, clk, readVgaSelector,max_R_top, max_G_top, max_B_top, min_R_top, min_G_top, min_B_top, avg_R_top, avg_G_top, avg_B_top,
                        max_R_bottom, max_G_bottom, max_B_bottom, min_R_bottom, min_G_bottom, min_B_bottom, avg_R_bottom, avg_G_bottom, avg_B_bottom,
                        max_R_right, max_G_right, max_B_right, min_R_right, min_G_right, min_B_right, avg_R_right, avg_G_right, avg_B_right,
                        max_R_left, max_G_left, max_B_left, min_R_left, min_G_left, min_B_left, avg_R_left, avg_G_left, avg_B_left);

    input wire clk, reset, readVgaSelector;
    input wire [7:0] R_bg, G_bg, B_bg, R_sp, G_sp, B_sp;
    input wire [9:0] posX_bg, posY_bg, posX_sp, posY_sp;
    output reg [127:0] R_outRegA, G_outRegA, B_outRegA, R_outRegB, G_outRegB, B_outRegB;
    output reg [7:0] max_R_top, max_G_top, max_B_top, min_R_top, min_G_top, min_B_top, avg_R_top, avg_G_top, avg_B_top,
                        max_R_bottom, max_G_bottom, max_B_bottom, min_R_bottom, min_G_bottom, min_B_bottom, avg_R_bottom, avg_G_bottom, avg_B_bottom,
                        max_R_right, max_G_right, max_B_right, min_R_right, min_G_right, min_B_right, avg_R_right, avg_G_right, avg_B_right,
                        max_R_left, max_G_left, max_B_left, min_R_left, min_G_left, min_B_left, avg_R_left, avg_G_left, avg_B_left;
                        

    localparam SPRITE_SIZE = 16;
    localparam BG_SIZE_X = 1000;
    localparam BG_SIZE_Y = 1000;
    localparam R_trans = 8'h17,
               G_trans = 8'h17,
               B_trans = 8'h17;


    // Registradores para o merge
	reg [3:0] contadorA = 4'b0;
	reg [6:0] base_indexA = 7'b0;
    reg [3:0] contadorB = 4'b0;
	reg [6:0] base_indexB = 7'b0;
    reg full_A = 1'b0;
    reg full_B = 1'b0;

    //Registradores para lógica registrar as posições de ancora dos sprites
    reg [9:0] posicoesX_sp[31:0];
    reg [9:0] posicoesY_sp[31:0]; 
    reg [31:0] contadorPosicao_sp = 32'b0;
    reg iniciarMerge = 1'b0;
    

    //Registradores para salvar as saídas de cada sprite collision bg

    //Sprite_collision_bg do top
    reg [7:0] max_R_top[31:0];
    reg [7:0] max_G_top[31:0];
    reg [7:0] max_B_top[31:0];
    reg [7:0] min_R_top[31:0];
    reg [7:0] min_G_top[31:0];
    reg [7:0] min_B_top[31:0];
    reg [7:0] avg_R_top[31:0];
    reg [7:0] avg_G_top[31:0];
    reg [7:0] avg_B_top[31:0];

    //Sprite_collision_bg do Bottom
    reg [7:0] max_R_bottom[31:0];
    reg [7:0] max_G_bottom[31:0];
    reg [7:0] max_B_bottom[31:0];
    reg [7:0] min_R_bottom[31:0];
    reg [7:0] min_G_bottom[31:0];
    reg [7:0] min_B_bottom[31:0];
    reg [7:0] avg_R_bottom[31:0];
    reg [7:0] avg_G_bottom[31:0];
    reg [7:0] avg_B_bottom[31:0];

    //Sprite_collision_bg do right
    reg [7:0] max_R_right[31:0];
    reg [7:0] max_G_right[31:0];
    reg [7:0] max_B_right[31:0];
    reg [7:0] min_R_right[31:0];
    reg [7:0] min_G_right[31:0];
    reg [7:0] min_B_right[31:0];
    reg [7:0] avg_R_right[31:0];
    reg [7:0] avg_G_right[31:0];
    reg [7:0] avg_B_right[31:0];

    //Sprite_collision_bg do left
    reg [7:0] max_R_left[31:0];
    reg [7:0] max_G_left[31:0];
    reg [7:0] max_B_left[31:0];
    reg [7:0] min_R_left[31:0];
    reg [7:0] min_G_left[31:0];
    reg [7:0] min_B_left[31:0];
    reg [7:0] avg_R_left[31:0];
    reg [7:0] avg_G_left[31:0];
    reg [7:0] avg_B_left[31:0];
    
    
    
    // Se o VGA está lendo B e A está cheio para de mandar para o merge.
    // Se o VGA está lendo A e B está cheio para de mandar para o merge
    assign stopMerge = ((readVgaSelector == 1'b1 && full_A == 1'b1) || (readVgaSelector == 1'b0 && full_B == 1'b1));


    // Pega do processador todas as ancoras dos sprites para calcular o sprite_collision_bg
    always @(posedge clk) begin

        if (reset) begin
            contadorPosicao_sp <= 32'b0;
            iniciarMerge <= 1'b0;
        end
        else begin
            
            contadorPosicao_sp <= contadorPosicao_sp + 1;

            if (contadorPosicao_sp <= 31) begin
                posicoesX_sp[contadorPosicao_sp] <= posX_sp;
                posicoesY_sp[contadorPosicao_sp] <= posY_sp;
            end else begin
                iniciarMerge <= 1'b1; //Conforme tenha todas as posições dos sprites, inicia o processo do merge
            end      
        end
    end



    //Calcula o que será exibido no VGA
    always@(posedge clk) 
    begin
        if (reset)
        begin
            R_outRegA <= 128'b0;
            G_outRegA <= 128'b0;
            B_outRegA <= 128'b0;
            R_outRegB <= 128'b0;
            G_outRegB <= 128'b0;
            B_outRegB <= 128'b0;
            contadorA  <= 4'b0;
			contadorB  <= 4'b0;
			full_A <= 1'b0;
			full_B <= 1'b0;
            collision <= 1'b0;
        end
        else
        begin
            if (iniciarMerge) begin
                base_indexA = contadorA * 8;
                base_indexB = contadorB * 8;

                if (readVgaSelector == 1'b1 && !full_A) //Se o VGA está lendo o registrador tipo B prepara os pixels do registrador A,
                begin
                    full_B <= 1'b0; //ComeÃ§a a ler o registrador A, volta o estado de full_B para 0.

                    if (R_sp == R_trans && G_sp == G_trans && B_sp == B_trans) //Verifica se a entrada do sprit Ã© a cor transparente naquele pixel, se for preenche com o background
                    begin 
                        R_outRegA[base_indexA +: 8] <= R_bg;
                        G_outRegA[base_indexA +: 8] <= G_bg;
                        B_outRegA[base_indexA +: 8] <= B_bg;
                    end
                    else begin
                        R_outRegA[base_indexA +: 8] <= R_sp;
                        G_outRegA[base_indexA +: 8] <= G_sp;
                        B_outRegA[base_indexA +: 8] <= B_sp;
                    end

                    contadorA <= contadorA + 1;
                    if (contadorA == 15) begin // Reinicia o contador apÃ³s o Ãºltimo conjunto de 8 bits (16 * 8 = 128 bits)
                        full_A <= 1'b1;
                        contadorA <= 4'b0;   
                    end

                end else if (readVgaSelector == 1'b0 && !full_B) begin

                    full_A <= 1'b0; //Começa a ler o registrador A, volta o estado de full_A para 0.

                    if (R_sp == R_trans && G_sp == G_trans && B_sp == B_trans) //Verifica se a entrada do sprit Ã© a cor transparente naquele pixel, se for preenche com o background
                    begin 
                        R_outRegB[base_indexB +: 8] <= R_bg;
                        G_outRegB[base_indexB +: 8] <= G_bg;
                        B_outRegB[base_indexB +: 8] <= B_bg;
                    end
                    else begin
                        R_outRegB[base_indexB +: 8] <= R_sp;
                        G_outRegB[base_indexB +: 8] <= G_sp;
                        B_outRegB[base_indexB +: 8] <= B_sp;
                    end
                    

                    contadorB <= contadorB + 1;

                    if (contadorB == 15) begin // Reinicia o contador apÃ³s o Ãºltimo conjunto de 8 bits (16 * 8 = 128 bits)
                        contadorB <= 4'b0;
                        full_B <= 1'b1;
                    end
                    
                end
            end
        end
    end



    //Calcula a RGB máximo, médio e mínimo de cada sprite que está colidindo com o background
  
    //Sprite 01
    background_collision sd1 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[0]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[0]),
        .max_R_top(max_R_top[0]),
        .max_G_top(max_G_top[0]),
        .max_B_top(max_B_top[0]),
        .min_R_top(min_R_top[0]),
        .min_G_top(min_G_top[0]),
        .min_B_top(min_B_top[0]),
        .avg_R_top(avg_R_top[0]),
        .avg_G_top(avg_G_top[0]),
        .avg_B_top(avg_B_top[0]),
        .max_R_bottom(max_R_bottom[0]),
        .max_G_bottom(max_G_bottom[0]),
        .max_B_bottom(max_B_bottom[0]),
        .min_R_bottom(min_R_bottom[0]),
        .min_G_bottom(min_G_bottom[0]),
        .min_B_bottom(min_B_bottom[0]),
        .avg_R_bottom(avg_R_bottom[0]),
        .avg_G_bottom(avg_G_bottom[0]),
        .avg_B_bottom(avg_B_bottom[0]),
        .max_R_right(max_R_right[0]),
        .max_G_right(max_G_right[0]),
        .max_B_right(max_B_right[0]),
        .min_R_right(min_R_right[0]),
        .min_G_right(min_G_right[0]),
        .min_B_right(min_B_right[0]),
        .avg_R_right(avg_R_right[0]),
        .avg_G_right(avg_G_right[0]),
        .avg_B_right(avg_B_right[0]),
        .max_R_left(max_R_left[0]),
        .max_G_left(max_G_left[0]),
        .max_B_left(max_B_left[0]),
        .min_R_left(min_R_left[0]),
        .min_G_left(min_G_left[0]),
        .min_B_left(min_B_left[0]),
        .avg_R_left(avg_R_left[0]),
        .avg_G_left(avg_G_left[0]),
        .avg_B_left(avg_B_left[0])
    );



    //Sprite 02
    background_collision sprite02 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[1]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[1]),
        .max_R_top(max_R_top[1]),
        .max_G_top(max_G_top[1]),
        .max_B_top(max_B_top[1]),
        .min_R_top(min_R_top[1]),
        .min_G_top(min_G_top[1]),
        .min_B_top(min_B_top[1]),
        .avg_R_top(avg_R_top[1]),
        .avg_G_top(avg_G_top[1]),
        .avg_B_top(avg_B_top[1]),
        .max_R_bottom(max_R_bottom[1]),
        .max_G_bottom(max_G_bottom[1]),
        .max_B_bottom(max_B_bottom[1]),
        .min_R_bottom(min_R_bottom[1]),
        .min_G_bottom(min_G_bottom[1]),
        .min_B_bottom(min_B_bottom[1]),
        .avg_R_bottom(avg_R_bottom[1]),
        .avg_G_bottom(avg_G_bottom[1]),
        .avg_B_bottom(avg_B_bottom[1]),
        .max_R_right(max_R_right[1]),
        .max_G_right(max_G_right[1]),
        .max_B_right(max_B_right[1]),
        .min_R_right(min_R_right[1]),
        .min_G_right(min_G_right[1]),
        .min_B_right(min_B_right[1]),
        .avg_R_right(avg_R_right[1]),
        .avg_G_right(avg_G_right[1]),
        .avg_B_right(avg_B_right[1]),
        .max_R_left(max_R_left[1]),
        .max_G_left(max_G_left[1]),
        .max_B_left(max_B_left[1]),
        .min_R_left(min_R_left[1]),
        .min_G_left(min_G_left[1]),
        .min_B_left(min_B_left[1]),
        .avg_R_left(avg_R_left[1]),
        .avg_G_left(avg_G_left[1]),
        .avg_B_left(avg_B_left[1])
    );


    //Sprite 03
    background_collision sprite03 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[2]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[2]),
        .max_R_top(max_R_top[2]),
        .max_G_top(max_G_top[2]),
        .max_B_top(max_B_top[2]),
        .min_R_top(min_R_top[2]),
        .min_G_top(min_G_top[2]),
        .min_B_top(min_B_top[2]),
        .avg_R_top(avg_R_top[2]),
        .avg_G_top(avg_G_top[2]),
        .avg_B_top(avg_B_top[2]),
        .max_R_bottom(max_R_bottom[2]),
        .max_G_bottom(max_G_bottom[2]),
        .max_B_bottom(max_B_bottom[2]),
        .min_R_bottom(min_R_bottom[2]),
        .min_G_bottom(min_G_bottom[2]),
        .min_B_bottom(min_B_bottom[2]),
        .avg_R_bottom(avg_R_bottom[2]),
        .avg_G_bottom(avg_G_bottom[2]),
        .avg_B_bottom(avg_B_bottom[2]),
        .max_R_right(max_R_right[2]),
        .max_G_right(max_G_right[2]),
        .max_B_right(max_B_right[2]),
        .min_R_right(min_R_right[2]),
        .min_G_right(min_G_right[2]),
        .min_B_right(min_B_right[2]),
        .avg_R_right(avg_R_right[2]),
        .avg_G_right(avg_G_right[2]),
        .avg_B_right(avg_B_right[2]),
        .max_R_left(max_R_left[2]),
        .max_G_left(max_G_left[2]),
        .max_B_left(max_B_left[2]),
        .min_R_left(min_R_left[2]),
        .min_G_left(min_G_left[2]),
        .min_B_left(min_B_left[2]),
        .avg_R_left(avg_R_left[2]),
        .avg_G_left(avg_G_left[2]),
        .avg_B_left(avg_B_left[2])
    );


    //Sprite 04
    background_collision sprite04 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[3]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[3]),
        .max_R_top(max_R_top[3]),
        .max_G_top(max_G_top[3]),
        .max_B_top(max_B_top[3]),
        .min_R_top(min_R_top[3]),
        .min_G_top(min_G_top[3]),
        .min_B_top(min_B_top[3]),
        .avg_R_top(avg_R_top[3]),
        .avg_G_top(avg_G_top[3]),
        .avg_B_top(avg_B_top[3]),
        .max_R_bottom(max_R_bottom[3]),
        .max_G_bottom(max_G_bottom[3]),
        .max_B_bottom(max_B_bottom[3]),
        .min_R_bottom(min_R_bottom[3]),
        .min_G_bottom(min_G_bottom[3]),
        .min_B_bottom(min_B_bottom[3]),
        .avg_R_bottom(avg_R_bottom[3]),
        .avg_G_bottom(avg_G_bottom[3]),
        .avg_B_bottom(avg_B_bottom[3]),
        .max_R_right(max_R_right[3]),
        .max_G_right(max_G_right[3]),
        .max_B_right(max_B_right[3]),
        .min_R_right(min_R_right[3]),
        .min_G_right(min_G_right[3]),
        .min_B_right(min_B_right[3]),
        .avg_R_right(avg_R_right[3]),
        .avg_G_right(avg_G_right[3]),
        .avg_B_right(avg_B_right[3]),
        .max_R_left(max_R_left[3]),
        .max_G_left(max_G_left[3]),
        .max_B_left(max_B_left[3]),
        .min_R_left(min_R_left[3]),
        .min_G_left(min_G_left[3]),
        .min_B_left(min_B_left[3]),
        .avg_R_left(avg_R_left[3]),
        .avg_G_left(avg_G_left[3]),
        .avg_B_left(avg_B_left[3])
    );


    //Sprite 05
    background_collision sprite05 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[4]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[4]),
        .max_R_top(max_R_top[4]),
        .max_G_top(max_G_top[4]),
        .max_B_top(max_B_top[4]),
        .min_R_top(min_R_top[4]),
        .min_G_top(min_G_top[4]),
        .min_B_top(min_B_top[4]),
        .avg_R_top(avg_R_top[4]),
        .avg_G_top(avg_G_top[4]),
        .avg_B_top(avg_B_top[4]),
        .max_R_bottom(max_R_bottom[4]),
        .max_G_bottom(max_G_bottom[4]),
        .max_B_bottom(max_B_bottom[4]),
        .min_R_bottom(min_R_bottom[4]),
        .min_G_bottom(min_G_bottom[4]),
        .min_B_bottom(min_B_bottom[4]),
        .avg_R_bottom(avg_R_bottom[4]),
        .avg_G_bottom(avg_G_bottom[4]),
        .avg_B_bottom(avg_B_bottom[4]),
        .max_R_right(max_R_right[4]),
        .max_G_right(max_G_right[4]),
        .max_B_right(max_B_right[4]),
        .min_R_right(min_R_right[4]),
        .min_G_right(min_G_right[4]),
        .min_B_right(min_B_right[4]),
        .avg_R_right(avg_R_right[4]),
        .avg_G_right(avg_G_right[4]),
        .avg_B_right(avg_B_right[4]),
        .max_R_left(max_R_left[4]),
        .max_G_left(max_G_left[4]),
        .max_B_left(max_B_left[4]),
        .min_R_left(min_R_left[4]),
        .min_G_left(min_G_left[4]),
        .min_B_left(min_B_left[4]),
        .avg_R_left(avg_R_left[4]),
        .avg_G_left(avg_G_left[4]),
        .avg_B_left(avg_B_left[4])
    );

    //Sprite 06
    background_collision sprite06 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[5]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[5]),
        .max_R_top(max_R_top[5]),
        .max_G_top(max_G_top[5]),
        .max_B_top(max_B_top[5]),
        .min_R_top(min_R_top[5]),
        .min_G_top(min_G_top[5]),
        .min_B_top(min_B_top[5]),
        .avg_R_top(avg_R_top[5]),
        .avg_G_top(avg_G_top[5]),
        .avg_B_top(avg_B_top[5]),
        .max_R_bottom(max_R_bottom[5]),
        .max_G_bottom(max_G_bottom[5]),
        .max_B_bottom(max_B_bottom[5]),
        .min_R_bottom(min_R_bottom[5]),
        .min_G_bottom(min_G_bottom[5]),
        .min_B_bottom(min_B_bottom[5]),
        .avg_R_bottom(avg_R_bottom[5]),
        .avg_G_bottom(avg_G_bottom[5]),
        .avg_B_bottom(avg_B_bottom[5]),
        .max_R_right(max_R_right[5]),
        .max_G_right(max_G_right[5]),
        .max_B_right(max_B_right[5]),
        .min_R_right(min_R_right[5]),
        .min_G_right(min_G_right[5]),
        .min_B_right(min_B_right[5]),
        .avg_R_right(avg_R_right[5]),
        .avg_G_right(avg_G_right[5]),
        .avg_B_right(avg_B_right[5]),
        .max_R_left(max_R_left[5]),
        .max_G_left(max_G_left[5]),
        .max_B_left(max_B_left[5]),
        .min_R_left(min_R_left[5]),
        .min_G_left(min_G_left[5]),
        .min_B_left(min_B_left[5]),
        .avg_R_left(avg_R_left[5]),
        .avg_G_left(avg_G_left[5]),
        .avg_B_left(avg_B_left[5])
    );


    //Sprite 07
    background_collision sprite07 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[6]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[6]),
        .max_R_top(max_R_top[6]),
        .max_G_top(max_G_top[6]),
        .max_B_top(max_B_top[6]),
        .min_R_top(min_R_top[6]),
        .min_G_top(min_G_top[6]),
        .min_B_top(min_B_top[6]),
        .avg_R_top(avg_R_top[6]),
        .avg_G_top(avg_G_top[6]),
        .avg_B_top(avg_B_top[6]),
        .max_R_bottom(max_R_bottom[6]),
        .max_G_bottom(max_G_bottom[6]),
        .max_B_bottom(max_B_bottom[6]),
        .min_R_bottom(min_R_bottom[6]),
        .min_G_bottom(min_G_bottom[6]),
        .min_B_bottom(min_B_bottom[6]),
        .avg_R_bottom(avg_R_bottom[6]),
        .avg_G_bottom(avg_G_bottom[6]),
        .avg_B_bottom(avg_B_bottom[6]),
        .max_R_right(max_R_right[6]),
        .max_G_right(max_G_right[6]),
        .max_B_right(max_B_right[6]),
        .min_R_right(min_R_right[6]),
        .min_G_right(min_G_right[6]),
        .min_B_right(min_B_right[6]),
        .avg_R_right(avg_R_right[6]),
        .avg_G_right(avg_G_right[6]),
        .avg_B_right(avg_B_right[6]),
        .max_R_left(max_R_left[6]),
        .max_G_left(max_G_left[6]),
        .max_B_left(max_B_left[6]),
        .min_R_left(min_R_left[6]),
        .min_G_left(min_G_left[6]),
        .min_B_left(min_B_left[6]),
        .avg_R_left(avg_R_left[6]),
        .avg_G_left(avg_G_left[6]),
        .avg_B_left(avg_B_left[6])
    );

    //Sprite 08
    background_collision sprite08 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[7]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[7]),
        .max_R_top(max_R_top[7]),
        .max_G_top(max_G_top[7]),
        .max_B_top(max_B_top[7]),
        .min_R_top(min_R_top[7]),
        .min_G_top(min_G_top[7]),
        .min_B_top(min_B_top[7]),
        .avg_R_top(avg_R_top[7]),
        .avg_G_top(avg_G_top[7]),
        .avg_B_top(avg_B_top[7]),
        .max_R_bottom(max_R_bottom[7]),
        .max_G_bottom(max_G_bottom[7]),
        .max_B_bottom(max_B_bottom[7]),
        .min_R_bottom(min_R_bottom[7]),
        .min_G_bottom(min_G_bottom[7]),
        .min_B_bottom(min_B_bottom[7]),
        .avg_R_bottom(avg_R_bottom[7]),
        .avg_G_bottom(avg_G_bottom[7]),
        .avg_B_bottom(avg_B_bottom[7]),
        .max_R_right(max_R_right[7]),
        .max_G_right(max_G_right[7]),
        .max_B_right(max_B_right[7]),
        .min_R_right(min_R_right[7]),
        .min_G_right(min_G_right[7]),
        .min_B_right(min_B_right[7]),
        .avg_R_right(avg_R_right[7]),
        .avg_G_right(avg_G_right[7]),
        .avg_B_right(avg_B_right[7]),
        .max_R_left(max_R_left[7]),
        .max_G_left(max_G_left[7]),
        .max_B_left(max_B_left[7]),
        .min_R_left(min_R_left[7]),
        .min_G_left(min_G_left[7]),
        .min_B_left(min_B_left[7]),
        .avg_R_left(avg_R_left[7]),
        .avg_G_left(avg_G_left[7]),
        .avg_B_left(avg_B_left[7])
    );

    //Sprite 09
    background_collision sprite09 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[8]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[8]),
        .max_R_top(max_R_top[8]),
        .max_G_top(max_G_top[8]),
        .max_B_top(max_B_top[8]),
        .min_R_top(min_R_top[8]),
        .min_G_top(min_G_top[8]),
        .min_B_top(min_B_top[8]),
        .avg_R_top(avg_R_top[8]),
        .avg_G_top(avg_G_top[8]),
        .avg_B_top(avg_B_top[8]),
        .max_R_bottom(max_R_bottom[8]),
        .max_G_bottom(max_G_bottom[8]),
        .max_B_bottom(max_B_bottom[8]),
        .min_R_bottom(min_R_bottom[8]),
        .min_G_bottom(min_G_bottom[8]),
        .min_B_bottom(min_B_bottom[8]),
        .avg_R_bottom(avg_R_bottom[8]),
        .avg_G_bottom(avg_G_bottom[8]),
        .avg_B_bottom(avg_B_bottom[8]),
        .max_R_right(max_R_right[8]),
        .max_G_right(max_G_right[8]),
        .max_B_right(max_B_right[8]),
        .min_R_right(min_R_right[8]),
        .min_G_right(min_G_right[8]),
        .min_B_right(min_B_right[8]),
        .avg_R_right(avg_R_right[8]),
        .avg_G_right(avg_G_right[8]),
        .avg_B_right(avg_B_right[8]),
        .max_R_left(max_R_left[8]),
        .max_G_left(max_G_left[8]),
        .max_B_left(max_B_left[8]),
        .min_R_left(min_R_left[8]),
        .min_G_left(min_G_left[8]),
        .min_B_left(min_B_left[8]),
        .avg_R_left(avg_R_left[8]),
        .avg_G_left(avg_G_left[8]),
        .avg_B_left(avg_B_left[8])
    );

    //Sprite 010
    background_collision sprite10 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[10]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[10]),
        .max_R_top(max_R_top[10]),
        .max_G_top(max_G_top[10]),
        .max_B_top(max_B_top[10]),
        .min_R_top(min_R_top[10]),
        .min_G_top(min_G_top[10]),
        .min_B_top(min_B_top[10]),
        .avg_R_top(avg_R_top[10]),
        .avg_G_top(avg_G_top[10]),
        .avg_B_top(avg_B_top[10]),
        .max_R_bottom(max_R_bottom[10]),
        .max_G_bottom(max_G_bottom[10]),
        .max_B_bottom(max_B_bottom[10]),
        .min_R_bottom(min_R_bottom[10]),
        .min_G_bottom(min_G_bottom[10]),
        .min_B_bottom(min_B_bottom[10]),
        .avg_R_bottom(avg_R_bottom[10]),
        .avg_G_bottom(avg_G_bottom[10]),
        .avg_B_bottom(avg_B_bottom[10]),
        .max_R_right(max_R_right[10]),
        .max_G_right(max_G_right[10]),
        .max_B_right(max_B_right[10]),
        .min_R_right(min_R_right[10]),
        .min_G_right(min_G_right[10]),
        .min_B_right(min_B_right[10]),
        .avg_R_right(avg_R_right[10]),
        .avg_G_right(avg_G_right[10]),
        .avg_B_right(avg_B_right[10]),
        .max_R_left(max_R_left[10]),
        .max_G_left(max_G_left[10]),
        .max_B_left(max_B_left[10]),
        .min_R_left(min_R_left[10]),
        .min_G_left(min_G_left[10]),
        .min_B_left(min_B_left[10]),
        .avg_R_left(avg_R_left[10]),
        .avg_G_left(avg_G_left[10]),
        .avg_B_left(avg_B_left[10])
    );

    //Sprite 11
    background_collision sprite11 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[10]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[10]),
        .max_R_top(max_R_top[10]),
        .max_G_top(max_G_top[10]),
        .max_B_top(max_B_top[10]),
        .min_R_top(min_R_top[10]),
        .min_G_top(min_G_top[10]),
        .min_B_top(min_B_top[10]),
        .avg_R_top(avg_R_top[10]),
        .avg_G_top(avg_G_top[10]),
        .avg_B_top(avg_B_top[10]),
        .max_R_bottom(max_R_bottom[10]),
        .max_G_bottom(max_G_bottom[10]),
        .max_B_bottom(max_B_bottom[10]),
        .min_R_bottom(min_R_bottom[10]),
        .min_G_bottom(min_G_bottom[10]),
        .min_B_bottom(min_B_bottom[10]),
        .avg_R_bottom(avg_R_bottom[10]),
        .avg_G_bottom(avg_G_bottom[10]),
        .avg_B_bottom(avg_B_bottom[10]),
        .max_R_right(max_R_right[10]),
        .max_G_right(max_G_right[10]),
        .max_B_right(max_B_right[10]),
        .min_R_right(min_R_right[10]),
        .min_G_right(min_G_right[10]),
        .min_B_right(min_B_right[10]),
        .avg_R_right(avg_R_right[10]),
        .avg_G_right(avg_G_right[10]),
        .avg_B_right(avg_B_right[10]),
        .max_R_left(max_R_left[10]),
        .max_G_left(max_G_left[10]),
        .max_B_left(max_B_left[10]),
        .min_R_left(min_R_left[10]),
        .min_G_left(min_G_left[10]),
        .min_B_left(min_B_left[10]),
        .avg_R_left(avg_R_left[10]),
        .avg_G_left(avg_G_left[10]),
        .avg_B_left(avg_B_left[10])
    );

    //Sprite 12
    background_collision sprite12 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[11]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[11]),
        .max_R_top(max_R_top[11]),
        .max_G_top(max_G_top[11]),
        .max_B_top(max_B_top[11]),
        .min_R_top(min_R_top[11]),
        .min_G_top(min_G_top[11]),
        .min_B_top(min_B_top[11]),
        .avg_R_top(avg_R_top[11]),
        .avg_G_top(avg_G_top[11]),
        .avg_B_top(avg_B_top[11]),
        .max_R_bottom(max_R_bottom[11]),
        .max_G_bottom(max_G_bottom[11]),
        .max_B_bottom(max_B_bottom[11]),
        .min_R_bottom(min_R_bottom[11]),
        .min_G_bottom(min_G_bottom[11]),
        .min_B_bottom(min_B_bottom[11]),
        .avg_R_bottom(avg_R_bottom[11]),
        .avg_G_bottom(avg_G_bottom[11]),
        .avg_B_bottom(avg_B_bottom[11]),
        .max_R_right(max_R_right[11]),
        .max_G_right(max_G_right[11]),
        .max_B_right(max_B_right[11]),
        .min_R_right(min_R_right[11]),
        .min_G_right(min_G_right[11]),
        .min_B_right(min_B_right[11]),
        .avg_R_right(avg_R_right[11]),
        .avg_G_right(avg_G_right[11]),
        .avg_B_right(avg_B_right[11]),
        .max_R_left(max_R_left[11]),
        .max_G_left(max_G_left[11]),
        .max_B_left(max_B_left[11]),
        .min_R_left(min_R_left[11]),
        .min_G_left(min_G_left[11]),
        .min_B_left(min_B_left[11]),
        .avg_R_left(avg_R_left[11]),
        .avg_G_left(avg_G_left[11]),
        .avg_B_left(avg_B_left[11])
    );

    //Sprite 13
    background_collision sprite13 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[12]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[12]),
        .max_R_top(max_R_top[12]),
        .max_G_top(max_G_top[12]),
        .max_B_top(max_B_top[12]),
        .min_R_top(min_R_top[12]),
        .min_G_top(min_G_top[12]),
        .min_B_top(min_B_top[12]),
        .avg_R_top(avg_R_top[12]),
        .avg_G_top(avg_G_top[12]),
        .avg_B_top(avg_B_top[12]),
        .max_R_bottom(max_R_bottom[12]),
        .max_G_bottom(max_G_bottom[12]),
        .max_B_bottom(max_B_bottom[12]),
        .min_R_bottom(min_R_bottom[12]),
        .min_G_bottom(min_G_bottom[12]),
        .min_B_bottom(min_B_bottom[12]),
        .avg_R_bottom(avg_R_bottom[12]),
        .avg_G_bottom(avg_G_bottom[12]),
        .avg_B_bottom(avg_B_bottom[12]),
        .max_R_right(max_R_right[12]),
        .max_G_right(max_G_right[12]),
        .max_B_right(max_B_right[12]),
        .min_R_right(min_R_right[12]),
        .min_G_right(min_G_right[12]),
        .min_B_right(min_B_right[12]),
        .avg_R_right(avg_R_right[12]),
        .avg_G_right(avg_G_right[12]),
        .avg_B_right(avg_B_right[12]),
        .max_R_left(max_R_left[12]),
        .max_G_left(max_G_left[12]),
        .max_B_left(max_B_left[12]),
        .min_R_left(min_R_left[12]),
        .min_G_left(min_G_left[12]),
        .min_B_left(min_B_left[12]),
        .avg_R_left(avg_R_left[12]),
        .avg_G_left(avg_G_left[12]),
        .avg_B_left(avg_B_left[12])
    );

    //Sprite 14
    background_collision sprite14 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[13]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[13]),
        .max_R_top(max_R_top[13]),
        .max_G_top(max_G_top[13]),
        .max_B_top(max_B_top[13]),
        .min_R_top(min_R_top[13]),
        .min_G_top(min_G_top[13]),
        .min_B_top(min_B_top[13]),
        .avg_R_top(avg_R_top[13]),
        .avg_G_top(avg_G_top[13]),
        .avg_B_top(avg_B_top[13]),
        .max_R_bottom(max_R_bottom[13]),
        .max_G_bottom(max_G_bottom[13]),
        .max_B_bottom(max_B_bottom[13]),
        .min_R_bottom(min_R_bottom[13]),
        .min_G_bottom(min_G_bottom[13]),
        .min_B_bottom(min_B_bottom[13]),
        .avg_R_bottom(avg_R_bottom[13]),
        .avg_G_bottom(avg_G_bottom[13]),
        .avg_B_bottom(avg_B_bottom[13]),
        .max_R_right(max_R_right[13]),
        .max_G_right(max_G_right[13]),
        .max_B_right(max_B_right[13]),
        .min_R_right(min_R_right[13]),
        .min_G_right(min_G_right[13]),
        .min_B_right(min_B_right[13]),
        .avg_R_right(avg_R_right[13]),
        .avg_G_right(avg_G_right[13]),
        .avg_B_right(avg_B_right[13]),
        .max_R_left(max_R_left[13]),
        .max_G_left(max_G_left[13]),
        .max_B_left(max_B_left[13]),
        .min_R_left(min_R_left[13]),
        .min_G_left(min_G_left[13]),
        .min_B_left(min_B_left[13]),
        .avg_R_left(avg_R_left[13]),
        .avg_G_left(avg_G_left[13]),
        .avg_B_left(avg_B_left[13])
    );

    //Sprite 15
    background_collision sprite15 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[14]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[14]),
        .max_R_top(max_R_top[14]),
        .max_G_top(max_G_top[14]),
        .max_B_top(max_B_top[14]),
        .min_R_top(min_R_top[14]),
        .min_G_top(min_G_top[14]),
        .min_B_top(min_B_top[14]),
        .avg_R_top(avg_R_top[14]),
        .avg_G_top(avg_G_top[14]),
        .avg_B_top(avg_B_top[14]),
        .max_R_bottom(max_R_bottom[14]),
        .max_G_bottom(max_G_bottom[14]),
        .max_B_bottom(max_B_bottom[14]),
        .min_R_bottom(min_R_bottom[14]),
        .min_G_bottom(min_G_bottom[14]),
        .min_B_bottom(min_B_bottom[14]),
        .avg_R_bottom(avg_R_bottom[14]),
        .avg_G_bottom(avg_G_bottom[14]),
        .avg_B_bottom(avg_B_bottom[14]),
        .max_R_right(max_R_right[14]),
        .max_G_right(max_G_right[14]),
        .max_B_right(max_B_right[14]),
        .min_R_right(min_R_right[14]),
        .min_G_right(min_G_right[14]),
        .min_B_right(min_B_right[14]),
        .avg_R_right(avg_R_right[14]),
        .avg_G_right(avg_G_right[14]),
        .avg_B_right(avg_B_right[14]),
        .max_R_left(max_R_left[14]),
        .max_G_left(max_G_left[14]),
        .max_B_left(max_B_left[14]),
        .min_R_left(min_R_left[14]),
        .min_G_left(min_G_left[14]),
        .min_B_left(min_B_left[14]),
        .avg_R_left(avg_R_left[14]),
        .avg_G_left(avg_G_left[14]),
        .avg_B_left(avg_B_left[14])
    );


    //Sprite 16
    background_collision sprite16 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[15]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[15]),
        .max_R_top(max_R_top[15]),
        .max_G_top(max_G_top[15]),
        .max_B_top(max_B_top[15]),
        .min_R_top(min_R_top[15]),
        .min_G_top(min_G_top[15]),
        .min_B_top(min_B_top[15]),
        .avg_R_top(avg_R_top[15]),
        .avg_G_top(avg_G_top[15]),
        .avg_B_top(avg_B_top[15]),
        .max_R_bottom(max_R_bottom[15]),
        .max_G_bottom(max_G_bottom[15]),
        .max_B_bottom(max_B_bottom[15]),
        .min_R_bottom(min_R_bottom[15]),
        .min_G_bottom(min_G_bottom[15]),
        .min_B_bottom(min_B_bottom[15]),
        .avg_R_bottom(avg_R_bottom[15]),
        .avg_G_bottom(avg_G_bottom[15]),
        .avg_B_bottom(avg_B_bottom[15]),
        .max_R_right(max_R_right[15]),
        .max_G_right(max_G_right[15]),
        .max_B_right(max_B_right[15]),
        .min_R_right(min_R_right[15]),
        .min_G_right(min_G_right[15]),
        .min_B_right(min_B_right[15]),
        .avg_R_right(avg_R_right[15]),
        .avg_G_right(avg_G_right[15]),
        .avg_B_right(avg_B_right[15]),
        .max_R_left(max_R_left[15]),
        .max_G_left(max_G_left[15]),
        .max_B_left(max_B_left[15]),
        .min_R_left(min_R_left[15]),
        .min_G_left(min_G_left[15]),
        .min_B_left(min_B_left[15]),
        .avg_R_left(avg_R_left[15]),
        .avg_G_left(avg_G_left[15]),
        .avg_B_left(avg_B_left[15])
    );


    //Sprite 17
    background_collision sprite17 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[16]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[16]),
        .max_R_top(max_R_top[16]),
        .max_G_top(max_G_top[16]),
        .max_B_top(max_B_top[16]),
        .min_R_top(min_R_top[16]),
        .min_G_top(min_G_top[16]),
        .min_B_top(min_B_top[16]),
        .avg_R_top(avg_R_top[16]),
        .avg_G_top(avg_G_top[16]),
        .avg_B_top(avg_B_top[16]),
        .max_R_bottom(max_R_bottom[16]),
        .max_G_bottom(max_G_bottom[16]),
        .max_B_bottom(max_B_bottom[16]),
        .min_R_bottom(min_R_bottom[16]),
        .min_G_bottom(min_G_bottom[16]),
        .min_B_bottom(min_B_bottom[16]),
        .avg_R_bottom(avg_R_bottom[16]),
        .avg_G_bottom(avg_G_bottom[16]),
        .avg_B_bottom(avg_B_bottom[16]),
        .max_R_right(max_R_right[16]),
        .max_G_right(max_G_right[16]),
        .max_B_right(max_B_right[16]),
        .min_R_right(min_R_right[16]),
        .min_G_right(min_G_right[16]),
        .min_B_right(min_B_right[16]),
        .avg_R_right(avg_R_right[16]),
        .avg_G_right(avg_G_right[16]),
        .avg_B_right(avg_B_right[16]),
        .max_R_left(max_R_left[16]),
        .max_G_left(max_G_left[16]),
        .max_B_left(max_B_left[16]),
        .min_R_left(min_R_left[16]),
        .min_G_left(min_G_left[16]),
        .min_B_left(min_B_left[16]),
        .avg_R_left(avg_R_left[16]),
        .avg_G_left(avg_G_left[16]),
        .avg_B_left(avg_B_left[16])
    );

    //Sprite 18
    background_collision sprite18 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[17]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[17]),
        .max_R_top(max_R_top[17]),
        .max_G_top(max_G_top[17]),
        .max_B_top(max_B_top[17]),
        .min_R_top(min_R_top[17]),
        .min_G_top(min_G_top[17]),
        .min_B_top(min_B_top[17]),
        .avg_R_top(avg_R_top[17]),
        .avg_G_top(avg_G_top[17]),
        .avg_B_top(avg_B_top[17]),
        .max_R_bottom(max_R_bottom[17]),
        .max_G_bottom(max_G_bottom[17]),
        .max_B_bottom(max_B_bottom[17]),
        .min_R_bottom(min_R_bottom[17]),
        .min_G_bottom(min_G_bottom[17]),
        .min_B_bottom(min_B_bottom[17]),
        .avg_R_bottom(avg_R_bottom[17]),
        .avg_G_bottom(avg_G_bottom[17]),
        .avg_B_bottom(avg_B_bottom[17]),
        .max_R_right(max_R_right[17]),
        .max_G_right(max_G_right[17]),
        .max_B_right(max_B_right[17]),
        .min_R_right(min_R_right[17]),
        .min_G_right(min_G_right[17]),
        .min_B_right(min_B_right[17]),
        .avg_R_right(avg_R_right[17]),
        .avg_G_right(avg_G_right[17]),
        .avg_B_right(avg_B_right[17]),
        .max_R_left(max_R_left[17]),
        .max_G_left(max_G_left[17]),
        .max_B_left(max_B_left[17]),
        .min_R_left(min_R_left[17]),
        .min_G_left(min_G_left[17]),
        .min_B_left(min_B_left[17]),
        .avg_R_left(avg_R_left[17]),
        .avg_G_left(avg_G_left[17]),
        .avg_B_left(avg_B_left[17])
    );

    //Sprite 19
    background_collision sprite19 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[18]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[18]),
        .max_R_top(max_R_top[18]),
        .max_G_top(max_G_top[18]),
        .max_B_top(max_B_top[18]),
        .min_R_top(min_R_top[18]),
        .min_G_top(min_G_top[18]),
        .min_B_top(min_B_top[18]),
        .avg_R_top(avg_R_top[18]),
        .avg_G_top(avg_G_top[18]),
        .avg_B_top(avg_B_top[18]),
        .max_R_bottom(max_R_bottom[18]),
        .max_G_bottom(max_G_bottom[18]),
        .max_B_bottom(max_B_bottom[18]),
        .min_R_bottom(min_R_bottom[18]),
        .min_G_bottom(min_G_bottom[18]),
        .min_B_bottom(min_B_bottom[18]),
        .avg_R_bottom(avg_R_bottom[18]),
        .avg_G_bottom(avg_G_bottom[18]),
        .avg_B_bottom(avg_B_bottom[18]),
        .max_R_right(max_R_right[18]),
        .max_G_right(max_G_right[18]),
        .max_B_right(max_B_right[18]),
        .min_R_right(min_R_right[18]),
        .min_G_right(min_G_right[18]),
        .min_B_right(min_B_right[18]),
        .avg_R_right(avg_R_right[18]),
        .avg_G_right(avg_G_right[18]),
        .avg_B_right(avg_B_right[18]),
        .max_R_left(max_R_left[18]),
        .max_G_left(max_G_left[18]),
        .max_B_left(max_B_left[18]),
        .min_R_left(min_R_left[18]),
        .min_G_left(min_G_left[18]),
        .min_B_left(min_B_left[18]),
        .avg_R_left(avg_R_left[18]),
        .avg_G_left(avg_G_left[18]),
        .avg_B_left(avg_B_left[18])
    );

    //Sprite 20
    background_collision sprite20 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[19]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[19]),
        .max_R_top(max_R_top[19]),
        .max_G_top(max_G_top[19]),
        .max_B_top(max_B_top[19]),
        .min_R_top(min_R_top[19]),
        .min_G_top(min_G_top[19]),
        .min_B_top(min_B_top[19]),
        .avg_R_top(avg_R_top[19]),
        .avg_G_top(avg_G_top[19]),
        .avg_B_top(avg_B_top[19]),
        .max_R_bottom(max_R_bottom[19]),
        .max_G_bottom(max_G_bottom[19]),
        .max_B_bottom(max_B_bottom[19]),
        .min_R_bottom(min_R_bottom[19]),
        .min_G_bottom(min_G_bottom[19]),
        .min_B_bottom(min_B_bottom[19]),
        .avg_R_bottom(avg_R_bottom[19]),
        .avg_G_bottom(avg_G_bottom[19]),
        .avg_B_bottom(avg_B_bottom[19]),
        .max_R_right(max_R_right[19]),
        .max_G_right(max_G_right[19]),
        .max_B_right(max_B_right[19]),
        .min_R_right(min_R_right[19]),
        .min_G_right(min_G_right[19]),
        .min_B_right(min_B_right[19]),
        .avg_R_right(avg_R_right[19]),
        .avg_G_right(avg_G_right[19]),
        .avg_B_right(avg_B_right[19]),
        .max_R_left(max_R_left[19]),
        .max_G_left(max_G_left[19]),
        .max_B_left(max_B_left[19]),
        .min_R_left(min_R_left[19]),
        .min_G_left(min_G_left[19]),
        .min_B_left(min_B_left[19]),
        .avg_R_left(avg_R_left[19]),
        .avg_G_left(avg_G_left[19]),
        .avg_B_left(avg_B_left[19])
    );

    //Sprite 21
    background_collision sprite21 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[20]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[20]),
        .max_R_top(max_R_top[20]),
        .max_G_top(max_G_top[20]),
        .max_B_top(max_B_top[20]),
        .min_R_top(min_R_top[20]),
        .min_G_top(min_G_top[20]),
        .min_B_top(min_B_top[20]),
        .avg_R_top(avg_R_top[20]),
        .avg_G_top(avg_G_top[20]),
        .avg_B_top(avg_B_top[20]),
        .max_R_bottom(max_R_bottom[20]),
        .max_G_bottom(max_G_bottom[20]),
        .max_B_bottom(max_B_bottom[20]),
        .min_R_bottom(min_R_bottom[20]),
        .min_G_bottom(min_G_bottom[20]),
        .min_B_bottom(min_B_bottom[20]),
        .avg_R_bottom(avg_R_bottom[20]),
        .avg_G_bottom(avg_G_bottom[20]),
        .avg_B_bottom(avg_B_bottom[20]),
        .max_R_right(max_R_right[20]),
        .max_G_right(max_G_right[20]),
        .max_B_right(max_B_right[20]),
        .min_R_right(min_R_right[20]),
        .min_G_right(min_G_right[20]),
        .min_B_right(min_B_right[20]),
        .avg_R_right(avg_R_right[20]),
        .avg_G_right(avg_G_right[20]),
        .avg_B_right(avg_B_right[20]),
        .max_R_left(max_R_left[20]),
        .max_G_left(max_G_left[20]),
        .max_B_left(max_B_left[20]),
        .min_R_left(min_R_left[20]),
        .min_G_left(min_G_left[20]),
        .min_B_left(min_B_left[20]),
        .avg_R_left(avg_R_left[20]),
        .avg_G_left(avg_G_left[20]),
        .avg_B_left(avg_B_left[20])
    );

    //Sprite 22
    background_collision sprite22 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[21]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[21]),
        .max_R_top(max_R_top[21]),
        .max_G_top(max_G_top[21]),
        .max_B_top(max_B_top[21]),
        .min_R_top(min_R_top[21]),
        .min_G_top(min_G_top[21]),
        .min_B_top(min_B_top[21]),
        .avg_R_top(avg_R_top[21]),
        .avg_G_top(avg_G_top[21]),
        .avg_B_top(avg_B_top[21]),
        .max_R_bottom(max_R_bottom[21]),
        .max_G_bottom(max_G_bottom[21]),
        .max_B_bottom(max_B_bottom[21]),
        .min_R_bottom(min_R_bottom[21]),
        .min_G_bottom(min_G_bottom[21]),
        .min_B_bottom(min_B_bottom[21]),
        .avg_R_bottom(avg_R_bottom[21]),
        .avg_G_bottom(avg_G_bottom[21]),
        .avg_B_bottom(avg_B_bottom[21]),
        .max_R_right(max_R_right[21]),
        .max_G_right(max_G_right[21]),
        .max_B_right(max_B_right[21]),
        .min_R_right(min_R_right[21]),
        .min_G_right(min_G_right[21]),
        .min_B_right(min_B_right[21]),
        .avg_R_right(avg_R_right[21]),
        .avg_G_right(avg_G_right[21]),
        .avg_B_right(avg_B_right[21]),
        .max_R_left(max_R_left[21]),
        .max_G_left(max_G_left[21]),
        .max_B_left(max_B_left[21]),
        .min_R_left(min_R_left[21]),
        .min_G_left(min_G_left[21]),
        .min_B_left(min_B_left[21]),
        .avg_R_left(avg_R_left[21]),
        .avg_G_left(avg_G_left[21]),
        .avg_B_left(avg_B_left[21])
    );

    //Sprite 23
    background_collision sprite23 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[22]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[22]),
        .max_R_top(max_R_top[22]),
        .max_G_top(max_G_top[22]),
        .max_B_top(max_B_top[22]),
        .min_R_top(min_R_top[22]),
        .min_G_top(min_G_top[22]),
        .min_B_top(min_B_top[22]),
        .avg_R_top(avg_R_top[22]),
        .avg_G_top(avg_G_top[22]),
        .avg_B_top(avg_B_top[22]),
        .max_R_bottom(max_R_bottom[22]),
        .max_G_bottom(max_G_bottom[22]),
        .max_B_bottom(max_B_bottom[22]),
        .min_R_bottom(min_R_bottom[22]),
        .min_G_bottom(min_G_bottom[22]),
        .min_B_bottom(min_B_bottom[22]),
        .avg_R_bottom(avg_R_bottom[22]),
        .avg_G_bottom(avg_G_bottom[22]),
        .avg_B_bottom(avg_B_bottom[22]),
        .max_R_right(max_R_right[22]),
        .max_G_right(max_G_right[22]),
        .max_B_right(max_B_right[22]),
        .min_R_right(min_R_right[22]),
        .min_G_right(min_G_right[22]),
        .min_B_right(min_B_right[22]),
        .avg_R_right(avg_R_right[22]),
        .avg_G_right(avg_G_right[22]),
        .avg_B_right(avg_B_right[22]),
        .max_R_left(max_R_left[22]),
        .max_G_left(max_G_left[22]),
        .max_B_left(max_B_left[22]),
        .min_R_left(min_R_left[22]),
        .min_G_left(min_G_left[22]),
        .min_B_left(min_B_left[22]),
        .avg_R_left(avg_R_left[22]),
        .avg_G_left(avg_G_left[22]),
        .avg_B_left(avg_B_left[22])
    );

    //Sprite 24
    background_collision sprite24 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[23]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[23]),
        .max_R_top(max_R_top[23]),
        .max_G_top(max_G_top[23]),
        .max_B_top(max_B_top[23]),
        .min_R_top(min_R_top[23]),
        .min_G_top(min_G_top[23]),
        .min_B_top(min_B_top[23]),
        .avg_R_top(avg_R_top[23]),
        .avg_G_top(avg_G_top[23]),
        .avg_B_top(avg_B_top[23]),
        .max_R_bottom(max_R_bottom[23]),
        .max_G_bottom(max_G_bottom[23]),
        .max_B_bottom(max_B_bottom[23]),
        .min_R_bottom(min_R_bottom[23]),
        .min_G_bottom(min_G_bottom[23]),
        .min_B_bottom(min_B_bottom[23]),
        .avg_R_bottom(avg_R_bottom[23]),
        .avg_G_bottom(avg_G_bottom[23]),
        .avg_B_bottom(avg_B_bottom[23]),
        .max_R_right(max_R_right[23]),
        .max_G_right(max_G_right[23]),
        .max_B_right(max_B_right[23]),
        .min_R_right(min_R_right[23]),
        .min_G_right(min_G_right[23]),
        .min_B_right(min_B_right[23]),
        .avg_R_right(avg_R_right[23]),
        .avg_G_right(avg_G_right[23]),
        .avg_B_right(avg_B_right[23]),
        .max_R_left(max_R_left[23]),
        .max_G_left(max_G_left[23]),
        .max_B_left(max_B_left[23]),
        .min_R_left(min_R_left[23]),
        .min_G_left(min_G_left[23]),
        .min_B_left(min_B_left[23]),
        .avg_R_left(avg_R_left[23]),
        .avg_G_left(avg_G_left[23]),
        .avg_B_left(avg_B_left[23])
    );

    //Sprite 25
    background_collision sprite25 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[24]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[24]),
        .max_R_top(max_R_top[24]),
        .max_G_top(max_G_top[24]),
        .max_B_top(max_B_top[24]),
        .min_R_top(min_R_top[24]),
        .min_G_top(min_G_top[24]),
        .min_B_top(min_B_top[24]),
        .avg_R_top(avg_R_top[24]),
        .avg_G_top(avg_G_top[24]),
        .avg_B_top(avg_B_top[24]),
        .max_R_bottom(max_R_bottom[24]),
        .max_G_bottom(max_G_bottom[24]),
        .max_B_bottom(max_B_bottom[24]),
        .min_R_bottom(min_R_bottom[24]),
        .min_G_bottom(min_G_bottom[24]),
        .min_B_bottom(min_B_bottom[24]),
        .avg_R_bottom(avg_R_bottom[24]),
        .avg_G_bottom(avg_G_bottom[24]),
        .avg_B_bottom(avg_B_bottom[24]),
        .max_R_right(max_R_right[24]),
        .max_G_right(max_G_right[24]),
        .max_B_right(max_B_right[24]),
        .min_R_right(min_R_right[24]),
        .min_G_right(min_G_right[24]),
        .min_B_right(min_B_right[24]),
        .avg_R_right(avg_R_right[24]),
        .avg_G_right(avg_G_right[24]),
        .avg_B_right(avg_B_right[24]),
        .max_R_left(max_R_left[24]),
        .max_G_left(max_G_left[24]),
        .max_B_left(max_B_left[24]),
        .min_R_left(min_R_left[24]),
        .min_G_left(min_G_left[24]),
        .min_B_left(min_B_left[24]),
        .avg_R_left(avg_R_left[24]),
        .avg_G_left(avg_G_left[24]),
        .avg_B_left(avg_B_left[24])
    );

    //Sprite 26
    background_collision sprite26 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[25]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[25]),
        .max_R_top(max_R_top[25]),
        .max_G_top(max_G_top[25]),
        .max_B_top(max_B_top[25]),
        .min_R_top(min_R_top[25]),
        .min_G_top(min_G_top[25]),
        .min_B_top(min_B_top[25]),
        .avg_R_top(avg_R_top[25]),
        .avg_G_top(avg_G_top[25]),
        .avg_B_top(avg_B_top[25]),
        .max_R_bottom(max_R_bottom[25]),
        .max_G_bottom(max_G_bottom[25]),
        .max_B_bottom(max_B_bottom[25]),
        .min_R_bottom(min_R_bottom[25]),
        .min_G_bottom(min_G_bottom[25]),
        .min_B_bottom(min_B_bottom[25]),
        .avg_R_bottom(avg_R_bottom[25]),
        .avg_G_bottom(avg_G_bottom[25]),
        .avg_B_bottom(avg_B_bottom[25]),
        .max_R_right(max_R_right[25]),
        .max_G_right(max_G_right[25]),
        .max_B_right(max_B_right[25]),
        .min_R_right(min_R_right[25]),
        .min_G_right(min_G_right[25]),
        .min_B_right(min_B_right[25]),
        .avg_R_right(avg_R_right[25]),
        .avg_G_right(avg_G_right[25]),
        .avg_B_right(avg_B_right[25]),
        .max_R_left(max_R_left[25]),
        .max_G_left(max_G_left[25]),
        .max_B_left(max_B_left[25]),
        .min_R_left(min_R_left[25]),
        .min_G_left(min_G_left[25]),
        .min_B_left(min_B_left[25]),
        .avg_R_left(avg_R_left[25]),
        .avg_G_left(avg_G_left[25]),
        .avg_B_left(avg_B_left[25])
    );

    //Sprite 27
    background_collision sprite27 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[26]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[26]),
        .max_R_top(max_R_top[26]),
        .max_G_top(max_G_top[26]),
        .max_B_top(max_B_top[26]),
        .min_R_top(min_R_top[26]),
        .min_G_top(min_G_top[26]),
        .min_B_top(min_B_top[26]),
        .avg_R_top(avg_R_top[26]),
        .avg_G_top(avg_G_top[26]),
        .avg_B_top(avg_B_top[26]),
        .max_R_bottom(max_R_bottom[26]),
        .max_G_bottom(max_G_bottom[26]),
        .max_B_bottom(max_B_bottom[26]),
        .min_R_bottom(min_R_bottom[26]),
        .min_G_bottom(min_G_bottom[26]),
        .min_B_bottom(min_B_bottom[26]),
        .avg_R_bottom(avg_R_bottom[26]),
        .avg_G_bottom(avg_G_bottom[26]),
        .avg_B_bottom(avg_B_bottom[26]),
        .max_R_right(max_R_right[26]),
        .max_G_right(max_G_right[26]),
        .max_B_right(max_B_right[26]),
        .min_R_right(min_R_right[26]),
        .min_G_right(min_G_right[26]),
        .min_B_right(min_B_right[26]),
        .avg_R_right(avg_R_right[26]),
        .avg_G_right(avg_G_right[26]),
        .avg_B_right(avg_B_right[26]),
        .max_R_left(max_R_left[26]),
        .max_G_left(max_G_left[26]),
        .max_B_left(max_B_left[26]),
        .min_R_left(min_R_left[26]),
        .min_G_left(min_G_left[26]),
        .min_B_left(min_B_left[26]),
        .avg_R_left(avg_R_left[26]),
        .avg_G_left(avg_G_left[26]),
        .avg_B_left(avg_B_left[26])
    );

    //Sprite 28
    background_collision sprite28 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[27]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[27]),
        .max_R_top(max_R_top[27]),
        .max_G_top(max_G_top[27]),
        .max_B_top(max_B_top[27]),
        .min_R_top(min_R_top[27]),
        .min_G_top(min_G_top[27]),
        .min_B_top(min_B_top[27]),
        .avg_R_top(avg_R_top[27]),
        .avg_G_top(avg_G_top[27]),
        .avg_B_top(avg_B_top[27]),
        .max_R_bottom(max_R_bottom[27]),
        .max_G_bottom(max_G_bottom[27]),
        .max_B_bottom(max_B_bottom[27]),
        .min_R_bottom(min_R_bottom[27]),
        .min_G_bottom(min_G_bottom[27]),
        .min_B_bottom(min_B_bottom[27]),
        .avg_R_bottom(avg_R_bottom[27]),
        .avg_G_bottom(avg_G_bottom[27]),
        .avg_B_bottom(avg_B_bottom[27]),
        .max_R_right(max_R_right[27]),
        .max_G_right(max_G_right[27]),
        .max_B_right(max_B_right[27]),
        .min_R_right(min_R_right[27]),
        .min_G_right(min_G_right[27]),
        .min_B_right(min_B_right[27]),
        .avg_R_right(avg_R_right[27]),
        .avg_G_right(avg_G_right[27]),
        .avg_B_right(avg_B_right[27]),
        .max_R_left(max_R_left[27]),
        .max_G_left(max_G_left[27]),
        .max_B_left(max_B_left[27]),
        .min_R_left(min_R_left[27]),
        .min_G_left(min_G_left[27]),
        .min_B_left(min_B_left[27]),
        .avg_R_left(avg_R_left[27]),
        .avg_G_left(avg_G_left[27]),
        .avg_B_left(avg_B_left[27])
    );


    //Sprite 29
    background_collision sprite29 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[28]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[28]),
        .max_R_top(max_R_top[28]),
        .max_G_top(max_G_top[28]),
        .max_B_top(max_B_top[28]),
        .min_R_top(min_R_top[28]),
        .min_G_top(min_G_top[28]),
        .min_B_top(min_B_top[28]),
        .avg_R_top(avg_R_top[28]),
        .avg_G_top(avg_G_top[28]),
        .avg_B_top(avg_B_top[28]),
        .max_R_bottom(max_R_bottom[28]),
        .max_G_bottom(max_G_bottom[28]),
        .max_B_bottom(max_B_bottom[28]),
        .min_R_bottom(min_R_bottom[28]),
        .min_G_bottom(min_G_bottom[28]),
        .min_B_bottom(min_B_bottom[28]),
        .avg_R_bottom(avg_R_bottom[28]),
        .avg_G_bottom(avg_G_bottom[28]),
        .avg_B_bottom(avg_B_bottom[28]),
        .max_R_right(max_R_right[28]),
        .max_G_right(max_G_right[28]),
        .max_B_right(max_B_right[28]),
        .min_R_right(min_R_right[28]),
        .min_G_right(min_G_right[28]),
        .min_B_right(min_B_right[28]),
        .avg_R_right(avg_R_right[28]),
        .avg_G_right(avg_G_right[28]),
        .avg_B_right(avg_B_right[28]),
        .max_R_left(max_R_left[28]),
        .max_G_left(max_G_left[28]),
        .max_B_left(max_B_left[28]),
        .min_R_left(min_R_left[28]),
        .min_G_left(min_G_left[28]),
        .min_B_left(min_B_left[28]),
        .avg_R_left(avg_R_left[28]),
        .avg_G_left(avg_G_left[28]),
        .avg_B_left(avg_B_left[28])
    );

    //Sprite 30
    background_collision sprite30 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[29]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[29]),
        .max_R_top(max_R_top[29]),
        .max_G_top(max_G_top[29]),
        .max_B_top(max_B_top[29]),
        .min_R_top(min_R_top[29]),
        .min_G_top(min_G_top[29]),
        .min_B_top(min_B_top[29]),
        .avg_R_top(avg_R_top[29]),
        .avg_G_top(avg_G_top[29]),
        .avg_B_top(avg_B_top[29]),
        .max_R_bottom(max_R_bottom[29]),
        .max_G_bottom(max_G_bottom[29]),
        .max_B_bottom(max_B_bottom[29]),
        .min_R_bottom(min_R_bottom[29]),
        .min_G_bottom(min_G_bottom[29]),
        .min_B_bottom(min_B_bottom[29]),
        .avg_R_bottom(avg_R_bottom[29]),
        .avg_G_bottom(avg_G_bottom[29]),
        .avg_B_bottom(avg_B_bottom[29]),
        .max_R_right(max_R_right[29]),
        .max_G_right(max_G_right[29]),
        .max_B_right(max_B_right[29]),
        .min_R_right(min_R_right[29]),
        .min_G_right(min_G_right[29]),
        .min_B_right(min_B_right[29]),
        .avg_R_right(avg_R_right[29]),
        .avg_G_right(avg_G_right[29]),
        .avg_B_right(avg_B_right[29]),
        .max_R_left(max_R_left[29]),
        .max_G_left(max_G_left[29]),
        .max_B_left(max_B_left[29]),
        .min_R_left(min_R_left[29]),
        .min_G_left(min_G_left[29]),
        .min_B_left(min_B_left[29]),
        .avg_R_left(avg_R_left[29]),
        .avg_G_left(avg_G_left[29]),
        .avg_B_left(avg_B_left[29])
    );

    //Sprite 31
    background_collision sprite31 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[30]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[30]),
        .max_R_top(max_R_top[30]),
        .max_G_top(max_G_top[30]),
        .max_B_top(max_B_top[30]),
        .min_R_top(min_R_top[30]),
        .min_G_top(min_G_top[30]),
        .min_B_top(min_B_top[30]),
        .avg_R_top(avg_R_top[30]),
        .avg_G_top(avg_G_top[30]),
        .avg_B_top(avg_B_top[30]),
        .max_R_bottom(max_R_bottom[30]),
        .max_G_bottom(max_G_bottom[30]),
        .max_B_bottom(max_B_bottom[30]),
        .min_R_bottom(min_R_bottom[30]),
        .min_G_bottom(min_G_bottom[30]),
        .min_B_bottom(min_B_bottom[30]),
        .avg_R_bottom(avg_R_bottom[30]),
        .avg_G_bottom(avg_G_bottom[30]),
        .avg_B_bottom(avg_B_bottom[30]),
        .max_R_right(max_R_right[30]),
        .max_G_right(max_G_right[30]),
        .max_B_right(max_B_right[30]),
        .min_R_right(min_R_right[30]),
        .min_G_right(min_G_right[30]),
        .min_B_right(min_B_right[30]),
        .avg_R_right(avg_R_right[30]),
        .avg_G_right(avg_G_right[30]),
        .avg_B_right(avg_B_right[30]),
        .max_R_left(max_R_left[30]),
        .max_G_left(max_G_left[30]),
        .max_B_left(max_B_left[30]),
        .min_R_left(min_R_left[30]),
        .min_G_left(min_G_left[30]),
        .min_B_left(min_B_left[30]),
        .avg_R_left(avg_R_left[30]),
        .avg_G_left(avg_G_left[30]),
        .avg_B_left(avg_B_left[30])
    );


    //Sprite 32
    background_collision sprite32 (
        .clk(clk),
        .rst(rst),
        .R_bg(R_bg),
        .G_bg(G_bg),
        .B_bg(B_bg),
        .ancora_bg_X(posX_bg),
        .ancora_sp_X(posicoesX_sp[31]),
        .ancora_bg_Y(posY_bg),
        .ancora_sp_Y(posicoesY_sp[31]),
        .max_R_top(max_R_top[31]),
        .max_G_top(max_G_top[31]),
        .max_B_top(max_B_top[31]),
        .min_R_top(min_R_top[31]),
        .min_G_top(min_G_top[31]),
        .min_B_top(min_B_top[31]),
        .avg_R_top(avg_R_top[31]),
        .avg_G_top(avg_G_top[31]),
        .avg_B_top(avg_B_top[31]),
        .max_R_bottom(max_R_bottom[31]),
        .max_G_bottom(max_G_bottom[31]),
        .max_B_bottom(max_B_bottom[31]),
        .min_R_bottom(min_R_bottom[31]),
        .min_G_bottom(min_G_bottom[31]),
        .min_B_bottom(min_B_bottom[31]),
        .avg_R_bottom(avg_R_bottom[31]),
        .avg_G_bottom(avg_G_bottom[31]),
        .avg_B_bottom(avg_B_bottom[31]),
        .max_R_right(max_R_right[31]),
        .max_G_right(max_G_right[31]),
        .max_B_right(max_B_right[31]),
        .min_R_right(min_R_right[31]),
        .min_G_right(min_G_right[31]),
        .min_B_right(min_B_right[31]),
        .avg_R_right(avg_R_right[31]),
        .avg_G_right(avg_G_right[31]),
        .avg_B_right(avg_B_right[31]),
        .max_R_left(max_R_left[31]),
        .max_G_left(max_G_left[31]),
        .max_B_left(max_B_left[31]),
        .min_R_left(min_R_left[31]),
        .min_G_left(min_G_left[31]),
        .min_B_left(min_B_left[31]),
        .avg_R_left(avg_R_left[31]),
        .avg_G_left(avg_G_left[31]),
        .avg_B_left(avg_B_left[31])
    );


endmodule