package day16

import java.io.FileNotFoundException
import java.lang.RuntimeException
import scala.collection.mutable.ArraySeq
import scala.collection.mutable.ArrayBuffer
import scala.io.Source

sealed abstract class DanceMove
case class MoveSpin(count: Int) extends DanceMove
case class MoveExchange(pos1: Int, pos2: Int) extends DanceMove
case class MovePartner(progA: Char, progB: Char) extends DanceMove
case class MoveMap(map: Array[Int]) extends DanceMove

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

class Dance {
  var programs = ArraySeq.range('a', 'q').toArray
  var programPos = ArraySeq.range(0, 16).toArray

  def spin(count: Int): Unit = {
    if (count == 0) return

    val newPrograms = programs.clone
    System.arraycopy(programs, 0, newPrograms, count, programs.length - count)
    System.arraycopy(programs, programs.length - count, newPrograms, 0, count)
    programs = newPrograms
  }

  def exchange(pos1: Int, pos2: Int): Unit = {
    val prog1 = programs(pos1)
    val prog2 = programs(pos2)

    programs(pos1) = prog2
    programs(pos2) = prog1

    programPos(prog1 - 'a') = pos2
    programPos(prog2 - 'a') = pos1
  }

  def partner(progA: Char, progB: Char): Unit = {
    exchange(programPos(progA - 'a'), programPos(progB - 'a'))
  }

  def moveMap(map: Array[Int]): Unit = {
    val newPrograms = programs.clone
    for (i <- 0 until programs.length) {
      newPrograms(i) = programs(map(i))
      programPos(newPrograms(i) - 'a') = i
    }
    programs = newPrograms
  }

  def applyMove(move: DanceMove): Unit = {
    move match {
      case MoveSpin(count) => spin(count)
      case MoveExchange(pos1, pos2) => exchange(pos1, pos2)
      case MovePartner(progA, progB) => partner(progA, progB)
      case MoveMap(map) => moveMap(map)
    }
  }
}

object Dance {
  def spinMap(moveMap: Array[Int], count: Int): Array[Int] = {
    if (count == 0) return moveMap

    val newMoveMap = moveMap.clone
    System.arraycopy(moveMap, 0, newMoveMap, count, moveMap.length - count)
    System.arraycopy(moveMap, moveMap.length - count, newMoveMap, 0, count)
    newMoveMap
  }

  def exchangeMap(moveMap: Array[Int], pos1: Int, pos2: Int): Unit = {
    val prog1 = moveMap(pos1)
    val prog2 = moveMap(pos2)
    moveMap(pos1) = prog2
    moveMap(pos2) = prog1
  }

  def identityMoveMap(): Array[Int] = {
    val map = Array.ofDim[Int](16)
    for (i <- 0 until map.length) {
      map(i) = i
    }
    map
  }

  def optimize(moves: Array[DanceMove]): Array[DanceMove] = {
    val newMoves = ArrayBuffer.empty[DanceMove]

    var mapSet = false
    var moveMap = identityMoveMap

    moves.foreach {
      _ match {
        case MoveSpin(count) => {
          moveMap = spinMap(moveMap, count)
          mapSet = true
        }
        case MoveExchange(pos1, pos2) => {
          exchangeMap(moveMap, pos1, pos2)
          mapSet = true
        }
        case MovePartner(progA, progB) => {
          if (mapSet) {
            newMoves.append(MoveMap(moveMap))
            moveMap = identityMoveMap
            mapSet = false
          }
          newMoves.append(MovePartner(progA, progB))
        }
        case MoveMap(_) => {
          throw new RuntimeException("MoveMap in an unoptimized moves array")
        }
      }
    }

    newMoves.toArray
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

  val moves = Dance.optimize(parsedMoves)
  println(s"Optimized to ${moves.length} moves")

  val dance = new Dance
  for (i <- 0 until dancesCount) {
    if (i % 100000 == 0) {
      println
      print(i + ": ")
      print(".")
    } else if (i % 1000 == 0) {
      print(".")
    }

    moves.foreach(dance.applyMove)
  }
  println
  println(s"Program positions after $dancesCount dances: ${dance.programs.mkString}")
}
