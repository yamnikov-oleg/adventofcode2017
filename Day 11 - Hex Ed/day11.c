#include <stdio.h>
#include <string.h>

typedef enum {
    DIR_N,
    DIR_NE,
    DIR_SE,
    DIR_S,
    DIR_SW,
    DIR_NW,
} dir_t;

int readword(char *buf, unsigned int bufsize, FILE *f)
{
    // Should leave one last char for the \0
    int result = 0;
    for (; bufsize > 1; bufsize--)
    {
        int ch = fgetc(f);
        if (ch == EOF)
        {
            result = EOF;
            break;
        }
        if (ch == ',' || ch == '\n')
        {
            break;
        }

        *buf = (char)ch;
        buf++;
    }

    *buf = '\0';
    return result;
}

typedef enum {
    READ_SUCCESS,
    READ_EOF,
    READ_INVALID,
} read_t;

read_t readdir(dir_t *dir, FILE *f)
{
    char buf[16];
    int rwr = readword(buf, 16, f);
    if (strlen(buf) == 0)
    {
        if (rwr == EOF)
            return READ_EOF;

        return readdir(dir, f);
    }

    if (strcmp(buf, "n") == 0)
        *dir = DIR_N;
    else if (strcmp(buf, "ne") == 0)
        *dir = DIR_NE;
    else if (strcmp(buf, "se") == 0)
        *dir = DIR_SE;
    else if (strcmp(buf, "s") == 0)
        *dir = DIR_S;
    else if (strcmp(buf, "sw") == 0)
        *dir = DIR_SW;
    else if (strcmp(buf, "nw") == 0)
        *dir = DIR_NW;
    else
        return READ_INVALID;

    return READ_SUCCESS;
}

// Coordinates in a hex field:
//   ___     ___
//  / 0 \___/ 2 \___
//  \_0_/ 1 \_0_/ 3 \_
//  / 0 \_0_/ 2 \_0_/
//  \_1_/ 1 \_1_/ 3 \_
//  / 0 \_1_/ 2 \_1_/
//  \_2_/ 1 \_2_/ 3 \_
//      \_2_/   \_2_/
//
typedef struct
{
    int column;
    int row;
} hexcoord_t;

void move(hexcoord_t *coord, dir_t dir)
{
    switch (dir)
    {
    case DIR_N:
        coord->row--;
        break;
    case DIR_NE:
        if (coord->column % 2 == 0)
            coord->row--;

        coord->column++;
        break;
    case DIR_SE:
        if (coord->column % 2 != 0)
            coord->row++;

        coord->column++;
        break;
    case DIR_S:
        coord->row++;
        break;
    case DIR_SW:
        if (coord->column % 2 != 0)
            coord->row++;

        coord->column--;
        break;
    case DIR_NW:
        if (coord->column % 2 == 0)
            coord->row--;

        coord->column--;
        break;
    }
}

int distanceToOrigin(hexcoord_t coord)
{
    // Min and max close row indices. These are the min and max index
    // of the rows, which can be reached by exactly D steps, where D is
    // the absolute value of coord.column.
    int minClose, maxClose;
    int absColumn = coord.column < 0 ? -coord.column : coord.column;
    if (absColumn % 2 == 0)
    {
        minClose = -(absColumn / 2);
        maxClose = absColumn / 2;
    }
    else
    {
        minClose = -(absColumn / 2) - 1;
        maxClose = absColumn / 2;
    }

    if (coord.row >= minClose && coord.row <= maxClose)
    {
        return absColumn;
    }
    else if (coord.row < minClose)
    {
        return absColumn + (minClose - coord.row);
    }
    else
    {
        return absColumn + (coord.row - maxClose);
    }
}

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        puts("Input file path is required");
        return 1;
    }

    FILE *inputFile = fopen(argv[1], "r");
    if (inputFile == NULL)
    {
        perror("Error while opening file");
        return 1;
    }

    dir_t dir;
    read_t read;
    hexcoord_t coord = {0, 0};
    int farthestDistance = 0;
    while ((read = readdir(&dir, inputFile)) == READ_SUCCESS)
    {
        move(&coord, dir);
        int distance = distanceToOrigin(coord);
        if (distance > farthestDistance)
        {
            farthestDistance = distance;
        }
    }
    if (read == READ_INVALID)
    {
        puts("Invalid format of the input file");
        return 1;
    }
    fclose(inputFile);

    printf("Final coord: %d, %d\n", coord.column, coord.row);
    printf("Distance to the origin cell: %d\n", distanceToOrigin(coord));
    printf("Farthest distance ever: %d\n", farthestDistance);
}
