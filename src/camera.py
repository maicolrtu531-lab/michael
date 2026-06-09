import pygame
from src.settings import *

class Camera:
    def __init__(self):
        self.offset_x = 0
        self.offset_y = 0

    def update(self, target):
        self.offset_x = target.rect.centerx - SCREEN_WIDTH  // 2
        self.offset_y = target.rect.centery - SCREEN_HEIGHT // 2
        self.offset_x = max(0, min(self.offset_x, WORLD_WIDTH  - SCREEN_WIDTH))
        self.offset_y = max(0, min(self.offset_y, WORLD_HEIGHT - SCREEN_HEIGHT))

    def apply(self, rect):
        return pygame.Rect(rect.x - self.offset_x, rect.y - self.offset_y, rect.width, rect.height)
