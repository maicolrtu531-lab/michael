import pygame
from src.settings import *
from src.scenes.menu_scene     import MenuScene
from src.scenes.game_scene     import GameScene
from src.scenes.gameover_scene import GameOverScene

class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption(TITLE)
        self.clock  = pygame.time.Clock()
        self.scene  = MenuScene()

    def run(self):
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    return
                result = self.scene.handle_event(event)
                if result:
                    self._switch(result)

            self.scene.update()
            self.scene.draw(self.screen)

            # Check scene transitions from GameScene
            if isinstance(self.scene, GameScene) and self.scene.next_scene:
                ns = self.scene.next_scene
                p  = self.scene.player
                if ns == SCENE_GAMEOVER:
                    self.scene = GameOverScene(win=False, kills=p.kills, level=p.level, gold=p.gold)
                elif ns == SCENE_WIN:
                    self.scene = GameOverScene(win=True,  kills=p.kills, level=p.level, gold=p.gold)

            pygame.display.flip()
            self.clock.tick(FPS)

    def _switch(self, target):
        if target == "quit":
            import sys; pygame.quit(); sys.exit()
        elif target == SCENE_GAME:
            self.scene = GameScene()
        elif target == SCENE_MENU:
            self.scene = MenuScene()
