package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	idSum := 0
	powerSum := 0

	for scanner.Scan() {
		line := scanner.Text()
		line = line[5:]
		idAndGames := strings.SplitN(line, ":", 2)
		id, err := strconv.Atoi(idAndGames[0])

		if err != nil {
			panic(err)
		}

		games := strings.Split(idAndGames[1], ";")

		var (
			valid    bool = true
			maxRed   int
			maxGreen int
			maxBlue  int
		)

		for _, game := range games {
			var (
				red   int
				green int
				blue  int
			)

			colors := strings.Split(game, ",")

			for _, colorInfo := range colors {
				colorInfo = strings.TrimSpace(colorInfo)
				numberAndColor := strings.Fields(colorInfo)
				number, err := strconv.Atoi(numberAndColor[0])

				if err != nil {
					panic(err)
				}

				switch numberAndColor[1][0] {
				case 'r':
					red += number
				case 'g':
					green += number
				case 'b':
					blue += number
				}

				if red > 12 || green > 13 || blue > 14 {
					valid = false
				}

				maxRed = max(maxRed, red)
				maxGreen = max(maxGreen, green)
				maxBlue = max(maxBlue, blue)
			}
		}

		if valid {
			idSum += id
		}

		powerSum += maxRed * maxGreen * maxBlue
	}

	if err := scanner.Err(); err != nil {
		panic(err)
	}

	fmt.Printf("ID Sum: %d\nPower Sum: %d\n", idSum, powerSum)
}
