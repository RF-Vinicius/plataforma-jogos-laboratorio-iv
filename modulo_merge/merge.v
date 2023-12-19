module merge (stopMerge, R_bg, G_bg, B_bg, R_sp, G_sp, B_sp, R_outRegA, G_outRegA, B_outRegA, R_outRegB, G_outRegB, B_outRegB, posX_bg, posY_bg, posX_sp, posY_sp, reset, clk, readVgaSelector,max_R_top, max_G_top, max_B_top, min_R_top, min_G_top, min_B_top, avg_R_top, avg_G_top, avg_B_top,
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
    output stopMerge;                

    localparam R_trans = 8'h17,
               G_trans = 8'h17,
               B_trans = 8'h17;


    // Registradores para o merge
	reg [3:0] contadorA = 4'b0;
    reg [3:0] contadorA_next = 4'b0;
	reg [6:0] base_indexA = 7'b0;
    reg [3:0] contadorB = 4'b0;
    reg [3:0] contadorB_next = 4'b0;
	reg [6:0] base_indexB = 7'b0;
    reg full_A = 1'b0;
    reg full_B = 1'b0;

    //Registradores para lógica registrar as posições de ancora dos sprites
    reg [9:0] posicoesX_sp[31:0];
    reg [9:0] posicoesY_sp[31:0]; 
    reg [31:0] contadorPosicao_sp = 32'b0;
    reg [31:0] contadorPosicao_sp_next = 32'b0;
    reg iniciarMerge = 1'b0;

    wire [7:0] max_R_top_wire;
    wire [7:0] max_G_top_wire;
    wire [7:0] max_B_top_wire;
    wire [7:0] min_R_top_wire;
    wire [7:0] min_G_top_wire;
    wire [7:0] min_B_top_wire;
    wire [7:0] avg_R_top_wire;
    wire [7:0] avg_G_top_wire;
    wire [7:0] avg_B_top_wire;

    wire [7:0] max_R_bottom_wire;
    wire [7:0] max_G_bottom_wire;
    wire [7:0] max_B_bottom_wire;
    wire [7:0] min_R_bottom_wire;
    wire [7:0] min_G_bottom_wire;
    wire [7:0] min_B_bottom_wire;
    wire [7:0] avg_R_bottom_wire;
    wire [7:0] avg_G_bottom_wire;
    wire [7:0] avg_B_bottom_wire;

    wire [7:0] max_R_right_wire;
    wire [7:0] max_G_right_wire;
    wire [7:0] max_B_right_wire;
    wire [7:0] min_R_right_wire;
    wire [7:0] min_G_right_wire;
    wire [7:0] min_B_right_wire;
    wire [7:0] avg_R_right_wire;
    wire [7:0] avg_G_right_wire;
    wire [7:0] avg_B_right_wire;

    wire [7:0] max_R_left_wire;
    wire [7:0] max_G_left_wire;
    wire [7:0] max_B_left_wire;
    wire [7:0] min_R_left_wire;
    wire [7:0] min_G_left_wire;
    wire [7:0] min_B_left_wire;
    wire [7:0] avg_R_left_wire;
    wire [7:0] avg_G_left_wire;
    wire [7:0] avg_B_left_wire;
    
    
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
            
            contadorPosicao_sp <= contadorPosicao_sp_next;

            if (contadorPosicao_sp <= 31) begin
                posicoesX_sp[contadorPosicao_sp] <= posX_sp;
                posicoesY_sp[contadorPosicao_sp] <= posY_sp;
            end else begin
                iniciarMerge <= 1'b1; //Conforme tenha todas as posições dos sprites, inicia o processo do merge
            end      
        end
    end

    always @* begin
        if (contadorPosicao_sp <= 31)
            contadorPosicao_sp_next = contadorPosicao_sp + 1;
        else 
            contadorPosicao_sp_next = contadorPosicao_sp;
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
        end
        else
        begin
            if (iniciarMerge) begin
                base_indexA = contadorA * 8;
                base_indexB = contadorB * 8;
                contadorA <= contadorA_next;
                contadorB <= contadorB_next;

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

                    if (contadorA == 15)
                        full_A <= 1;

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

                    if (contadorA == 15)
                        full_B <= 1;
                    
                end
            end
        end
    end


    always @* begin
        if ((contadorA < 15) && readVgaSelector == 1'b1) // Reinicia o contador apÃ³s o Ãºltimo conjunto de 8 bits (16 * 8 = 128 bits)
            contadorA_next = contadorA + 1;
        else begin
            contadorA_next = 4'b0;  
        end
    end

    always @* begin
        if ((contadorB < 15) && readVgaSelector == 1'b0) // Reinicia o contador apÃ³s o Ãºltimo conjunto de 8 bits (16 * 8 = 128 bits)
            contadorB_next = contadorB + 1;
        else begin
            contadorB_next = 4'b0;  
        end
    end

always @(posedge clk) begin
    // Atribuições para os registradores de saída referentes a top
    max_R_top <= max_R_top_wire;
    max_G_top <= max_G_top_wire;
    max_B_top <= max_B_top_wire;
    min_R_top <= min_R_top_wire;
    min_G_top <= min_G_top_wire;
    min_B_top <= min_B_top_wire;
    avg_R_top <= avg_R_top_wire;
    avg_G_top <= avg_G_top_wire;
    avg_B_top <= avg_B_top_wire;

    // Atribuições para os registradores de saída referentes a bottom
    max_R_bottom <= max_R_bottom_wire;
    max_G_bottom <= max_G_bottom_wire;
    max_B_bottom <= max_B_bottom_wire;
    min_R_bottom <= min_R_bottom_wire;
    min_G_bottom <= min_G_bottom_wire;
    min_B_bottom <= min_B_bottom_wire;
    avg_R_bottom <= avg_R_bottom_wire;
    avg_G_bottom <= avg_G_bottom_wire;
    avg_B_bottom <= avg_B_bottom_wire;

    // Atribuições para os registradores de saída referentes a right
    max_R_right <= max_R_right_wire;
    max_G_right <= max_G_right_wire;
    max_B_right <= max_B_right_wire;
    min_R_right <= min_R_right_wire;
    min_G_right <= min_G_right_wire;
    min_B_right <= min_B_right_wire;
    avg_R_right <= avg_R_right_wire;
    avg_G_right <= avg_G_right_wire;
    avg_B_right <= avg_B_right_wire;

    // Atribuições para os registradores de saída referentes a left
    max_R_left <= max_R_left_wire;
    max_G_left <= max_G_left_wire;
    max_B_left <= max_B_left_wire;
    min_R_left <= min_R_left_wire;
    min_G_left <= min_G_left_wire;
    min_B_left <= min_B_left_wire;
    avg_R_left <= avg_R_left_wire;
    avg_G_left <= avg_G_left_wire;
    avg_B_left <= avg_B_left_wire;
end


//Calcula a RGB máximo, médio e mínimo de cada sprite que está colidindo com o background
background_collision sprite01 (
    .clk(clk),
    .rst(reset),
    .R_bg(R_bg),
    .G_bg(G_bg),
    .B_bg(B_bg),
    .ancora_bg_X(posX_bg),
    .ancora_bg_Y(posY_bg),
    .ancora_sp_Y(posicoesY_sp[0]),
    .ancora_sp_X(posicoesX_sp[0]),
    .max_R_top(max_R_top_wire),
    .max_G_top(max_G_top_wire),
    .max_B_top(max_B_top_wire),
    .min_R_top(min_R_top_wire),
    .min_G_top(min_G_top_wire),
    .min_B_top(min_B_top_wire),
    .avg_R_top(avg_R_top_wire),
    .avg_G_top(avg_G_top_wire),
    .avg_B_top(avg_B_top_wire),
    .max_R_bottom(max_R_bottom_wire),
    .max_G_bottom(max_G_bottom_wire),
    .max_B_bottom(max_B_bottom_wire),
    .min_R_bottom(min_R_bottom_wire),
    .min_G_bottom(min_G_bottom_wire),
    .min_B_bottom(min_B_bottom_wire),
    .avg_R_bottom(avg_R_bottom_wire),
    .avg_G_bottom(avg_G_bottom_wire),
    .avg_B_bottom(avg_B_bottom_wire),
    .max_R_right(max_R_right_wire),
    .max_G_right(max_G_right_wire),
    .max_B_right(max_B_right_wire),
    .min_R_right(min_R_right_wire),
    .min_G_right(min_G_right_wire),
    .min_B_right(min_B_right_wire),
    .avg_R_right(avg_R_right_wire),
    .avg_G_right(avg_G_right_wire),
    .avg_B_right(avg_B_right_wire),
    .max_R_left(max_R_left_wire),
    .max_G_left(max_G_left_wire),
    .max_B_left(max_B_left_wire),
    .min_R_left(min_R_left_wire),
    .min_G_left(min_G_left_wire),
    .min_B_left(min_B_left_wire),
    .avg_R_left(avg_R_left_wire),
    .avg_G_left(avg_G_left_wire),
    .avg_B_left(avg_B_left_wire)
);

endmodule