import {
  Assignment,
  CompileFailedError,
  CompileResult,
  Expression,
  FunctionCall,
  FunctionCallOptions,
  FunctionDefinition,
  Identifier,
  IndexAccess,
  MemberAccess,
  compileSol,
} from "solc-typed-ast";
import * as fs from "fs";
import { ASTReader } from "solc-typed-ast";
const CALL = "call";
const ADDRESS = "address";

main();

// main function, which loads cmd arguments and start all operations
async function main() {
  const solidityFilePath = process.argv[2];
  const result = await compile(solidityFilePath);
  if (isCompileResult(result)) {
    scanFileForReentrancy(result);
  } else {
    console.log("Something went wrong with compiling .sol file");
  }
}

// Function, which comiples solidity file to solc-typed-ast "CompileResult"
// NOTE: Solidity file should be in the same directory
async function compile(
  solidityFilePath: string
): Promise<CompileResult | void> {
  try {
    return await compileSol(solidityFilePath, "auto");
  } catch (e) {
    if (e instanceof CompileFailedError) {
      console.error("Compile errors encountered:");

      for (const failure of e.failures) {
        console.error(`Solc ${failure.compilerVersion}:`);

        for (const error of failure.errors) {
          console.error(error);
        }
      }
    } else {
      console.error(e);
    }
  }
}
// The function iterates through all functions declared in a solidity file and for each function:
//              - Chek if there are external calls using solidity `call` operator and if there are:
//                  - Check whether there are storage variables assigments happening after the external call
//                  And if there are:
//                      - We print in which function the vulnerability is and the offset of the operation
function scanFileForReentrancy(compiledSol: CompileResult) {
  let vulnerable = false;
  const reader = new ASTReader();
  const sourceUnits = reader.read(compiledSol.data);
  sourceUnits.forEach((line) => {
    sourceUnits[0].walk((el) => {
      // Enter only functions
      if (el.type == "FunctionDefinition") {
        const funcDeclarationId = el.id;
        let externalCallId = 0;
        // Check if there is an external call operator and rise a flag if there is
        el.walk((c) => {
          if (c instanceof FunctionCall) {
            if (c.vExpression instanceof FunctionCallOptions) {
              const options = c.vExpression.vExpression;
              if (options instanceof MemberAccess) {
                if (
                  options.memberName === CALL &&
                  options.vExpression.typeString === ADDRESS
                ) {
                  // We have an external call
                  externalCallId = c.id;
                }
              }
            }
          }
        });
        // If there is... Make a search for the operators after the external call and
        // check for storage update
        if (externalCallId != 0) {
          el.walk((c) => {
            if (c.type == "Assignment") {
              let variableDeclaretionId: number = Number.MAX_VALUE;
              const type = (c as Assignment).vLeftHandSide;
              if (type instanceof IndexAccess) {
                const declaration =
                  findReferanceDeclarationForIndexAccess(type);
                if (declaration) {
                  variableDeclaretionId = declaration;
                }
              } else if (type instanceof Identifier) {
                variableDeclaretionId = type.referencedDeclaration;
              }
              // Check whether the assigned variable is a storage variable.
              if (variableDeclaretionId < funcDeclarationId) {
                // Check whether the assigment is after an external call
                if (c.id > externalCallId) {
                  vulnerable = true;
                  console.log(`!!! Reentrancy vulnerability spotted !!!
                  Vulnerability details: 
                  Function: "${(el as FunctionDefinition).name}"
                  Location Offset: ${c.sourceInfo.offset}`);
                }
              }
            }
          });
        }
      }
    });
  });
  if (!vulnerable) {
    console.log("Provided code is safe from reentrancy");
  }
}

// A func to check whether the file has been compiled successfully
function isCompileResult(obj: any): obj is CompileResult {
  return (
    (obj as CompileResult) !== undefined &&
    (obj as CompileResult).compilerVersion !== undefined
  );
}

// The function recursively enter nodes of type "IndexAccess" untill reaches an "Identity" node
// and obtain the id of the corresponding variable declaration.
function findReferanceDeclarationForIndexAccess(
  index: IndexAccess
): number | undefined {
  const vBase = index.vBaseExpression;
  if (vBase instanceof Identifier) {
    return vBase.referencedDeclaration;
  } else if (vBase instanceof IndexAccess) {
    return findReferanceDeclarationForIndexAccess(vBase);
  } else return undefined;
}
