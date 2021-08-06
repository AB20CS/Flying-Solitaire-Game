######################################################################
# FLYING SOLITAIRE
#
# Bitmap Display Configuration:
# -Unit width in pixels: 4 
# -Unit height in pixels: 4 
# -Display width in pixels: 256 
# -Display height in pixels: 256 
# -Base Address for Display: 0x10008000 ($gp)
#
#####################################################################

.data
displayAddress: 	.word 0x10008000
Card:			.word 0xffffff:56 	# array of white card
ClearCard:		.word 0x228b22:56	# array of background colur in size of card
HorseshoeCard:		.word 0x6d36c6:56
KeyCard:		.word 0xca7e17:56
HatBacking:		.word 0x4b3617: 56	# rectangle with colour of har

red:			.word 0xff0000
black:			.word 0x0
white:			.word 0xffffff
horseshoe:		.word 0xf1dfdf
key_col:		.word 0xca7e17
green:			.word 0x24e015
yellow:			.word 0xf9f921
orange:			.word 0xf5b61a
purple:			.word 0x6d36c6
sky_blue:		.word 0x24dbfb
hat_col:		.word 0x4b3617
background_col: 	.word 0x228b22 
bottom_bar_col:		.word 0x959f95
shot_col:		.word 0xa5d7f9

.eqv WAIT_TIME	40
.eqv TOTAL_SIZE	4096
.eqv ROW_SIZE	256
.eqv SCORE_INCREMENT_INTERVAL	5
.eqv ONES_DIGIT	15088
.eqv TENS_DIGIT 15072
.eqv HUNDREDS_DIGIT 15056
.eqv THOUSANDS_DIGIT 15040

.text
.globl main
####################################################
# Registers Used:
# $s0: master loop counter
# $t0: base address
# $k0: hat
# $s1: spades
# $s2: clubs
# $s3: hearts
# $s4: diamonds
# $s5: golden key
# $s6: horseshoe
# $s7: total damage
# $k1: total points
# $a2: amount of grazing
# $a3: position of shot
############################################################		
main: 	
	lw $t0, displayAddress 	# $t0 stores the base address for display
	jal colour_background
	lw $t0, displayAddress 	# $t0 stores the base address for display
	jal drawBottomBar
	lw $t0, displayAddress 	# $t0 stores the base address for display
	addi $s0, $0, 1 	# store 1 in master loop counter
	
	add $k1, $0, $0		# initialize total points counter to 0
	addi $s7, $0, 50		# initialize total damage counter to 50
	
	jal init_hat	# initialize hat (avatar)
	jal init_obs_spade	# initialize spades card obstacle
	
	addi $a3, $zero, -1 # store -1 as default inactive position of shot
	addi $s5, $zero, -1 # store -1 as default inactive position of golden key
	addi $s6, $zero, -1 # store -1 as default inactive position of horseshoe
			
MAIN_LOOP: 	
		check_keypress:
			li $t9, 0xffff0000
			lw $t8, 0($t9)
			bne $t8, 1, update 	# if no key press, continue with update
			jal keypress
		
		update: 
			bge $s0, 25, main_update 	# if all obstacles have been initialized, continue with regular update

			beq $s0, 8, init_first_club
			ble $s0, 7, before_club
		
			beq $s0, 16, init_first_heart
			ble $s0, 15, before_heart
			
			beq $s0, 24, init_first_diamond
			ble $s0, 23, before_diamond
			
			j main_sleep
			
			main_update:
				jal drawHat
				jal update_obs_spade
				jal update_obs_club
				jal update_obs_heart
				jal update_obs_diamond
				jal update_shot
				jal update_horseshoe
				jal update_key
				
				addi $t7, $zero, 150
				div $s0, $t7 # number of loops / 70
				mfhi $t7 # $t7 = remainder
				beq $t7, $zero, init_first_horseshoe
				ReturnFromHorseshoeInit:
				
				addi $t7, $zero, 400
				div $s0, $t7 # number of loops / 200
				mfhi $t7 # $t7 = remainder
				beq $t7, $zero, init_first_key
				
				ReturnFromKeyInit:
				
				j main_sleep	
				
				init_first_horseshoe:
					jal init_horseshoe
					j ReturnFromHorseshoeInit
				
				init_first_key:
					jal init_key
					j ReturnFromKeyInit
				
					
			before_club:
				jal drawHat
				jal update_obs_spade
				jal update_shot
				j main_sleep
			
			before_heart:
				jal drawHat
				jal update_obs_spade
				jal update_obs_club
				jal update_shot
				j main_sleep
				
			before_diamond:
				jal drawHat
				jal update_obs_spade
				jal update_obs_club
				jal update_obs_heart
				jal update_shot
				j main_sleep
			
			init_first_club:
				jal drawHat
				jal update_obs_spade
				jal init_obs_club	# initialize clubs card obstacle
				jal update_shot
				j main_sleep
			
			init_first_heart:
				jal drawHat
				jal update_obs_spade
				jal update_obs_club
				jal init_obs_heart	# initialize hearts card obstacle
				jal update_shot
				j main_sleep	
			
			init_first_diamond:
				jal drawHat
				jal update_obs_spade
				jal update_obs_club
				jal update_obs_heart
				jal init_obs_diamond	# initialize diamonds card obstacle
				jal update_shot
				j main_sleep		
		
		main_sleep:
			li $v0, 32
			li $a0, WAIT_TIME   
			syscall 
	
		addi $s0, $s0, 1 # increment master counter
			
		increment_score:
			# Incrementing Score
			addi $t7, $zero, SCORE_INCREMENT_INTERVAL
			div $s0, $t7
			mfhi $t7
		
			bnez $t7, MAIN_LOOP
			addi $k1, $k1, 1 # increment score counter

		print_score:
			jal clear_score
			
			add $t5, $zero, $k1 # store total score in $t5
			
			print_thousands:
				addi $t1, $zero, 1000 # store 1000 in $t1
				div $t5, $t1 # score / 1000
				mflo $t6 # quotient = $t6
				
				addi $sp, $sp, -4
				addi $t7, $t0, THOUSANDS_DIGIT
				sw $t7, 0($sp)
			
				la $ra, print_hundreds
			
				beq $t6, 0, draw_0
				beq $t6, 1, draw_1
				beq $t6, 2, draw_2
				beq $t6, 3, draw_3
				beq $t6, 4, draw_4
				beq $t6, 5, draw_5
				beq $t6, 6, draw_6
				beq $t6, 7, draw_7
				beq $t6, 8, draw_8
				beq $t6, 9, draw_9
			
			print_hundreds:
				mfhi $t5 # move remainder from score / 1000 to $t5
				addi $t1, $zero, 100 # store 100 in $t1
				div $t5, $t1 # hundreds_remainder / 100
				mflo $t6 # quotient = $t6
				
				addi $sp, $sp, -4
				addi $t7, $t0, HUNDREDS_DIGIT
				sw $t7, 0($sp)
				
				la $ra, print_tens
				
				beq $t6, 0, draw_0
				beq $t6, 1, draw_1
				beq $t6, 2, draw_2
				beq $t6, 3, draw_3
				beq $t6, 4, draw_4
				beq $t6, 5, draw_5
				beq $t6, 6, draw_6
				beq $t6, 7, draw_7
				beq $t6, 8, draw_8
				beq $t6, 9, draw_9
			
			print_tens:
				mfhi $t5 # move remainder from score / 100 to $t5
				addi $t1, $zero, 10 # store 10 in $t1
				div $t5, $t1 # tens_remainder 
				mflo $t6 # quotient = $t6
				
				addi $sp, $sp, -4
				addi $t7, $t0, TENS_DIGIT
				sw $t7, 0($sp)
				
				la $ra, print_ones
				
				beq $t6, 0, draw_0
				beq $t6, 1, draw_1
				beq $t6, 2, draw_2
				beq $t6, 3, draw_3
				beq $t6, 4, draw_4
				beq $t6, 5, draw_5
				beq $t6, 6, draw_6
				beq $t6, 7, draw_7
				beq $t6, 8, draw_8
				beq $t6, 9, draw_9
			
			
			print_ones:
				mfhi $t6 # move remainder from score / 10 to $t6
				
				addi $sp, $sp, -4
				addi $t7, $t0, ONES_DIGIT
				sw $t7, 0($sp)
				
				la $ra, MAIN_LOOP
				
				beq $t6, 0, draw_0
				beq $t6, 1, draw_1
				beq $t6, 2, draw_2
				beq $t6, 3, draw_3
				beq $t6, 4, draw_4
				beq $t6, 5, draw_5
				beq $t6, 6, draw_6
				beq $t6, 7, draw_7
				beq $t6, 8, draw_8
				beq $t6, 9, draw_9
			
		j MAIN_LOOP
		
		
