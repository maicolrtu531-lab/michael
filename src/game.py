import pygame
from src.settings import *
from src.scenes.game_scene import GameScene

class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption(TITLE)
        self.clock  = pygame.time.Clock()
        self.scene  = GameScene()

    def run(self):
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return
                if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                    return
                self.scene.handle_event(event)

            self.scene.update()
            self.scene.draw(self.screen)
            pygame.display.flip()
            self.clock.tick(FPS)
