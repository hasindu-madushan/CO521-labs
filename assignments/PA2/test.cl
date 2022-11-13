(* models one-dimensional cellular automaton on a circle of finite radius
   arrays are faked as Strings,
   X's respresent live cells, dots represent dead cells,
   no error checking is done *)
class CellularAutomaton inherits IO {
    population_map : String;
    flag: Bool;
   
    init(map : String) : SELF_TYPE {
        {
            population_map <- map;
	    flag <- true; -- for testing boolean
            self;
        }
    };
   
    print() : SELF_TYPE {
        {
	    (* unscpaed new line ! *)
            out_string(population_map.concat("He
llo\n"));
            self;
        }
    };
   
    num_cells() : Int {
        population_map.length()
    };
   
    cell(position : Int) : String {
        population_map.substr(position, 1)
    };
   
    cell_left_neighbor(position : Int) : String {
        if position = 0 then
            cell(num_cells() - 1)
        else
            cell(position - 1)
        fi
    };
   
    cell_right_neighbor(position : Int) : String {
        if position = num_cells() - 1 then
            cell(0)
        else
            cell(position + 1)
        fi
    };
   
    (* a cell will live if exactly 1 of itself and it's immediate
       neighbors are alive *)
    cell_at_next_evolution(position : Int) : String {
        if (if cell(position) = "X" then 1 else 0 fi
            + if cell_left_neighbor(position) = "X" then 1 else 0 fi
            + if cell_right_neighbor(position) = "X" then 1 else 0 fi
            = 1)
        then
            "X"
        else
            '.'
        fi
    };
   
    evolve() : SELF_TYPE {
        (let position : Int in
        (let num : Int <- num_cells[] in
        (let temp : String in
            {
                while position < num loop
                    {
                        temp <- temp.concat(cell_at_next_evolution(position));
                        position <- position + 1;
                    }
                pool;
                population_map <- temp;
                self;
            }
        ) ) )
    };
};

^^ -- Must show errors

class Main {
    cells : CellularAutomaton;
    x: Int;
    b: Bool;
    
*)
    main() : SELF_TYPE {
        {
            cells <- (new CellularAutomaton).init("         X         ");

	    -- LE 
	    b <- x <= 5;

	    (* Case *)
	    case x + 001 of 
		k : Int => x * x;
	    esac;

	    -- Valid escape characters test
	    let s: String <- "\n\f\t\b";

            cells.print();
            (let countdown : Int <- 20 in
                while countdown > 0 loop
                    {
                        cells.evolve();
			cells@CellularAutomaton.evolve();
                        cells.print();
                        countdown <- countdown - 1;
                    
                pool
            );  (* end let countdown
            self;
        }
    };
};
