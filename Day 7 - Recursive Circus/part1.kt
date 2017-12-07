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

    val subprograms = match.groupValues[3].split(", ").toTypedArray()

    return Pair(name, ProgramProps(weight, subprograms))
}

fun main(args: Array<String>) {
    if (args.size < 1) {
        println("Requires input file path")
        exitProcess(1)
    }

    // Build a map from program names to the property of having a parent.
    val programsParented: MutableMap<String, Boolean> = HashMap()

    try {
        val file = File(args[0])
        file.bufferedReader().useLines { lines ->
            for (line in lines) {
                // Parse line into program name and its properties
                val (name, props) = parseProgramProps(line)

                // All subprograms of this program definitely have a parent.
                for (sub in props.subprograms) {
                    programsParented[sub] = true
                }

                // Unless this program is marked as "parented", mark it as
                // "unparented".
                if (!programsParented.containsKey(name)) {
                    programsParented[name] = false
                }
            }
        }
    } catch (e: Exception) {
        println(e.message)
        exitProcess(1)
    }

    println("Programs without any parent:")
    val unparented = programsParented.filter { (_, parented) -> !parented }.keys
    for (program in unparented) {
        println(program)
    }
}
