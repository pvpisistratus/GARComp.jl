using Colors, RandomBattles

HEIGHT = 667
WIDTH = 375
BACKGROUND = colorant"grey14"

type_colors = (colorant"snow4", colorant"crimson", colorant"skyblue3", 
    colorant"darkorchid", colorant"tan3", colorant"burlywood", 
    colorant"greenyellow", colorant"indigo", colorant"steelblue4", 
    colorant"orange", colorant"dodgerblue", colorant"green3", 
    colorant"gold", colorant"salmon", colorant"paleturquoise", 
    colorant"midnightblue", colorant"black", colorant"lightpink")

team1 = "medicham", "azumarill", "altaria"
team2 = "stunfisk_galarian", "jellicent", "bastiodon"

static_state = StaticState((team1[1], team1[2], team1[3], 
    team2[1], team2[2], team2[3]))
dynamic_state = DynamicState(static_state)

get_colors(team::UInt8, mon::UInt8) = 
    type_colors[static_state[team][mon].primary_type], 
    static_state[team][mon].secondary_type < UInt8(19) ? 
        type_colors[static_state[team][mon].secondary_type] : 
        type_colors[static_state[team][mon].primary_type]

pokemon = (Rect(94, 384, 20, 40), Rect(114, 384, 20, 40)), 
    (Rect(241, 242, 20, 40), Rect(261, 242, 20, 40))

pokemon_labels = TextActor(team1[1], "open_sans"; 
    pos = (94, 424), font_size = 10, color = Int[255,255,255,255]), 
    TextActor(team2[1], "open_sans"; 
    pos = (241, 282), font_size = 10, color = Int[255,255,255,255])

hp_bar_holders = Rect(62, 369, 102, 10), Rect(209, 227, 102, 10)

function get_hp_percent(team::UInt8, active::UInt8)
    percent = (UInt16(100) * 
        RandomBattles.get_hp(dynamic_state[team][active])) ÷ 
        static_state[team][active].stats.hitpoints
    color = percent >= 50 ? colorant"green" : 
        percent >= 20 ? colorant"yellow" : colorant"red"
    return percent, color
end

d1, d2 = RandomBattles.get_possible_decisions(dynamic_state, static_state,
    allow_nothing = false, allow_overfarming = false)

home_decision = 0x02
charged_move = 0x00
in_turn = false
opp_charged_move = false

function draw()
    active = RandomBattles.get_active(dynamic_state)
    pokemon_colors = get_colors(0x01, active[1]), get_colors(0x02, active[2])
    
    for i = 0x01:0x02
        for j = 0x01:0x02
            draw(pokemon[i][j], pokemon_colors[i][j], fill = true)
        end
        draw(pokemon_labels[i])
        draw(hp_bar_holders[i], colorant"white", fill = true)
        hp_percent, hp_color = get_hp_percent(i, active[i])
        draw(Rect(hp_bar_holders[i].x + 1, hp_bar_holders[i].y + 1, 
            hp_percent, 8), hp_color, fill = true)
    end

    if !opp_charged_move
        # switch buttons
        switch1 = active[1] == 0x01 ? 0x02 : 0x01
        switch2 = active[1] == 0x03 ? 0x02 : 0x03
        switch1_colors = get_colors(0x01, switch1)
        switch2_colors = get_colors(0x01, switch2)
        draw(Rect(146, 384, 9, 18), switch1_colors[1], fill = true)
        draw(Rect(155, 384, 9, 18), switch1_colors[2], fill = true)
        draw(Rect(146, 406, 9, 18), switch2_colors[1], fill = true)
        draw(Rect(155, 406, 9, 18), switch2_colors[2], fill = true)
        # println(dynamic_state[0x01].switch_cooldown)
        draw(Rect(146, 384, 18, 
            (3 * Int64(dynamic_state[0x01].switch_cooldown)) ÷ 20), 
            colorant"grey14", fill = true)
        draw(Rect(146, 406, 18, 
            (3 * Int64(dynamic_state[0x01].switch_cooldown)) ÷ 20), 
            colorant"grey14", fill = true)

        # charged move buttons
        draw(Circle(71, 393, 9), 
            type_colors[static_state[0x01][active[1]].charged_move_1.move_type], 
            fill = true)
        draw(Circle(71, 415, 9), 
            type_colors[static_state[0x01][active[1]].charged_move_2.move_type], 
            fill = true)
        draw(Rect(61, 383, 20, 20 - min(20, 
            (20 * Int64(RandomBattles.get_energy(
            dynamic_state[0x01][active[1]]))) ÷ Int64(RandomBattles.get_energy(
            static_state[0x01][active[1]].charged_move_1)))), 
            colorant"grey14", fill = true)
        draw(Rect(61, 405, 20, 20 - min(20, 
            (20 * Int64(RandomBattles.get_energy(
            dynamic_state[0x01][active[1]]))) ÷ Int64(RandomBattles.get_energy(
            static_state[0x01][active[1]].charged_move_2)))), 
            colorant"grey14", fill = true)
    end

    # shields
    num_shields =  RandomBattles.get_shields(dynamic_state[0x01])
    num_shields > 0x00 ? draw(Actor("shield.png", pos = (41, 406))) : 0
    num_shields > 0x01 ? draw(Actor("shield.png", pos = (41, 384))) : 0
    num_shields =  RandomBattles.get_shields(dynamic_state[0x02])
    num_shields > 0x00 ? draw(Actor("shield.png", pos = (290, 207))) : 0
    num_shields > 0x01 ? draw(Actor("shield.png", pos = (270, 207))) : 0

    # opponent mons
    RandomBattles.get_hp(dynamic_state[0x02][0x01]) > 0x0000 ? 
        draw(Circle(220, 217, 8), colorant"red", fill = true) : 0
    RandomBattles.get_hp(dynamic_state[0x02][0x02]) > 0x0000 ? 
        draw(Circle(240, 217, 8), colorant"red", fill = true) : 0
    RandomBattles.get_hp(dynamic_state[0x02][0x03]) > 0x0000 ? 
        draw(Circle(260, 217, 8), colorant"red", fill = true) : 0
