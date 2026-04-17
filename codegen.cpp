#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/Support/TargetSelect.h>
#include <llvm/MC/TargetRegistry.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/Host.h>
#include <llvm/Target/TargetMachine.h>
#include <llvm/Target/TargetOptions.h>
#include <map>
#include <iostream>
#include <cstring>
#include <optional>

using namespace llvm;

extern "C" {
    struct ASTNode {
        char* type; 
        int val; 
        char name[100];
        struct ASTNode *left, *right, *third;
    };
}

static LLVMContext Context;
static Module *TheModule = new Module("Expresso", Context);
static IRBuilder<> Builder(Context);
static std::map<std::string, AllocaInst *> NamedValues;
static int tCount = 0;
static int lCount = 0;

AllocaInst* getOrCreateAlloca(std::string name) {
    if (NamedValues.count(name)) return NamedValues[name];
    Function *F = Builder.GetInsertBlock()->getParent();
    IRBuilder<> TmpB(&F->getEntryBlock(), F->getEntryBlock().begin());
    AllocaInst* alloca = TmpB.CreateAlloca(Type::getInt64Ty(Context), nullptr, name);
    NamedValues[name] = alloca;
    return alloca;
}

std::string gen3AC(ASTNode* n) {
    if (!n) return "";
    if (strcmp(n->type, "NUM") == 0) return std::to_string(n->val);
    if (strcmp(n->type, "ID") == 0) return std::string(n->name);
    if (strcmp(n->type, "STR") == 0) return "\"" + std::string(n->name) + "\"";
    if (strcmp(n->type, "SEQ") == 0) { gen3AC(n->left); return gen3AC(n->right); }

    std::string res = "t" + std::to_string(tCount++);
    if (strcmp(n->type, "ASSIGN") == 0) {
        printf("  %s = %s\n", n->left->name, gen3AC(n->right).c_str());
        return n->left->name;
    }
    if (strcmp(n->type, "SHOW") == 0 || strcmp(n->type, "TAKE") == 0) {
        printf("  %s %s %s\n", n->type, gen3AC(n->left).c_str(), gen3AC(n->right).c_str());
        return "";
    }
    if (strcmp(n->type, "IF") == 0) {
        std::string lElse = "L" + std::to_string(lCount++);
        printf("  IF NOT %s GOTO %s\n", gen3AC(n->left).c_str(), lElse.c_str());
        gen3AC(n->right);
        printf("%s:\n", lElse.c_str());
        if (n->third) gen3AC(n->third);
        return "";
    }
    if (strcmp(n->type, "WHILE") == 0) {
        std::string lStart = "L" + std::to_string(lCount++);
        std::string lEnd = "L" + std::to_string(lCount++);
        printf("%s:\n", lStart.c_str());
        printf("  IF NOT %s GOTO %s\n", gen3AC(n->left).c_str(), lEnd.c_str());
        gen3AC(n->right);
        printf("  GOTO %s\n%s:\n", lStart.c_str(), lEnd.c_str());
        return "";
    }
    printf("  %s = %s %s %s\n", res.c_str(), gen3AC(n->left).c_str(), n->type, gen3AC(n->right).c_str());
    return res;
}

Value* GenerateIR(ASTNode* n) {
    if (!n) return nullptr;
    if (strcmp(n->type, "NUM") == 0) return ConstantInt::get(Context, APInt(64, n->val, true));
    if (strcmp(n->type, "ID") == 0) {
        AllocaInst* A = getOrCreateAlloca(n->name);
        return Builder.CreateLoad(A->getAllocatedType(), A, n->name);
    }
    if (strcmp(n->type, "SEQ") == 0) { GenerateIR(n->left); return GenerateIR(n->right); }
    if (strcmp(n->type, "ASSIGN") == 0) return Builder.CreateStore(GenerateIR(n->right), getOrCreateAlloca(n->left->name));
    
    if (strcmp(n->type, "+") == 0) return Builder.CreateAdd(GenerateIR(n->left), GenerateIR(n->right), "addtmp");
    if (strcmp(n->type, "-") == 0) return Builder.CreateSub(GenerateIR(n->left), GenerateIR(n->right), "subtmp");
    if (strcmp(n->type, "==") == 0) return Builder.CreateZExt(Builder.CreateICmpEQ(GenerateIR(n->left), GenerateIR(n->right), "eqtmp"), Type::getInt64Ty(Context));
    if (strcmp(n->type, ">") == 0) return Builder.CreateZExt(Builder.CreateICmpSGT(GenerateIR(n->left), GenerateIR(n->right), "gttmp"), Type::getInt64Ty(Context));

    if (strcmp(n->type, "IF") == 0) {
        Function *F = Builder.GetInsertBlock()->getParent();
        BasicBlock *ThenBB = BasicBlock::Create(Context, "then", F);
        BasicBlock *ElseBB = BasicBlock::Create(Context, "else", F);
        BasicBlock *MergeBB = BasicBlock::Create(Context, "ifcont", F);
        Value *Cond = Builder.CreateICmpNE(GenerateIR(n->left), ConstantInt::get(Context, APInt(64, 0)), "ifcond");
        Builder.CreateCondBr(Cond, ThenBB, ElseBB);
        Builder.SetInsertPoint(ThenBB); GenerateIR(n->right); Builder.CreateBr(MergeBB);
        Builder.SetInsertPoint(ElseBB); if (n->third) GenerateIR(n->third); Builder.CreateBr(MergeBB);
        Builder.SetInsertPoint(MergeBB); return nullptr;
    }
    return ConstantInt::get(Context, APInt(64, 0));
}

extern "C" void start_llvm_pipeline(ASTNode* root) {
    if (!root) return;
    InitializeNativeTarget(); 
    InitializeNativeTargetAsmPrinter();
    std::string Triple = sys::getDefaultTargetTriple();
    std::string Error; 
    auto Target = TargetRegistry::lookupTarget(Triple, Error);
    if (!Target) return;

    auto TM = Target->createTargetMachine(Triple, "generic", "", TargetOptions(), std::optional<Reloc::Model>());
    TheModule->setDataLayout(TM->createDataLayout());
    TheModule->setTargetTriple(Triple);

    TheModule->getOrInsertFunction("printf", FunctionType::get(Type::getInt32Ty(Context), PointerType::get(Type::getInt8Ty(Context), 0), true));
    TheModule->getOrInsertFunction("scanf", FunctionType::get(Type::getInt32Ty(Context), PointerType::get(Type::getInt8Ty(Context), 0), true));

    Function *F = Function::Create(FunctionType::get(Type::getInt32Ty(Context), false), Function::ExternalLinkage, "main", TheModule);
    Builder.SetInsertPoint(BasicBlock::Create(Context, "entry", F));

    GenerateIR(root);
    Builder.CreateRet(ConstantInt::get(Context, APInt(32, 0)));

    printf("\n--- THREE ADDRESS CODE (3AC) ---\n"); 
    gen3AC(root);

    std::error_code EC;
    raw_fd_ostream dest("out.ll", EC, sys::fs::OF_None);
    if (!EC) { TheModule->print(dest, nullptr); dest.flush(); }
}