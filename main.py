import pygame
import sys
from src.game import Game

def main():
    pygame.init()
    game = Game()
    game.run()
    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