############################################################

# Controls: w (0x77): up, a (0x61): left, d (0x64): right, s (0x73): down, p (0x70): reset
keypress:	lw $t7, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
		
		beq $t7, 0x61, move_left # ASCII code of 'a' is 0x61 or 97 in decimal
		beq $t7, 0x77, move_up # ASCII code of 'w' is 0x77
		beq $t7, 0x64, move_right # ASCII code of 'd' is 0x64
		beq $t7, 0x73, move_down # ASCII code of 's' is 0x73
		beq $t7, 0x70, restart # ASCII code of 'p' is 0x70
		beq $t7, 0x20, shoot, # ASCII code for 'space' is 0x20

	move_left: 
		addi $t7, $k0, -4 # store left edge of hat in $t7
		addi $t8, $zero, ROW_SIZE # store row size in $t8
		div $t7, $t8 # divide right address by size of each row (remainder = column of hat)
		mfhi $t7  # store remainder in $t7
		
		beq $t7, 0, keypress_done	# if remainder = 0, do not update position
		j clearHatLeftMove
		AfterLeftClear:
		addi $k0, $k0, -4 # else, move right one unit
		b keypress_done

	move_up:
		lw $t0, displayAddress
		add $t7, $k0, $zero # store left edge of hat in $t7
		sub $t7, $t7, $t0
		ble $t7, 256, keypress_done # if location is on top line
		j clearHatUpMove
		AfterUpClear:
		addi $k0, $k0, -256
		b keypress_done

	move_right:
		addi $t7, $k0, 16 # store right edge of hat in $t7
		addi $t8, $zero, ROW_SIZE # store row size in $t8
		div $t7, $t8 # divide right address by size of each row (remainder = column of hat)
		mfhi $t7  # store remainder in $t7
		
		beq $t7, 0, keypress_done	# if remainder = 0, do not update position
		j clearHatRightMove
		AfterRightClear:
		addi $k0, $k0, 4 # else, move right one unit
		b keypress_done

	move_down:
		lw $t0, displayAddress
		addi $t7, $k0, 768 # store bottom edge of hat in $t7
		sub $t7, $t7, $t0
		bge $t7, 14336, keypress_done # if location is on just above bottom bar
		j clearHatDownMove
		AfterDownClear:
		addi $k0, $k0, 256
		b keypress_done

	restart:
		la $ra, main # restart game (store address of main label in $ra)
		b keypress_done
		
	shoot:
		bne $a3, -1, keypress_done # if a shot is still on screen, do not shoot
		addi $a3, $k0, 268 # store initial address of shot in $a3 (to the right of hat)
		lw $t1, shot_col
		sw $t1, ($a3)
		b keypress_done

	keypress_done: jr $ra

# Clear during Movement
	clearHatLeftMove:
		move $t7, $k0 	# stores address of top left corner of hat
		lw $v0, background_col
		sw $v0, 8($t7)
		sw $v0, 264($t7)
		sw $v0, 520($t7)
		sw $v0, 780($t7)
		j AfterLeftClear
	
	clearHatUpMove:
		move $t7, $k0 	# stores address of top left corner of hat
		lw $v0, background_col
		sw $v0, 764($t7)
		sw $v0, 768($t7)
		sw $v0, 772($t7)
		sw $v0, 776($t7)
		sw $v0, 780($t7)
	
		sw $v0, 512($t7)
		sw $v0, 516($t7)
		sw $v0, 520($t7)
		j AfterUpClear
	
	clearHatRightMove:
		move $t7, $k0 	# stores address of top left corner of hat
		lw $v0, background_col
		sw $v0, 0($t7)
		sw $v0, 256($t7)
		sw $v0, 512($t7)
		sw $v0, 764($t7)
		j AfterRightClear 
	
	clearHatDownMove:
		move $t7, $k0 	# stores address of top left corner of hat
		lw $v0, background_col
		sw $v0, 0($t7)
		sw $v0, 4($t7)
		sw $v0, 8($t7)
		sw $v0, 764($t7)
		sw $v0, 780($t7)
		j AfterDownClear      
	      	      	      	      	      	      
# COLOURING	      	      	      	      
	      	      	      	      	      	      	      	      
colour_background:	lw $t1, background_col 	# $t1 stores background colour 
			addi $t7, $zero, 1 	# initialize unit counter
			
	back_col_loop:		
			bgt $t7, TOTAL_SIZE, end_back_loop
			sw $t1, 0($t0)
			addi $t7, $t7, 1 	# incremeent unit counter
			addi $t0, $t0, 4
			j back_col_loop

	end_back_loop:	jr $ra

drawBottomBar:
	lw $t1, bottom_bar_col	# $t1 stores bar colour 
	addi $t0, $t0, 14592 # store top left corner of bar in $t0
	addi $t7, $zero, 1 # initialize unit counter
			
	bar_col_loop:		
			bgt $t7, 448, hp_bar_init
			sw $t1, 0($t0)
			addi $t0, $t0, 4
			addi $t7, $t7, 1 	# incremeent unit counter
			j bar_col_loop
	
	hp_bar_init:
		lw $t1, green	# $t1 stores green colour 
		lw $t0, displayAddress
		
		# draw green bar
		addi $t0, $t0, 15404 # store top left corner of HP bar in $t0

		sw $t1, 4($t0)
		sw $t1, 8($t0)
		sw $t1, 12($t0)
		sw $t1, 16($t0)
		sw $t1, 20($t0)
		sw $t1, 24($t0)
		sw $t1, 28($t0)
		sw $t1, 32($t0)
		sw $t1, 36($t0)
		sw $t1, 40($t0)
		
		j end_bar_loop
	
	end_bar_loop:	
		lw $t0, displayAddress
		addi $t0, $t0, 14592 # store top left corner of bar in $t0
		lw $t1, black
		
		# Write "HP" on bottom bar
		sw $t1, 264($t0)
		sw $t1, 272($t0)
		sw $t1, 280($t0)
		sw $t1, 284($t0)
		sw $t1, 288($t0)
		
		sw $t1, 520($t0)
		sw $t1, 528($t0)
		sw $t1, 536($t0)
		sw $t1, 544($t0)
		
		sw $t1, 776($t0)
		sw $t1, 780($t0)
		sw $t1, 784($t0)
		sw $t1, 792($t0)
		sw $t1, 796($t0)
		sw $t1, 800($t0)
		
		sw $t1, 1032($t0)
		sw $t1, 1040($t0)
		sw $t1, 1048($t0)
		
		sw $t1, 1288($t0)
		sw $t1, 1296($t0)
		sw $t1, 1304($t0)
		
		jr $ra
	

