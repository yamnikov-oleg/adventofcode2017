package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Printf("Requires file path in command-line arguments")
		os.Exit(1)
	}

	file, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	validCount := 0
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		wordSet := map[string]struct{}{}
		words := strings.Split(line, " ")
		isValid := true
		for _, word := range words {
			if _, ok := wordSet[word]; ok {
				isValid = false
				break
			}
			wordSet[word] = struct{}{}
		}

		if isValid {
			validCount++
		}
	}

	fmt.Printf("Total valid count: %v\n", validCount)
}