end

function update_turn()
    if !iszero(d1) && !iszero(d2)
        decision = home_decision, 
            #RandomBattles.select_random_decision(d1, d2)[1],
            RandomBattles.select_random_decision(d1, d2)[2]
        turn_output = RandomBattles.play_turn(dynamic_state, static_state, 
            decision)
        global dynamic_state = 
            turn_output.odds == 1.0 || rand() < turn_output.odds ? 
            turn_output.next_state_1 : turn_output.next_state_2
        active = RandomBattles.get_active(dynamic_state)
        if 0x05 in decision || 0x06 in decision
            global pokemon_labels = TextActor(team1[active[1]], "open_sans"; 
                pos = (94, 424), font_size = 10, color = Int[255,255,255,255]), 
                TextActor(team2[active[2]], "open_sans"; 
                pos = (241, 282), font_size = 10, color = Int[255,255,255,255])
        end
        global opp_charged_move = decision[2] == 0x04
        global d2 = RandomBattles.get_possible_decisions(
            dynamic_state, static_state,
            allow_nothing = false, allow_overfarming = false)[2]
        global d1 = RandomBattles.get_possible_decisions(
            dynamic_state, static_state,
            allow_nothing = true, allow_overfarming = true)[1]
        if home_decision == 0x04
            global home_decision = charged_move + 0x06
        else
            global home_decision = !iszero(d1 & 0x02) ? 0x02 : 
                !iszero(d1 & 0x10) ? 0x05 : 0x06
        end
    end
    global in_turn = false
end

function update()
    if !in_turn
        schedule_once(update_turn, opp_charged_move ? 12.0 : 0.5)
        global in_turn = true
    end
end

function on_mouse_down(g::Game, pos, button)
    if home_decision == 0x02
        global home_decision = 
            !iszero(d1 & 0x01) && 40<pos[1]<62 && 383<pos[2]<427 ? 0x01 :
            !iszero(d1 & 0x08) && 60<pos[1]<82 && 383<pos[2]<427 ? 0x04 : 
            !iszero(d1 & 0x10) && 145<pos[1]<165 && 383<pos[2]<403 ? 0x05 : 
            !iszero(d1 & 0x20) && 145<pos[1]<165 && 405 <pos[2]<425 ? 0x06 : 
            !iszero(d1 & 0x04) ? 0x03 : 0x02
        global charged_move = home_decision == 0x05 ? 
            (383<pos[2]<405 ? 0x01 : 0x02) : 0x00
    end
end
