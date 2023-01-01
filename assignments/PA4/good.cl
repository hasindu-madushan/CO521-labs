class C {
	a : Int;
	b : Bool;
	init(x : Int, y : Bool) : C {
           {
		a <- x;
		b <- y;
		self;
           }
	};
};

class A inherits C {
};

Class Main {
	main():C {
	  (new C).init(1,true)
	};
};
