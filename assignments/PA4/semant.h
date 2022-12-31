#ifndef SEMANT_H_
#define SEMANT_H_

#include <assert.h>
#include <iostream>  
#include "cool-tree.h"
#include "stringtab.h"
#include "symtab.h"
#include "list.h"
#include <forward_list>
#include <map>


#define TRUE 1
#define FALSE 0

class ClassTable;
typedef ClassTable *ClassTableP;

class InheritanceGraph {
public:
  void add(Symbol parent_name, Symbol class_name);


private:
  struct Node {
    const std::string name;
    bool defined;
    std::forward_list<Node*> children;

    Node(const std::string& name_) : Node(name_, false) { }
    Node(const std::string& name_, bool defined_) : name(name_), defined(defined_) { }
  };
  
  int n_nodes;
  int n_defined;
  std::map<std::string, Node*> name_to_node;

  Node* add_node(const std::string& name);
  Node* add_node(Symbol name);
};

// This is a structure that may be used to contain the semantic
// information such as the inheritance graph.  You may use it or not as
// you like: it is only here to provide a container for the supplied
// methods.

class ClassTable {
private:

  
  int semant_errors;
  Class_ inheritance_graph;
  void install_basic_classes();
  bool check_cycles(Class_ new_class, Class_ current_node);
  ostream& error_stream;

public:
  ClassTable(Classes);
  int errors() { return semant_errors; }
  ostream& semant_error();
  ostream& semant_error(Class_ c);
  ostream& semant_error(Symbol filename, tree_node *t);
};


#endif

