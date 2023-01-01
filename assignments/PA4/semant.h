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
  InheritanceGraph();
  ~InheritanceGraph();
  void add(Symbol parent_name, Symbol class_name);
  void add(const std::string& parent_name, const std::string& class_name);
  void dump(std::ostream& stream);


private:
  struct Node {
    const std::string name;
    /**
     * If the class has a body 
     */
    bool defined;
    std::forward_list<Node*> children;
    Node* parent;

    Node(const std::string& name_) : Node(name_, false) { }
    Node(const std::string& name_, bool defined_) : name(name_), defined(defined_), parent(nullptr) { }
    /**
     * Recursively dump the entire sub tree 
     */
    void dump(std::ostream& stream);
  };
  
  Node* root;
  int n_nodes;
  int n_defined;
  std::map<std::string, Node*> name_to_node;

  /**
   * Add the node to the tree if the symbol does not exist. Otherwise get the 
   * existing node with the same class name 
   */
  Node* get_or_add_node(Symbol name);
  Node* get_or_add_node(const std::string& name);
  /**
   * Add a new node to the with the class name 'name'. If the class name is 
   * already defined an error will be reported 
   */
  Node* add_node(Symbol name);
  Node* add_node(const std::string& name);

  /**
   * Delete the node and the sub tree rooted with this 
   * node 
   */
  void delete_node(Node* node);

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

