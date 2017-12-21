package day16

import java.io.FileNotFoundException
import java.lang.RuntimeException
import scala.collection.mutable.ArraySeq
import scala.collection.mutable.ArrayBuffer
import scala.io.Source

// Product type of all dance moves
sealed abstract class DanceMove
case class MoveSpin(count: Int) extends DanceMove
case class MoveExchange(pos1: Int, pos2: Int) extends DanceMove
case class MovePartner(progA: Char, progB: Char) extends DanceMove

// State machine for the input parser
class MovesParser(input: Iterator[Char]) extends Iterator[DanceMove] {
  object States extends Enumeration {
    val Free, Spin, Exchange1, Exchange2,
      Partner1, PartnerSlash, Partner2, PartnerComma, EOF = Value
  }

  private var state = States.Free
  private var buff = ""
  private var buff2 = ""
  private var moveBuffer: Option[DanceMove] = None

  def update(): Option[DanceMove] = {
    if (!input.hasNext) {
      state = States.EOF
      return None
    }

    val char = input.next
    (state, char) match {
      case (States.Free, 's') => {
        state = States.Spin
        None
      }
      case (States.Free, 'x') => {
        state = States.Exchange1
        None
      }
      case (States.Free, 'p') => {
        state = States.Partner1
        None
      }
      case (States.Free, '\n') => {
        None
      }

      case (States.Spin, c) if c.isDigit => {
        buff = buff + c
        None
      }
      case (States.Spin, ',' | '\n') => {
        val move = MoveSpin(buff.toInt)

        state = States.Free
        buff = ""
        Some(move)
      }

      case (States.Exchange1, c) if c.isDigit => {
        buff = buff + c
        None
      }
      case (States.Exchange1, '/') => {
        state = States.Exchange2
        None
      }

      case (States.Exchange2, c) if c.isDigit => {
        buff2 = buff2 + c
        None
      }
      case (States.Exchange2, ',' | '\n') => {
        val move = MoveExchange(buff.toInt, buff2.toInt)

        state = States.Free
        buff = ""
        buff2 = ""
        Some(move)
      }

      case (States.Partner1, c) if c.isLetter => {
        buff = c + ""
        state = States.PartnerSlash
        None
      }
      case (States.PartnerSlash, '/') => {
        state = States.Partner2
        None
      }
      case (States.Partner2, c) if c.isLetter => {
        buff2 = c + ""
        state = States.PartnerComma
        None
      }
      case (States.PartnerComma, ',' | '\n') => {
        val move = MovePartner(buff(0), buff2(0))

        state = States.Free
        buff = ""
        buff2 = ""
        Some(move)
      }

      case (_, c) => {
        throw new RuntimeException(s"Unexpected char $c")
      }
    }
  }

  def hasNext(): Boolean = {
    while (moveBuffer.isEmpty && state != States.EOF) {
      moveBuffer = update
    }

    if (!moveBuffer.isEmpty) {
      true
    } else {
      false
    }
  }

  def next(): DanceMove = {
    if (hasNext) {
      val move = moveBuffer.get
      moveBuffer = None
      move
    } else {
      throw new RuntimeException("Call to next with empty iterator")
    }
  }
}

// The class of programs dance, performs all the moves
class Dance {
  var programs = ArraySeq.range(Dance.FirstProgram, Dance.ProgramAfterLast).toArray

  // Applies a move map (see Dance.optimize)
  def map(map: Array[Int]): Unit = {
    val newPrograms = programs.clone
    for (i <- 0 until programs.length) {
      newPrograms(i) = programs(map(i))
    }
    programs = newPrograms
  }

  // Applies programs substitutions (see Dance.optimize)
  def substitute(map: Map[Char, Char]): Unit = {
    for (i <- 0 until programs.length) {
      programs(i) = map(programs(i))
    }
  }
}

object Dance {
  val ProgramsCount = 16
  val FirstProgram = 'a'
  val LastProgram = ('a' + ProgramsCount - 1).toChar
  val ProgramAfterLast = ('a' + ProgramsCount).toChar

  // Compiles moves array into moves map and substitutions map.
  // The moves map maps programs' old indices onto their new indices.
  // The subtitutions map maps programs to be replaced onto the programs they
  // should be replaced by.
  def optimize(moves: Array[DanceMove]): (Array[Int], Map[Char, Char]) = {
    var moveMap = Array.ofDim[Int](Dance.ProgramsCount)
    for (i <- 0 until moveMap.length) {
      moveMap(i) = i
    }

    var subs = Map.empty[Char, Char]
    for (c <- Dance.FirstProgram to Dance.LastProgram) {
      subs += (c -> c)
    }

    moves.foreach {
      _ match {
        case MoveSpin(count) => {
          val (part1, part2) = moveMap.splitAt(moveMap.length - count)
          moveMap = part2 ++ part1
        }
        case MoveExchange(pos1, pos2) => {
          val prog1 = moveMap(pos1)
          val prog2 = moveMap(pos2)
          moveMap(pos1) = prog2
          moveMap(pos2) = prog1
        }
        case MovePartner(progA, progB) => {
          // Find keys of values progA and progB
          val progA_ = subs.find(p => p._2 == progA).get._1
          val progB_ = subs.find(p => p._2 == progB).get._1
          subs += (progA_ -> progB)
          subs += (progB_ -> progA)
        }
      }
    }

    (moveMap, subs)
  }
}

object Main extends App {
  if (args.length < 2) {
    println("Input file path and dances count are required")
    sys.exit(1)
  }

  val inputPath = args(0)
  val dancesCount = args(1).toInt

  val inputStream = try {
    Source.fromFile(inputPath)
  } catch {
    case ex: Throwable => {
      println(ex)
      sys.exit(1)
    }
  }

  val parser = new MovesParser(inputStream)
  val parsedMoves = parser.toArray
  println(s"Parsed ${parsedMoves.length} moves")

  val (moveMap, subs) = Dance.optimize(parsedMoves)

  val dance = new Dance
  for (itn <- 0 until dancesCount) {
    // Some progress output
    if (itn % (100*1000*1000) == 0) {
      println
      print((itn/(1000*1000)) + "M: ")
      print(".")
    } else if (itn % (1000*1000) == 0) {
      print(".")
    }

    dance.map(moveMap)
    dance.substitute(subs)
  }
  println
  println(s"Programs positions after $dancesCount dances: ${dance.programs.mkString}")
}
