% Liu Bei forsees that Yuan Shiu will be defeated by Cao Cao
% He needs to find a route to safety in Jin province before the defeat
% But Cao Cao's soldiers are everywhere

int: nrow;
set of int: ROW = 1..nrow;
int: ncol;
set of int: COL = 1..ncol;

% Plains, Mountain, Forest, City, River
enum TERRAIN = { P, M, F, C, R };
array[TERRAIN] of int: delay;
int: timelimit;

array[ROW,COL] of TERRAIN: terrain;
array[ROW,COL] of int: soldier;
array[ROW,COL] of bool: Jin;

int: start_row;
int: start_col;

int: maxstep;
set of int: STEP = 1..maxstep;
set of int: STEP0 = 0..maxstep;

var STEP: steps;
array[ROW,COL] of var STEP0: visit; % which step do we visit position or 0 if not visited
array[STEP] of var 0..nrow: step_row;
array[STEP] of var 0..ncol: step_col;

constraint forall(s in 1..steps)(visit[step_row[s],step_col[s]] == s);
constraint forall(s in steps+1..maxstep)(step_row[s]==0 /\ step_col[s]==0);

% start at start position
% constraint visit[start_row,start_col] = 1;
constraint step_row[1] = start_row;
constraint step_col[1] = start_col;

% only use steps moves
%constraint sum(r in ROW, c in COL)(visit[r,c] >= 1) <= steps;

% reach Jin province
%constraint exists(r in ROW, c in COL)(Jin[r,c] /\ visit[r,c] >= 1);
constraint Jin[step_row[steps],step_col[steps]] == true;

% visit at most one city
/*
constraint not exists(r1,r2 in ROW, c1,c2 in COL)
                     ((r1 != r2 \/ c1 != c2) 
                      /\ terrain[r1,c1] = C /\ terrain[r2,c2] = C 
                      /\ visit[r1,c1] >= 1 /\ visit[r2,c2] >= 1); 
*/
%constraint sum(r in ROW, c in COL where terrain[r,c] == C)(visit[r,c] > 0) <= 1;
constraint sum(s in 1..steps)(terrain[step_row[s],step_col[s]] == C) <= 1;

% cannot enter Mountain
%constraint not exists(r in ROW, c in COL)(terrain[r,c] = M /\ visit[r,c] >= 1);
%constraint forall(r in ROW, c in COL where terrain[r,c] == M)(visit[r,c] == 0);
constraint sum(s in 1..steps)(terrain[step_row[s],step_col[s]] == M) == 0;

% visit only one place in every step
/*
constraint forall(r1,r2 in ROW, c1,c2 in COL)
                 (r1 != r2 \/ c1 != c2  
                  -> (visit[r1,c1] = 0 
                      \/ visit[r2,c2] != visit[r1,c1])); 
*/
include "alldifferent_except_0.mzn";
constraint alldifferent_except_0(visit);

% steps form a path
/*
constraint forall(s in 1..steps-1)
                 (exists(r1, r2 in ROW, c1, c2 in COL)
                        (abs(r1-r2) + abs(c1-c2) = 1 
                         /\ visit[r1,c1] = s /\ visit[r2,c2] = s+1));
*//*
constraint forall(r in ROW,c in ROW where visit[r,c] in 1..steps-1)(
    sum(r1 in ROW, c1 in COL where abs(r1-r) + abs(c1-c) == 1)(
    visit[r1,c1] - visit[r,c] == 1) == 1    
);*/
constraint forall(s in 1..steps-1)(
    abs(step_row[s+1] - step_row[s]) + abs(step_col[s+1] - step_col[s]) == 1
);

% no shortcuts
/*
constraint forall(r1,r2 in ROW, c1,c2 in COL)
                 (abs(r1-r2) + abs(c1-c2) = 1 ->
                  visit[r1,c1] = 0 \/ visit[r2,c2] = 0 \/
                  abs(visit[r1,c1] - visit[r2,c2]) = 1);
*/
constraint forall(s1 in 1..steps-2)(
    forall(s2 in s1+2..steps)(
        abs(step_row[s1] - step_row[s2]) + abs(step_col[s1] - step_col[s2]) > 1
    )
);

% not too much delay
constraint time <= timelimit;
%var int: time = sum(r in ROW, c in COL)(delay[terrain[r,c]]*(visit[r,c] >= 1));
var int: time = sum(s in 1..steps)(delay[terrain[step_row[s],step_col[s]]]);

% minimize the number of soldiers traversed
solve minimize obj;
%var int: obj = sum(r in ROW, c in COL)((visit[r,c] > 0)*soldier[r,c]);
var int: obj = sum(s in 1..steps)(soldier[step_row[s],step_col[s]]);



array[TERRAIN] of string: ter = [".", "#", "^", "C", "~"];




output 
       ["% step_row = \(step_row);\n"]++
       ["% step_col = \(step_col);\n"]++
       ["%"] ++
       [ " " ++ ter[fix(terrain[r,c])] ++ if c = ncol then "\n%" else "" endif
       | r in ROW, c in COL ]
       ++ ["\n%"] ++
       [ if soldier[r,c] > 0 then show_int(2,soldier[r,c]) else " ." endif
         ++ if c = ncol then "\n%" else "" endif
       | r in ROW, c in COL ]
       ++ ["\n"] ++
       ["%"] ++
       [ if fix(visit[r,c]) > 0 then show_int(2,visit[r,c]) else " ." endif
         ++ if c = ncol then "\n%" else "" endif
       | r in ROW, c in COL ]
       ++ ["\nvisit = array2d(ROW,COL,\(visit));\nsteps = \(steps);\ntime = \(time);\nobj = \(obj);"]
       ;

/*
output
    %["%\n"]++
    ["% \(step_row);\n"]++
    ["% \(step_col);\n"]++
    ["%\n"]++
    ["visit = array2d(ROW,COL,\(visit));\nsteps = \(steps);\ntime = \(time);\nobj = \(obj);"]
    ;
*/
