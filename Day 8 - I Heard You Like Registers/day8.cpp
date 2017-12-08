#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <regex>
#include <string>

// Type for an error during instruction line parsing
class InstrParsingError : public std::runtime_error
{
  private:
    char const *const message;

  public:
    InstrParsingError(char const *const message) throw();
    virtual char const *what() const throw();
};

// Virtual machine holding the variable types
typedef std::map<std::string, int64_t> VM;

// Instruction from a single line of input
class Instruction
{
  public:
    enum Op
    {
        OpInc,
        OpDec,
    };

    enum Cmp
    {
        CmpEq,
        CmpNeq,
        CmpLt,
        CmpLte,
        CmpGt,
        CmpGte,
    };

    // Part before the 'if'
    std::string targetRegister;
    Op operation;
    int64_t operand;

    // Part after the 'if'
    std::string conditionRegister;
    Cmp comparison;
    int64_t comparisonOperand;

    Instruction(std::string);
    void execute(VM &);
};

InstrParsingError::InstrParsingError(char const *const message) throw() : std::runtime_error(message), message(message)
{
}

char const *InstrParsingError::what() const throw()
{
    return this->message;
}

const std::regex INSTRUCTION_RE(R"((\w+) (\w+) (-?\d+) if (\w+) ([<>=!]+) (-?\d+))");

Instruction::Instruction(std::string str)
{
    std::smatch match;
    if (!std::regex_match(str, match, INSTRUCTION_RE))
    {
        throw InstrParsingError("invalid string format");
    }

    this->targetRegister = match[1];

    if (match[2] == "inc")
    {
        this->operation = Instruction::OpInc;
    }
    else if (match[2] == "dec")
    {
        this->operation = Instruction::OpDec;
    }
    else
    {
        throw InstrParsingError("invalid operation");
    }

    this->operand = std::stol(match[3]);
    this->conditionRegister = match[4];

    if (match[5] == "==")
    {
        this->comparison = Instruction::CmpEq;
    }
    else if (match[5] == "!=")
    {
        this->comparison = Instruction::CmpNeq;
    }
    else if (match[5] == "<")
    {
        this->comparison = Instruction::CmpLt;
    }
    else if (match[5] == "<=")
    {
        this->comparison = Instruction::CmpLte;
    }
    else if (match[5] == ">")
    {
        this->comparison = Instruction::CmpGt;
    }
    else if (match[5] == ">=")
    {
        this->comparison = Instruction::CmpGte;
    }
    else
    {
        throw InstrParsingError("invalid comparison");
    }

    this->comparisonOperand = std::stol(match[6]);
}

void Instruction::execute(VM &vm)
{
    switch (this->comparison)
    {
    case Instruction::CmpEq:
        if (vm[this->conditionRegister] != this->comparisonOperand)
            return;
        break;
    case Instruction::CmpNeq:
        if (vm[this->conditionRegister] == this->comparisonOperand)
            return;
        break;
    case Instruction::CmpLt:
        if (vm[this->conditionRegister] >= this->comparisonOperand)
            return;
        break;
    case Instruction::CmpLte:
        if (vm[this->conditionRegister] > this->comparisonOperand)
            return;
        break;
    case Instruction::CmpGt:
        if (vm[this->conditionRegister] <= this->comparisonOperand)
            return;
        break;
    case Instruction::CmpGte:
        if (vm[this->conditionRegister] < this->comparisonOperand)
            return;
        break;
    }

    switch (this->operation)
    {
    case Instruction::OpInc:
        vm[this->targetRegister] += this->operand;
        break;
    case Instruction::OpDec:
        vm[this->targetRegister] -= this->operand;
        break;
    }
}

// Find the largest variable in the VM
std::pair<std::string, int64_t> largestVariable(const VM &vm)
{
    if (vm.size() == 0)
    {
        return std::pair<std::string, int64_t>("", std::numeric_limits<int64_t>::min());
    }

    auto it = vm.begin();
    std::string maxRegister = it->first;
    int64_t maxValue = it->second;
    while (it != vm.end())
    {
        if (it->second > maxValue)
        {
            maxRegister = it->first;
            maxValue = it->second;
        }
        it++;
    }

    return std::pair<std::string, int64_t>(maxRegister, maxValue);
}

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        std::cout << "Input file path is required" << std::endl;
        return 1;
    }

    std::ifstream inputFile(argv[1]);
    if (!inputFile.is_open())
    {
        perror("Error opening the file");
        return 1;
    }

    std::string line;
    uint64_t lineIndex = 1;
    VM vm;
    auto largestEver = largestVariable(vm);
    while (getline(inputFile, line))
    {
        try
        {
            Instruction ins(line);
            ins.execute(vm);

            auto largest = largestVariable(vm);
            if (largest.second > largestEver.second)
            {
                largestEver = largest;
            }
        }
        catch (InstrParsingError error)
        {
            std::cout << "Error on parsing line " << lineIndex << ":" << std::endl;
            std::cout << error.what() << std::endl;
            return 1;
        }

        lineIndex++;
    }

    auto largest = largestVariable(vm);
    std::cout << "Largest value after the end: "
              << largest.second
              << " in the register "
              << largest.first
              << std::endl;

    std::cout << "Largest value ever during the execution: "
              << largestEver.second
              << " in the register "
              << largestEver.first
              << std::endl;
}