# Register for Hat: $k0

init_hat:
	lw $t0, displayAddress 	# $t0 stores the base address for display
	
	addi $k0, $zero, 8208 # initialize starting position of hat
	add $k0, $k0, $t0 # add base address to relative unit
	j drawHat

drawHat:
	########## check for collision with card obstacle ###################
	lw $v0, white # $v0 stores white colour
	# if top row pixel is white (card is present), do damage
	lw $t6, 0($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 4($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 8($k0)
	beq $t6, $v0, CardDamage
	
	# if bottom row pixel is white (card is present), do damage
	lw $t6, 764($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 768($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 772($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 776($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 780($k0)
	beq $t6, $v0, CardDamage
	
	# if left side pixel is white (card is present), do damage
	lw $t6, 256($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 512($k0)
	beq $t6, $v0, CardDamage
	
	# if right pixel is white (card is present), do damage
	lw $t6, 264($k0)
	beq $t6, $v0, CardDamage
	
	lw $t6, 520($k0)
	beq $t6, $v0, CardDamage
	
	add $a2, $zero, $zero # set grazing to 0 (no contact with obstacles)
	
	############ check for collision with horseshoe card #############
	lw $v0, purple # $v0 stores purple colour
	# if top row pixel is purple (card is present), add bonus
	lw $t6, 0($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 4($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 8($k0)
	beq $t6, $v0, HorseshoeBonus
	
	# if bottom row pixel is purple (card is present), add bonus
	lw $t6, 764($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 768($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 772($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 776($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 780($k0)
	beq $t6, $v0, HorseshoeBonus
	
	# if left side pixel is purple (card is present), add bonus
	lw $t6, 256($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 512($k0)
	beq $t6, $v0, HorseshoeBonus
	
	# if right pixel is purple (card is present), add bonus
	lw $t6, 264($k0)
	beq $t6, $v0, HorseshoeBonus
	
	lw $t6, 520($k0)
	beq $t6, $v0, HorseshoeBonus
	
	
	############ check for collision with golden key card #############
	lw $v0, key_col # $v0 stores key colour
	# if top row pixel is key colour (card is present), boost health
	lw $t6, 0($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 4($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 8($k0)
	beq $t6, $v0, KeyBoost
	
	# if bottom row pixel is key colour (card is present), boost health
	lw $t6, 764($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 768($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 772($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 776($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 780($k0)
	beq $t6, $v0, KeyBoost
	
	# if left side pixel is key colour (card is present), boost health
	lw $t6, 256($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 512($k0)
	beq $t6, $v0, KeyBoost
	
	# if right pixel is key colour (card is present), boost health
	lw $t6, 264($k0)
	beq $t6, $v0, KeyBoost
	
	lw $t6, 520($k0)
	beq $t6, $v0, KeyBoost
	
	####### draw hat in updated position (normal colours) ##########
	move $t7, $k0 	# stores address of top left corner of hat
	# Drawing Hat shape
	lw $v0, hat_col # $v0 stores hat colour
	sw $v0, 0($t7)
	sw $v0, 4($t7)
	sw $v0, 8($t7)
	
	sw $v0, 256($t7)
	sw $v0, 260($t7)
	sw $v0, 264($t7)
	
	sw $v0, 764($t7)
	sw $v0, 768($t7)
	sw $v0, 772($t7)
	sw $v0, 776($t7)
	sw $v0, 780($t7)
	
	lw $v0, red	# $v0 stores red colour
	sw $v0, 512($t7)
	sw $v0, 516($t7)
	sw $v0, 520($t7)
	
	jr $ra
	
	CardDamage: 
		# draw yellow/orange hat
		move $t7, $k0 	# stores address of top left corner of hat
		addi $a2, $a2, 1 # incrememnt grazing
		
		bge $a2, 6, grazing_lvl2
		bge $a2, 1, grazing_lvl1 
		
		grazing_lvl1:
			lw $v0, orange # $v0 stores orange
			sw $v0, 0($t7)
			sw $v0, 4($t7)
			sw $v0, 8($t7)
			sw $v0, 256($t7)
			sw $v0, 260($t7)
			sw $v0, 264($t7)
			
			sw $v0, 764($t7)
			sw $v0, 768($t7)
			sw $v0, 772($t7)
			sw $v0, 776($t7)
			sw $v0, 780($t7)
		
			lw $v0, yellow	# $v0 stores yellow
			sw $v0, 512($t7)
			sw $v0, 516($t7)
			sw $v0, 520($t7)
			
			j RetFromCardDamageColour
			
		grazing_lvl2:
			lw $v0, sky_blue # $v0 stores sky blue
			sw $v0, 0($t7)
			sw $v0, 4($t7)
			sw $v0, 8($t7)
			sw $v0, 256($t7)
			sw $v0, 260($t7)
			sw $v0, 264($t7)
			
			sw $v0, 764($t7)
			sw $v0, 768($t7)
			sw $v0, 772($t7)
			sw $v0, 776($t7)
			sw $v0, 780($t7)
		
			lw $v0, yellow	# $v0 stores yellow
			sw $v0, 512($t7)
			sw $v0, 516($t7)
			sw $v0, 520($t7)
			
			j RetFromCardDamageColour
		
		RetFromCardDamageColour:
		addi $s7, $s7, -1 # decrement total damage counter
		blez $s7, GAME_OVER
		
		addi $t7, $zero, 5 # store 5 in $t7 (temporarily)
		div $s7, $t7 # divide total damage ctr by 5
		mfhi $t7 # store remainder in $t7
	 	beqz $t7, UpdateHPBar # if remainder == 0, update HP bar
	 	
		RetFromUpdateHP:
		jr $ra
		
		UpdateHPBar:
			mflo $t7 # store quotient in $t7
			lw $t0, displayAddress
			addi $t0, $t0, 15404 # store top left corner of HP bar in $t0
			
			beq $t7, 9, NineLeft
			beq $t7, 8, EightLeft
			beq $t7, 7, SevenLeft
			beq $t7, 6, SixLeft
			beq $t7, 5, FiveLeft
			beq $t7, 4, FourLeft
			beq $t7, 3, ThreeLeft
			beq $t7, 2, TwoLeft
			beq $t7, 1, OneLeft
			j RetFromUpdateHP
			
			
			sw $t1, 4($t0)
			
			NineLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)	
							
				lw $t1, red				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			EightLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
							
				lw $t1, red	
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			SevenLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
											
				lw $t1, red	
				sw $t1, 32($t0)
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			SixLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
											
				lw $t1, red	
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			FiveLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
											
				lw $t1, red	
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)				
				sw $t1, 40($t0)

				j RetFromUpdateHP
				
			FourLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
											
				lw $t1, red
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)	
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			ThreeLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
											
				lw $t1, red	
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			TwoLeft:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
											
				lw $t1, red	
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
				
			OneLeft:
				lw $t1, green
				sw $t1, 4($t0)
							
				lw $t1, red	
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)				
				sw $t1, 40($t0)
				
				j RetFromUpdateHP
	
	HorseshoeBonus:
		
		addi $k1, $k1, 10 # add 10 bonus points to total score
		
		# draw flashy hat
		move $t7, $k0 	# stores address of top left corner of hat
		
		lw $v0, horseshoe # $v0 stores very light red colour
		sw $v0, 0($t7)
		sw $v0, 4($t7)
		sw $v0, 8($t7)
		sw $v0, 256($t7)
		sw $v0, 260($t7)
		sw $v0, 264($t7)
	
		sw $v0, 764($t7)
		sw $v0, 768($t7)
		sw $v0, 772($t7)
		sw $v0, 776($t7)
		sw $v0, 780($t7)
	
		lw $v0, black	# $v0 stores black
		sw $v0, 512($t7)
		sw $v0, 516($t7)
		sw $v0, 520($t7)
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		jal clearFullHorseshoe
		
		lw $ra, 0 ($sp)
		addi $sp, $sp, 4
		
		jr $ra
		
	KeyBoost: 
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		
		jal clearFullKey
		
		lw $ra, 0 ($sp)
		addi $sp, $sp, 4
		
		# draw flashy hat
		move $t7, $k0 	# stores address of top left corner of hat
		
		lw $v0, black # $v0 stores orange
		sw $v0, 0($t7)
		sw $v0, 4($t7)
		sw $v0, 8($t7)
		sw $v0, 256($t7)
		sw $v0, 260($t7)
		sw $v0, 264($t7)
	
		sw $v0, 764($t7)
		sw $v0, 768($t7)
		sw $v0, 772($t7)
		sw $v0, 776($t7)
		sw $v0, 780($t7)
	
		lw $v0, horseshoe	# $v0 stores yellow
		sw $v0, 512($t7)
		sw $v0, 516($t7)
		sw $v0, 520($t7)
		
		bge $s7, 45, ReturnFromUpdateHPKey
		addi $s7, $s7, 5 # increment total damage counter
		addi $t7, $zero, 5 # store 5 in $t7 (temporarily)
		div $s7, $t7 # divide total damage ctr by 5
		j UpdateHPBarKey
	 	
		ReturnFromUpdateHPKey:
		jr $ra
		
		UpdateHPBarKey:
			mflo $t7 # store quotient in $t7
			lw $t0, displayAddress
			addi $t0, $t0, 15404 # store top left corner of HP bar in $t0
			beq $t7, 9, NineLeftKey
			beq $t7, 8, EightLeftKey
			beq $t7, 7, SevenLeftKey
			beq $t7, 6, SixLeftKey
			beq $t7, 5, FiveLeftKey
			beq $t7, 4, FourLeftKey
			beq $t7, 3, ThreeLeftKey
			beq $t7, 2, TwoLeftKey
			beq $t7, 1, OneLeftKey
			j ReturnFromUpdateHPKey
			
			
			sw $t1, 4($t0)
			
			NineLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				
			EightLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)	
							
				lw $t1, red				
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				
			SevenLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
								
				lw $t1, red
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
			
			SixLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
							
				lw $t1, red
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				
			FiveLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
						
				lw $t1, red
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
			
			FourLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
								
				lw $t1, red
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				
			ThreeLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
								
				lw $t1, red
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				
			TwoLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
								
				lw $t1, red
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				
			OneLeftKey:
				lw $t1, green
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				
				lw $t1, red
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 24($t0)
				sw $t1, 28($t0)
				sw $t1, 32($t0)
				sw $t1, 36($t0)
				sw $t1, 40($t0)
				
				j ReturnFromUpdateHPKey
				

# Registers for Obstacles: $s1 (spade) , $s2 (clubs), $s3 (diamond), $s4 (heart)

init_obs_spade: 
		random_spade_location:
		# Random number generator
		li $v0, 42
		li $a0, 1
		li $a1, 50
		syscall
		
		
		add $s1, $a0, $zero
		addi $v0, $zero, ROW_SIZE
		mult $s1, $v0
		mflo $s1
		lw $t0, displayAddress 	# $t0 stores the base address for display
		add $s1, $s1, $t0
		addi $s1, $s1, -28
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		jal drawSpade 		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra

update_obs_spade:	
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		lw $t0, displayAddress 	# $t0 stores the base address for display
		sub $v0, $s1, $t0 	# subtract base address from top left corner of obs location
		li $v1, ROW_SIZE 
		div $v0, $v1 	# divide relative location of obs by row size
		mfhi $v0 	# store remainder of division in $v0
		beq $v0, $zero, clearFullSpade 	# if card has reached left edge, erase it
		jal clearPartSpade	# else, clear parts of it
		addi $s1, $s1, -4

		jal drawSpade 		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra
	
drawSpade:	
		addi $t5, $0, 1 	# unit counter
		addi $t6, $0, 1 	# width unit counter
		move $t7, $s1 	# stores address of top left corner
		la $t9, Card 	# holds array of card
		
	 
	DrawSpadeLoop:	
		bgt $t5, 56, endOfSpadeCard # if count > 56, exit
		bgt $t6, 7, endOfSpadeWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawSpadeLoop

	endOfSpadeWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawSpadeLoop
		
	endOfSpadeCard:	
		move $t7, $s1 # stores address of top left corner
		lw $v0, black
		sw $v0, 268($t7) # row 1
		
		sw $v0, 520($t7) 
		sw $v0, 524($t7) # row 2
		sw $v0, 528($t7) 
		
		sw $v0, 772($t7) 
		sw $v0, 776($t7) 
		sw $v0, 780($t7) # row 3
		sw $v0, 784($t7) 
		sw $v0, 788($t7) 
		
		sw $v0, 1028($t7)
		sw $v0, 1036($t7) # row 4
		sw $v0, 1044($t7)
		
		sw $v0, 1292($t7) # row 5
		
		sw $v0, 1544($t7)
		sw $v0, 1548($t7) # row 6
		sw $v0, 1552($t7)
		
		jr $ra	

clearPartSpade:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s1 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearPartSpadeLoop:	
		bgt $t5, 56, endOfClearPartSpade # if count > 56, exit
		bgt $t6, 7, endOfClearPartSpadeWidth # if width_count > 7
		
		beq $t6, 1, firstColSpade
		
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearPartSpadeLoop
		
		firstColSpade: # do not update left edge (does not change)
			addi $t7, $t7, 4 # increment display address
			addi $t9, $t9, 4 # incrememnt location in Card array
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
			
			j DrawClearPartSpadeLoop

	endOfClearPartSpadeWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearPartSpadeLoop
		
	endOfClearPartSpade:	
		jr $ra

clearFullSpade:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s1 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearSpadeLoop:	
		bgt $t5, 56, endOfClearSpade # if count > 56, exit
		bgt $t6, 7, endOfClearSpadeWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearSpadeLoop

	endOfClearSpadeWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearSpadeLoop
		
	endOfClearSpade:	
		
		j init_obs_spade
							
##########################

init_obs_club: 	
		random_club_location:
		# Random number generator
		li $v0, 42
		li $a0, 1
		li $a1, 50
		syscall
		
		add $s2, $a0, $zero
		addi $v0, $zero, ROW_SIZE
		mult $s2, $v0
		mflo $s2
		lw $t0, displayAddress 	# $t0 stores the base address for display
		add $s2, $s2, $t0
		addi $s2, $s2, -28
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		jal drawClub 		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra

update_obs_club:	
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		lw $t0, displayAddress 	# $t0 stores the base address for display
		sub $v0, $s2, $t0 	# subtract base address from top left corner of obs location
		li $v1, ROW_SIZE 
		div $v0, $v1 	# divide relative location of obs by row size
		mfhi $v0 	# store remainder of division in $v0
		beq $v0, $zero, clearFullClub	# if card has reached left edge, erase it
		jal clearPartClub	# else, clear parts of it
		addi $s2, $s2, -4
			
		jal drawClub 		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra
	
drawClub:	
		addi $t5, $0, 1 	# unit counter
		addi $t6, $0, 1 	# width unit counter
		move $t7, $s2 	# stores address of top left corner
		la $t9, Card 	# holds array of card
		
	 
	DrawClubLoop:	
		bgt $t5, 56, endOfClubCard # if count > 56, exit
		bgt $t6, 7, endOfClubWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClubLoop

	endOfClubWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClubLoop
		
	endOfClubCard:	
		move $t7, $s2 # stores address of top left corner
		lw $v0, black
		
		sw $v0, 260($t7) # row 1
		sw $v0, 264($t7)
		sw $v0, 268($t7)
		sw $v0, 272($t7)
		sw $v0, 276($t7)
		
		sw $v0, 516($t7) # row 2
		sw $v0, 524($t7)
		sw $v0, 532($t7)
		
		sw $v0, 776($t7) # row 3
		sw $v0, 780($t7)
		sw $v0, 784($t7)
		
		sw $v0, 1028($t7) # row 4
		sw $v0, 1036($t7)
		sw $v0, 1044($t7)
		
		sw $v0, 1284($t7) # row 5
		sw $v0, 1288($t7)
		sw $v0, 1292($t7)
		sw $v0, 1296($t7)
		sw $v0, 1300($t7)
		
		sw $v0, 1548($t7) # row 6
		
		jr $ra	

clearPartClub:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s2 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearPartClubLoop:	
		bgt $t5, 56, endOfClearPartClub # if count > 56, exit
		bgt $t6, 7, endOfClearPartClubWidth # if width_count > 7
		
		beq $t6, 1, firstColClub
				
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearPartClubLoop
		
		firstColClub: # do not update left edge (does not change)
			addi $t7, $t7, 4 # increment display address
			addi $t9, $t9, 4 # incrememnt location in Card array
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
			
			j DrawClearPartClubLoop

	endOfClearPartClubWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearPartClubLoop
		
	endOfClearPartClub:	
		jr $ra

clearFullClub:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s2 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 	
	DrawClearClubLoop:	
		bgt $t5, 56, endOfClearClub # if count > 56, exit
		bgt $t6, 7, endOfClearClubWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearClubLoop

	endOfClearClubWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearClubLoop
		
	endOfClearClub:	
		j init_obs_club																								

##########################

init_obs_heart: 
		random_heart_location:	
		# Random number generator
		li $v0, 42
		li $a0, 1
		li $a1, 50
		syscall
		
		add $s3, $a0, $zero
		addi $v0, $zero, ROW_SIZE
		mult $s3, $v0
		mflo $s3
		lw $t0, displayAddress 	# $t0 stores the base address for display
		add $s3, $s3, $t0
		addi $s3, $s3, -28
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		jal drawHeart		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra

update_obs_heart:	
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		lw $t0, displayAddress 	# $t0 stores the base address for display
		sub $v0, $s3, $t0 	# subtract base address from top left corner of obs location
		li $v1, ROW_SIZE 
		div $v0, $v1 	# divide relative location of obs by row size
		mfhi $v0 	# store remainder of division in $v0
		beq $v0, $zero, clearFullHeart	# if card has reached left edge, erase it
		jal clearPartHeart	# else, clear parts of it
		addi $s3, $s3, -4
			
		jal drawHeart 		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra
	
drawHeart:	
		addi $t5, $0, 1 	# unit counter
		addi $t6, $0, 1 	# width unit counter
		move $t7, $s3 	# stores address of top left corner
		la $t9, Card 	# holds array of card
		
	 
	DrawHeartLoop:	
		bgt $t5, 56, endOfHeartCard # if count > 56, exit
		bgt $t6, 7, endOfHeartWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawHeartLoop

	endOfHeartWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawHeartLoop
		
	endOfHeartCard:	
		move $t7, $s3 # stores address of top left corner
		lw $v0, red
		
		sw $v0, 264($t7) # row 1
		sw $v0, 272($t7)
		
		sw $v0, 516($t7) # row 2
		sw $v0, 520($t7)
		sw $v0, 528($t7)
		sw $v0, 532($t7)
		
		sw $v0, 772($t7) # row 3
		sw $v0, 776($t7)
		sw $v0, 780($t7)
		sw $v0, 784($t7)
		sw $v0, 788($t7)
		
		sw $v0, 1032($t7) # row 4
		sw $v0, 1036($t7)
		sw $v0, 1040($t7)
		
		sw $v0, 1292($t7) # row 5
		
		jr $ra	

clearPartHeart:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s3 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearPartHeartLoop:	
		bgt $t5, 56, endOfClearPartHeart # if count > 56, exit
		bgt $t6, 7, endOfClearPartHeartWidth # if width_count > 7
		
		beq $t6, 1, firstColHeart
				
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearPartHeartLoop
		
		firstColHeart: # do not update left edge (does not change)
			addi $t7, $t7, 4 # increment display address
			addi $t9, $t9, 4 # incrememnt location in Card array
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
			
			j DrawClearPartHeartLoop

	endOfClearPartHeartWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearPartHeartLoop
		
	endOfClearPartHeart:	
		jr $ra

clearFullHeart:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s3 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 	
	DrawClearHeartLoop:	
		bgt $t5, 56, endOfClearHeart # if count > 56, exit
		bgt $t6, 7, endOfClearHeartWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearHeartLoop

	endOfClearHeartWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearHeartLoop
		
	endOfClearHeart:	
		j init_obs_heart																																					      		      		      		     	

##########################

init_obs_diamond: 
		random_diamond_location:	
		# Random number generator
		li $v0, 42
		li $a0, 1
		li $a1, 50
		syscall
		
		add $s4, $a0, $zero
		addi $v0, $zero, ROW_SIZE
		mult $s4, $v0
		mflo $s4
		lw $t0, displayAddress 	# $t0 stores the base address for display
		add $s4, $s4, $t0
		addi $s4, $s4, -28
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		jal drawDiamond		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra

update_obs_diamond:	
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		lw $t0, displayAddress 	# $t0 stores the base address for display
		sub $v0, $s4, $t0 	# subtract base address from top left corner of obs location
		li $v1, ROW_SIZE 
		div $v0, $v1 	# divide relative location of obs by row size
		mfhi $v0 	# store remainder of division in $v0
		beq $v0, $zero, clearFullDiamond	# if card has reached left edge, erase it
		jal clearPartDiamond	# else, clear parts of it
		addi $s4, $s4, -4
			
		jal drawDiamond 		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra
	
drawDiamond:	
		addi $t5, $0, 1 	# unit counter
		addi $t6, $0, 1 	# width unit counter
		move $t7, $s4 	# stores address of top left corner
		la $t9, Card 	# holds array of card
		
	 
	DrawDiamondLoop:	
		bgt $t5, 56, endOfDiamondCard # if count > 56, exit
		bgt $t6, 7, endOfDiamondWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawDiamondLoop

	endOfDiamondWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawDiamondLoop
		
	endOfDiamondCard:	
		move $t7, $s4 # stores address of top left corner
		lw $v0, red
		
		sw $v0, 268($t7) # row 1
		 
		sw $v0, 520($t7) # row 2
		sw $v0, 524($t7)
		sw $v0, 528($t7)
		
		sw $v0, 772($t7) # row 3
		sw $v0, 776($t7)
		sw $v0, 780($t7)
		sw $v0, 784($t7)
		sw $v0, 788($t7)
		
		sw $v0, 1032($t7) # row 4
		sw $v0, 1036($t7)
		sw $v0, 1040($t7)
		
		sw $v0, 1292($t7) # row 5
		
		jr $ra	

clearPartDiamond:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s4 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearPartDiamondLoop:	
		bgt $t5, 56, endOfClearPartDiamond # if count > 56, exit
		bgt $t6, 7, endOfClearPartDiamondWidth # if width_count > 7
		
		beq $t6, 1, firstColDiamond
				
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearPartDiamondLoop
		
		firstColDiamond: # do not update left edge (does not change)
			addi $t7, $t7, 4 # increment display address
			addi $t9, $t9, 4 # incrememnt location in Card array
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
			
			j DrawClearPartDiamondLoop

	endOfClearPartDiamondWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearPartDiamondLoop
		
	endOfClearPartDiamond:	
		jr $ra

clearFullDiamond:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s4 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 	
	DrawClearDiamondLoop:	
		bgt $t5, 56, endOfClearDiamond # if count > 56, exit
		bgt $t6, 7, endOfClearDiamondWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearDiamondLoop

	endOfClearDiamondWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearDiamondLoop
		
	endOfClearDiamond:	
		j init_obs_diamond																																				      		      		      		     																																						      		      		      		     																																						      		      		      		     																																					      		      		      		     																																						      		      		      		     																																						      		      		      		     	

###################################

init_horseshoe: 
		random_horseshoe_location:	
		# Random number generator
		li $v0, 42
		li $a0, 1
		li $a1, 50
		syscall
		
		add $s6, $a0, $zero
		addi $v0, $zero, ROW_SIZE
		mult $s6, $v0
		mflo $s6
		lw $t0, displayAddress 	# $t0 stores the base address for display
		add $s6, $s6, $t0
		addi $s6, $s6, -28
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		jal drawHorseshoe		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra

update_horseshoe:
		beq $s6, -1, ReturnFromHorseshoeUpdate # if there is no horseshoe on screen return	
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		lw $t0, displayAddress 	# $t0 stores the base address for display
		sub $v0, $s6, $t0 	# subtract base address from top left corner of obs location
		li $v1, ROW_SIZE 
		div $v0, $v1 	# divide relative location of obs by row size
		mfhi $v0 	# store remainder of division in $v0
		beq $v0, $zero, clearFullHorseshoe	# if card has reached left edge, erase it
		jal clearPartHorseshoe	# else, clear parts of it
		addi $s6, $s6, -4
			
		jal drawHorseshoe		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		ReturnFromHorseshoeUpdate:
			jr $ra
	
drawHorseshoe:	
		addi $t5, $0, 1 	# unit counter
		addi $t6, $0, 1 	# width unit counter
		move $t7, $s6 	# stores address of top left corner
		la $t9, HorseshoeCard 	# holds array of card
		
	 
	DrawHorseshoeLoop:	
		bgt $t5, 56, endOfHorseshoeCard # if count > 56, exit
		bgt $t6, 7, endOfHorseshoeWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawHorseshoeLoop

	endOfHorseshoeWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawHorseshoeLoop
		
	endOfHorseshoeCard:	
		move $t7, $s6 # stores address of top left corner
		lw $v0, horseshoe
		
		sw $v0, 264($t7) # row 1
		sw $v0, 268($t7)
		sw $v0, 272($t7)
		
		sw $v0, 516($t7) # row 2  
		sw $v0, 532($t7)
		 
		sw $v0, 772($t7) # row 3
		sw $v0, 788($t7) 
		  
		sw $v0, 1032($t7) # row 4
		sw $v0, 1040($t7)
		  
		sw $v0, 1288($t7) # row 5 
		sw $v0, 1296($t7) 
		
		sw $v0, 1540($t7) # row 6
		sw $v0, 1544($t7)
		sw $v0, 1552($t7)
		sw $v0, 1556($t7)    
		
		jr $ra	

clearPartHorseshoe:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s6 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearPartHorseshoeLoop:	
		bgt $t5, 56, endOfClearPartHorseshoe # if count > 56, exit
		bgt $t6, 7, endOfClearPartHorseshoeWidth # if width_count > 7
		
		beq $t6, 1, firstColHorseshoe
				
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearPartHorseshoeLoop
		
		firstColHorseshoe: # do not update left edge (does not change)
			addi $t7, $t7, 4 # increment display address
			addi $t9, $t9, 4 # incrememnt location in Card array
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
			
			j DrawClearPartHorseshoeLoop

	endOfClearPartHorseshoeWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearPartHorseshoeLoop
		
	endOfClearPartHorseshoe:	
		jr $ra

clearFullHorseshoe:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s6 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 	
	DrawClearHorseshoeLoop:	
		bgt $t5, 56, endOfClearHorseshoe # if count > 56, exit
		bgt $t6, 7, endOfClearHorseshoeWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearHorseshoeLoop

	endOfClearHorseshoeWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearHorseshoeLoop
		
	endOfClearHorseshoe:	
		addi $s6, $zero, -1 # set $s6 to -1 (inactive)
		jr $ra

###################################

init_key: 
		random_key_location:	
		# Random number generator
		li $v0, 42
		li $a0, 1
		li $a1, 50
		syscall
		
		add $s5, $a0, $zero
		addi $v0, $zero, ROW_SIZE
		mult $s5, $v0
		mflo $s5
		lw $t0, displayAddress 	# $t0 stores the base address for display
		add $s5, $s5, $t0
		addi $s5, $s5, -28
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		jal drawKey		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		jr $ra

update_key:
		beq $s5, -1, ReturnFromKeyUpdate # if there is no key on screen return	
		
		addi $sp, $sp, -4 # move stack ptr over a word
		sw $ra, 0($sp) # push $ra onto stack
		
		lw $t0, displayAddress 	# $t0 stores the base address for display
		sub $v0, $s5, $t0 	# subtract base address from top left corner of obs location
		li $v1, ROW_SIZE 
		div $v0, $v1 	# divide relative location of obs by row size
		mfhi $v0 	# store remainder of division in $v0
		beq $v0, $zero, clearFullKey	# if card has reached left edge, erase it
		jal clearPartKey	# else, clear parts of it
		addi $s5, $s5, -4
			
		jal drawKey		# draw card
		
		lw $ra, 0($sp) # pop off stack
		addi $sp, $sp, 4
		
		ReturnFromKeyUpdate:
			jr $ra
	
drawKey:	
		addi $t5, $0, 1 	# unit counter
		addi $t6, $0, 1 	# width unit counter
		move $t7, $s5 	# stores address of top left corner
		la $t9, KeyCard 	# holds array of card
		
	 
	DrawKeyLoop:	
		bgt $t5, 56, endOfKeyCard # if count > 56, exit
		bgt $t6, 7, endOfKeyWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawKeyLoop

	endOfKeyWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawKeyLoop
		
	endOfKeyCard:	
		move $t7, $s5 # stores address of top left corner
		addi $t7, $t7, -4
		
		lw $v0, orange
		
		sw $v0, 272($t7) # row 1
		sw $v0, 276($t7)
		sw $v0, 280($t7)
		
		sw $v0, 528($t7) # row 2  
		sw $v0, 532($t7)
		sw $v0, 536($t7)
		 
		sw $v0, 784($t7) # row 3 
		  
		sw $v0, 1040($t7) # row 4
		sw $v0, 1044($t7)
		  
		sw $v0, 1296($t7) # row 5 
		
		sw $v0, 1544($t7) # row 6
		sw $v0, 1548($t7)
		sw $v0, 1552($t7) 
		sw $v0, 1556($t7)
		sw $v0, 1560($t7)   
		
		jr $ra	

clearPartKey:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s5 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 
	DrawClearPartKeyLoop:	
		bgt $t5, 56, endOfClearPartKey # if count > 56, exit
		bgt $t6, 7, endOfClearPartKeyWidth # if width_count > 7
		
		beq $t6, 1, firstColKey
				
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearPartKeyLoop
		
		firstColKey: # do not update left edge (does not change)
			addi $t7, $t7, 4 # increment display address
			addi $t9, $t9, 4 # incrememnt location in Card array
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
			
			j DrawClearPartKeyLoop

	endOfClearPartKeyWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearPartKeyLoop
		
	endOfClearPartKey:	
		jr $ra

clearFullKey:	
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
		move $t7, $s5 # stores address of top left corner
		la $t9, ClearCard # holds array of card
	 	
	DrawClearKeyLoop:	
		bgt $t5, 56, endOfClearKey # if count > 56, exit
		bgt $t6, 7, endOfClearKeyWidth # if width_count > 7
		lw  $t8, ($t9)
		sw $t8, ($t7)
		
		addi $t7, $t7, 4 # increment display address
		addi $t9, $t9, 4 # incrememnt location in Card array
		addi $t5, $t5, 1 # add 1 to unit counter
		addi $t6, $t6, 1 # add 1 to width counter
	
		j DrawClearKeyLoop

	endOfClearKeyWidth:	
		addi $t6, $0, 1 # reset width counter
		addi $t7, $t7, 228
		j DrawClearKeyLoop
		
	endOfClearKey:	
		addi $s5, $zero, -1 # set $s5 to -1 (inactive)
		jr $ra

####################################


update_shot:
	
	addi $sp, $sp -4
	sw $ra, 0($sp) # push $ra into stack

	beq $a3, -1, ReturnFromShotUpdate # no shot on screen
	# clear old shot position
	lw $t1, background_col
	sw $t1, ($a3)
	
	addi $t7, $a3, 4 # store location of shot in $t7
	addi $t8, $zero, ROW_SIZE # store row size in $t8
	div $t7, $t8 # divide right address by size of each row (remainder = column of hat)
	mfhi $t7  # store remainder in $t7
	beq $t7, 0, inactivate_shot	# if remainder = 0, clear shot from screen (shot has reached end of screen)
	
	# update shot position
	addi $a3, $a3, 4
	
	
	# if shot hits a spade
	CheckShotSpade:
		move $t7, $s1
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
	 	
		CheckShotSpadeLoop:	
			bgt $t5, 56, endOfCheckShotSpade # if count > 56, exit
			bgt $t6, 7, endOfCheckShotSpadeWidth # if width_count > 7
			
			beq $a3, $t7, hit_spade
			
			addi $t7, $t7, 4 # increment display address
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
	
			j CheckShotSpadeLoop

		endOfCheckShotSpadeWidth:	
			addi $t6, $0, 1 # reset width counter
			addi $t7, $t7, 228
			j CheckShotSpadeLoop
		
		endOfCheckShotSpade:	
			j CheckShotClub
	
	# if shot hits a club
	CheckShotClub:
		move $t7, $s2
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
	 	
		CheckShotClubLoop:	
			bgt $t5, 56, endOfCheckShotClub # if count > 56, exit
			bgt $t6, 7, endOfCheckShotClubWidth # if width_count > 7
			
			beq $a3, $t7, hit_club
			
			addi $t7, $t7, 4 # increment display address
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
	
			j CheckShotClubLoop

		endOfCheckShotClubWidth:	
			addi $t6, $0, 1 # reset width counter
			addi $t7, $t7, 228
			j CheckShotClubLoop
		
		endOfCheckShotClub:
			j CheckShotHeart
			
	# if shot hits a heart
	CheckShotHeart:
		move $t7, $s3
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
	 	
		CheckShotHeartLoop:	
			bgt $t5, 56, endOfCheckShotHeart # if count > 56, exit
			bgt $t6, 7, endOfCheckShotHeartWidth # if width_count > 7
			
			beq $a3, $t7, hit_heart
			
			addi $t7, $t7, 4 # increment display address
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
	
			j CheckShotHeartLoop

		endOfCheckShotHeartWidth:	
			addi $t6, $0, 1 # reset width counter
			addi $t7, $t7, 228
			j CheckShotHeartLoop
		
		endOfCheckShotHeart:
			j CheckShotDiamond
			
	# if shot hits a diamond
	CheckShotDiamond:
		move $t7, $s4
		addi $t5, $0, 1 # unit counter
		addi $t6, $0, 1 # width unit counter
	 	
		CheckShotDiamondLoop:	
			bgt $t5, 56, endOfCheckShotDiamond # if count > 56, exit
			bgt $t6, 7, endOfCheckShotDiamondWidth # if width_count > 7
			
			beq $a3, $t7, hit_diamond
			
			addi $t7, $t7, 4 # increment display address
			addi $t5, $t5, 1 # add 1 to unit counter
			addi $t6, $t6, 1 # add 1 to width counter
	
			j CheckShotDiamondLoop

		endOfCheckShotDiamondWidth:	
			addi $t6, $0, 1 # reset width counter
			addi $t7, $t7, 228
			j CheckShotDiamondLoop
		
		endOfCheckShotDiamond:
			j update_shot_position
	
	# draw shot at new position
	update_shot_position:
		lw $t1, shot_col
		sw $t1, ($a3)	
		
		ReturnFromShotUpdate: 
			lw $ra, 0($sp) # pop off stack
			addi $sp, $sp, 4
			jr $ra																																					      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     	
	
		inactivate_shot:
			addi $a3, $zero, -1 # set $a3 to inactive form
			j ReturnFromShotUpdate
	
		hit_spade:
			jal clearFullSpade
			j inactivate_shot
		
		hit_club:
			jal clearFullClub
			j inactivate_shot
	
		hit_heart:
			jal clearFullHeart
			j inactivate_shot
		
		hit_diamond:
			jal clearFullDiamond
			j inactivate_shot
			
						
###################################
draw_0:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 256($t7) # row 2
	sw $t1, 264($t7)
	
	sw $t1, 512($t7) # row 3
	sw $t1, 520($t7)
	
	sw $t1, 768($t7) # row 4
	sw $t1, 776($t7)
	
	sw $t1, 1024($t7) # row 5
	sw $t1, 1028($t7)
	sw $t1, 1032($t7)
	
	jr $ra

draw_1:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 8($t7)
	sw $t1, 264($t7)
	sw $t1, 520($t7)
	sw $t1, 776($t7)
	sw $t1, 1032($t7)
	
	jr $ra	
	
draw_2:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 264($t7) # row 2
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 768($t7) # row 4
	
	sw $t1, 1024($t7) # row 5
	sw $t1, 1028($t7)
	sw $t1, 1032($t7)
	
	jr $ra

draw_3:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 264($t7) # row 2
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 776($t7) # row 4
	
	sw $t1, 1024($t7) # row 5
	sw $t1, 1028($t7)
	sw $t1, 1032($t7)
	
	jr $ra																																					      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																				      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																				      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     	
																																					      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     	
draw_4:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 8($t7)
	
	sw $t1, 256($t7) # row 2
	sw $t1, 264($t7)
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 776($t7) # row 4
	
	sw $t1, 1032($t7) # row 5
	
	jr $ra	

draw_5:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 256($t7) # row 2
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 776($t7) # row 4
	
	sw $t1, 1024($t7) # row 5
	sw $t1, 1028($t7)
	sw $t1, 1032($t7)
	
	jr $ra	

draw_6:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 256($t7) # row 2
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 768($t7) # row 4
	sw $t1, 776($t7)
	
	sw $t1, 1024($t7) # row 5
	sw $t1, 1028($t7)
	sw $t1, 1032($t7)
	
	jr $ra	
	
draw_7:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 264($t7) # row 2
	sw $t1, 520($t7) # row 3
	sw $t1, 776($t7) # row 4
	sw $t1, 1032($t7) # row 5
	
	jr $ra		

draw_8:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 256($t7) # row 2
	sw $t1, 264($t7)
	
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 768($t7) # row 4
	sw $t1, 776($t7)
	
	sw $t1, 1024($t7) # row 5
	sw $t1, 1028($t7)
	sw $t1, 1032($t7)
	
	jr $ra		

draw_9:
	lw $t7, 0($sp) # pop location off stack
	addi $sp, $sp, 4
	
	lw $t1, black # store black colour in $t1
	
	sw $t1, 0($t7) # row 1
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t1, 256($t7) # row 2
	sw $t1, 264($t7)
	
	sw $t1, 512($t7) # row 3
	sw $t1, 516($t7)
	sw $t1, 520($t7)
	
	sw $t1, 776($t7) # row 4
	
	sw $t1, 1032($t7) # row 5
	
	jr $ra				

clear_score:
	addi $t7, $t0, THOUSANDS_DIGIT  
	lw $t1, bottom_bar_col
	
	addi $t5, $zero, 1 # initialize unit counter to 1
	addi $t6, $zero, 0 # initialize width counter to 0
	
	clear_score_loop:
		bge $t5, 75, end_clear_score
		bge $t6, 15, end_of_width_clear_score
		
		sw $t1, 0($t7)
		
		addi $t6, $t6, 1 # increment width counter by 1
		addi $t5, $t5, 1 # increment row counter by 1
		addi $t7, $t7, 4 # increment position on bitmap display
		j clear_score_loop
		
		end_of_width_clear_score:
			addi $t6, $zero, 0 # reset width counter to 0
			addi $t7, $t7, 196 # next row
			j clear_score_loop
		
		
	end_clear_score:
		jr $ra																																						
																											
####################################																																					      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     																																						      		      		      		     	
GAME_OVER:
	
	lw $t0, displayAddress
	lw $t1, red	
	# draw green bar
	addi $t0, $t0, 15404 # store top left corner of HP bar in $t0
	sw $t1, 4($t0)
	
	darken_screen:	lw $t0, displayAddress
			addi $t7, $zero, 1 	# initialize unit counter
			
		darken_loop:	
			bgt $t7, TOTAL_SIZE, write_game_over
			lw $t1, 0($t0)
			subi $t1, $t1, 0x42450b
			sw $t1, 0($t0)
			addi $t7, $t7, 1 	# incremeent unit counter
			addi $t0, $t0, 4
			j darken_loop
	
	write_game_over:
		lw $t0, displayAddress
		addi $t0, $t0, 5980
		lw $t1, black
		
		sw $t1, 0($t0) # row 1
		sw $t1, 4($t0)
		sw $t1, 8($t0)
		sw $t1, 12($t0)
		sw $t1, 24($t0)
		sw $t1, 28($t0)
		sw $t1, 32($t0)
		sw $t1, 40($t0)
		sw $t1, 44($t0)
		sw $t1, 48($t0)
		sw $t1, 52($t0)
		sw $t1, 56($t0)
		sw $t1, 64($t0)
		sw $t1, 68($t0)
		sw $t1, 72($t0)
		
		sw $t1, 256($t0) # row 2
		sw $t1, 280($t0)
		sw $t1, 288($t0)
		sw $t1, 296($t0)
		sw $t1, 304($t0)
		sw $t1, 312($t0)
		sw $t1, 320($t0)
		
		sw $t1, 512($t0) # row 3
		sw $t1, 520($t0)
		sw $t1, 524($t0)
		sw $t1, 528($t0)
		sw $t1, 536($t0)
		sw $t1, 540($t0)
		sw $t1, 544($t0)
		sw $t1, 552($t0)
		sw $t1, 560($t0)
		sw $t1, 568($t0)
		sw $t1, 576($t0)
		sw $t1, 580($t0)
		
		sw $t1, 768($t0) # row 4
		sw $t1, 780($t0)
		sw $t1, 792($t0)
		sw $t1, 800($t0)
		sw $t1, 808($t0)
		sw $t1, 816($t0)
		sw $t1, 824($t0)
		sw $t1, 832($t0)
		
		sw $t1, 1024($t0) # row 5
		sw $t1, 1028($t0)
		sw $t1, 1032($t0)
		sw $t1, 1036($t0)
		sw $t1, 1048($t0)
		sw $t1, 1056($t0)
		sw $t1, 1064($t0)
		sw $t1, 1080($t0)
		sw $t1, 1088($t0)
		sw $t1, 1092($t0)
		sw $t1, 1096($t0)
		
		# row 6 (blank row)
	
		sw $t1, 1536($t0) # row 7
		sw $t1, 1540($t0)
		sw $t1, 1544($t0)
		sw $t1, 1552($t0)
		sw $t1, 1568($t0)
		sw $t1, 1576($t0)
		sw $t1, 1580($t0)
		sw $t1, 1584($t0)
		sw $t1, 1592($t0)
		sw $t1, 1596($t0)
		sw $t1, 1600($t0)
		sw $t1, 1604($t0)
		
		sw $t1, 1792($t0) # row 8
		sw $t1, 1800($t0)
		sw $t1, 1808($t0)
		sw $t1, 1824($t0)
		sw $t1, 1832($t0)
		sw $t1, 1848($t0)
		sw $t1, 1860($t0)
		
		sw $t1, 2048($t0) # row 9
		sw $t1, 2056($t0)
		sw $t1, 2064($t0)
		sw $t1, 2080($t0)
		sw $t1, 2088($t0)
		sw $t1, 2092($t0)
		sw $t1, 2104($t0)
		sw $t1, 2108($t0)
		sw $t1, 2112($t0)
		sw $t1, 2116($t0)
		
		sw $t1, 2304($t0) # row 10
		sw $t1, 2312($t0)
		sw $t1, 2324($t0)
		sw $t1, 2332($t0)
		sw $t1, 2344($t0)
		sw $t1, 2360($t0)
		sw $t1, 2368($t0)
		
		sw $t1, 2560($t0) # row 11
		sw $t1, 2564($t0)
		sw $t1, 2568($t0)
		sw $t1, 2584($t0)
		sw $t1, 2600($t0)
		sw $t1, 2604($t0)
		sw $t1, 2608($t0)
		sw $t1, 2616($t0)
		sw $t1, 2628($t0)
		
		j GAME_OVER_LOOP
		
	GAME_OVER_LOOP: 
		# Check for key press
		li $t9, 0xffff0000
		lw $t8, 0($t9)
		
		bne $t8, 1, GAME_OVER_LOOP	# if no key press, continue with update
		
		lw $t7, 4($t9) # this assumes $t9 is set to 0xfff0000 from before
		beq $t7, 0x70, main # ASCII code of 'p' is 0x70
		
		j GAME_OVER_LOOP
	
Exit:	li $v0, 10 # terminate the program gracefully
	syscall
