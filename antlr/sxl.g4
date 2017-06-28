/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

grammar sxl;
blocks : 'blocks' '{' block+ '}' ;

block : LABEL '{' block_item+ '}' ;
block_item
    : description
    | address
    | size
    | registers
    ;

registers : 'registers' '{' register+ '}';

register : LABEL '{' register_item+ '}';
register_item
    : description    #regDescription
    | address        #regAddr
    | signals        #regSignals
    | notify         #regNotify
    ;

signals : 'signals' '{' signal+ '}' ;

signal : LABEL '{' signal_item+ '}' ;
signal_item
    : unit          #dontcare
    | numrep        #dontcare
    | range_item    #dontcare
    | position      #sigPosition
    | sigmode       #sigMode
    | resetval      #sigReset
    | type_item     #dontcare
    | enumeration   #dontcare
    | description   #dontcare
    ;

enumeration : 'enums' '{' enum_item+ '}' ;
enum_item: LABEL '{' value description? '}' ;

description : 'desc' STRING;
address : 'addr' HEX ;
size : 'size' HEX ;
value : 'value' (Positive | Natural);
notify : 'notify' key=('rw' | 'ro' | 'wo') ;

unit : 'unit' unit_value ;
unit_value
    : '-'
    | LABEL
    | 'Perc.'
    ;

numrep : 'numrep' numrep_value ;
numrep_value
    : 'uint8'
    | 'uint16'
    | 'uint32'
    | 'sint8'
    | 'sint16'
    | 'sint32'
    | 'ufix8.8'
    | 'enum'
    | 'bool'
    | 'raw'
    ;

range_item : 'range' range_value ;
range_value
    : Nat_range
    | Int_range
    | Fix_range
    | '-'
    ;

position : 'pos' position_value ;
position_value
    : Positive      #posSingle
    | Natural       #posSingle
    | Nat_range     #posRange
    ;

sigmode : 'mode' key=('ro' | 'rw' | 'wo' | 't' | 'c') ;

resetval : 'reset' resetval_value ;
resetval_value
    : Positive      #resetInt
    | Natural       #resetInt
    | HEX           #resetHex
    ;

type_item : 'type' type_val ;
type_val
    : 'enum'
    | 'flag'
    ;

Fix_range
    : Fixpoint ':' Fixpoint
    ;

Nat_range
    : Natural ':' Natural
    ;

Int_range
    : Integer ':' (Positive ':')? Integer
    ;


HEX : [0] [xX] [0-9a-fA-F]+ ;

Fixpoint : '-'? FIX;
fragment FIX
    : INT '.' [0-9]+
    ;

Positive : POS;
Natural : INT;
Integer : '-'? INT;

fragment INT
    : '0' | POS
    ;

fragment POS
    : [1-9] [0-9]*
    ;

LABEL : [a-zA-Z] [a-zA-Z0-9]* ;
EXT_LABEL : (LABEL | [-_:.] )+ ;

STRING : '{' ~[{}\r\n]* '}' ;
WS : [ \t\r\n]+ -> skip ;
