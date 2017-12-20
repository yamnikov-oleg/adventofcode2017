package day16

import java.io.FileNotFoundException
import java.lang.RuntimeException
import scala.collection.immutable.Vector
import scala.io.Source

sealed abstract class DanceMove
case class MoveSpin(count: Int) extends DanceMove
case class MoveExchange(pos1: Int, pos2: Int) extends DanceMove
case class MovePartner(progA: Char, progB: Char) extends DanceMove

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
  var programs = Vector.range('a', 'q')

  def spin(count: Int): Unit = {
    val pre = programs.slice(0, programs.length - count)
    val post = programs.slice(programs.length - count, programs.length)
    programs = post ++ pre
  }

  def exchange(pos1: Int, pos2: Int): Unit = {
    val (min, max) = if (pos1 < pos2) (pos1, pos2) else (pos2, pos1)

    val pre = programs.slice(0, min)
    val elem1 = programs(min)
    val inter = programs.slice(min + 1, max)
    val elem2 = programs(max)
    val post = programs.slice(max + 1, programs.length)
    programs = (pre :+ elem2) ++ inter ++ (elem1 +: post)
  }

  def partner(progA: Char, progB: Char): Unit = {
    exchange(programs.indexOf(progA), programs.indexOf(progB))
  }

  def applyMove(move: DanceMove): Unit = {
    move match {
      case MoveSpin(count) => spin(count)
      case MoveExchange(pos1, pos2) => exchange(pos1, pos2)
      case MovePartner(progA, progB) => partner(progA, progB)
    }
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
  val moves = parser.toList
  println(s"Parsed ${moves.length} moves")

  val dance = new Dance
  for (i <- 0 to dancesCount-1) {
    if (i % 10000 == 0) {
      println
      print(i + ": ")
    }
    if (i % 100 == 0) {
      print(".")
    }
    moves.foreach (dance.applyMove _)
  }
  println
  println(s"Program positions after $dancesCount dances: ${dance.programs.mkString}")
}
