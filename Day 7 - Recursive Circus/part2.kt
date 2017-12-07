import java.io.File
import kotlin.system.exitProcess

data class ProgramProps(val weight: Int, val subprograms: Array<String>)

val programRegex = Regex("""(\w+) \((\d+)\)(?: -> (.+))?""")

fun parseProgramProps(line: String): Pair<String, ProgramProps> {
    val match = programRegex.matchEntire(line)
    if (match == null) {
        throw IllegalArgumentException("\"$line\": the line has illegal format")
    }

    val name = match.groupValues[1]

    val weightString = match.groupValues[2]
    val weight: Int
    try {
        weight = weightString.toInt()
    } catch (e: NumberFormatException) {
        throw IllegalArgumentException("\"$weightString\": the weight is not a valid integer")
    }

    var subprograms: Array<String> = arrayOf()
    if (match.groupValues[3].isNotEmpty()) {
        subprograms = match.groupValues[3].split(", ").toTypedArray()
    }

    return Pair(name, ProgramProps(weight, subprograms))
}

class ProgramTree {
    private val programs: MutableMap<String, ProgramProps> = HashMap()
    private val parents: MutableMap<String, String> = HashMap()

    val root: String
        get() = programs.keys.filter { name -> !parents.containsKey(name) }.first()

    fun insert(name: String, props: ProgramProps) {
        programs[name] = props
        for (sub in props.subprograms) {
            parents[sub] = name
        }
    }

    sealed class BranchBalance {
        data class Balanced(
            val totalWeight: Int
        ) : BranchBalance()
        data class Imbalanced(
            val program: String,
            val actualWeight: Int,
            val requiredWeight: Int
        ) : BranchBalance()
    }

    fun checkBranchBalance(branchRoot: String): BranchBalance {
        val props = programs[branchRoot]
        if (props == null) {
            throw IllegalArgumentException("unknown program \"$branchRoot\"")
        }

        if (props.subprograms.isEmpty()) {
            return BranchBalance.Balanced(props.weight)
        }

        val subweights: MutableMap<String, Int> = mutableMapOf()
        for (sub in props.subprograms) {
            val balance = checkBranchBalance(sub)
            if (balance is BranchBalance.Imbalanced) {
                return balance
            } else if (balance is BranchBalance.Balanced) {
                subweights[sub] = balance.totalWeight
            }
        }

        if (subweights.size >= 3) {
            // If this program has at least three child, we can find one branch
            // which's weight doesn't match weights of the others.
            // This algorithm assumes that all the weights of all the branches
            // equal each other except _one_.
            var candidate1: String? = null
            var candidate2: String? = null
            for ((branch, weight) in subweights) {
                if (candidate1 == null) {
                    candidate1 = branch
                    continue
                }
                if (candidate2 == null) {
                    if (weight != subweights[candidate1]) {
                        candidate2 = branch
                    }
                    continue
                }

                var balancedBranch: String
                var imbalancedBranch: String
                if (weight != subweights[candidate1]) {
                    // Candidate 1 is the imbalanced branch
                    balancedBranch = candidate2
                    imbalancedBranch = candidate1
                } else {
                    // Candidate 2 is the imbalanced branch
                    balancedBranch = candidate1
                    imbalancedBranch = candidate2
                }

                val balancedWeight = subweights[balancedBranch]!!
                val imbalancedWeight = subweights[imbalancedBranch]!!
                return BranchBalance.Imbalanced(
                    candidate1,
                    imbalancedWeight,
                    balancedWeight
                )
            }
        }

        return BranchBalance.Balanced(props.weight + subweights.values.sum())
    }

    fun checkBalance(): BranchBalance = checkBranchBalance(root)
}

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Requires input file path")
        exitProcess(1)
    }

    // First pass: parse the tree.
    val tree = ProgramTree()
    try {
        val file = File(args[0])
        file.bufferedReader().useLines { lines ->
            for (line in lines) {
                val (name, props) = parseProgramProps(line)
                tree.insert(name, props)
            }
        }
    } catch (e: Exception) {
        println(e.message)
        exitProcess(1)
    }

    // Second pass: traverse the tree to find imbalanced programs
    val balance = tree.checkBalance()
    if (balance is ProgramTree.BranchBalance.Balanced) {
        println("The tree is balanced and has the total weight of ${balance.totalWeight}")
    } else if (balance is ProgramTree.BranchBalance.Imbalanced) {
        println("The tree has imbalanced program \"${balance.program}\"")
        println("Its weight equals to ${balance.actualWeight} but should equal to ${balance.requiredWeight} to make tree balanced")
    }
}
