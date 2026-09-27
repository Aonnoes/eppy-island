bool checkCollision(player, block) {
  final playerX = player.position.x;
  final playerY = player.position.y;
  final blockX = block.position.x;
  final blockY = block.position.y;

  final playerWidth = player.width;
  final playerHeight = player.height;
  final blockWidth = block.width;
  final blockHeight = block.height;

  return (playerX < blockX + blockWidth &&
      playerX + playerWidth > blockX &&
      playerY < blockY + blockHeight &&
      playerY + playerHeight > blockY);
}
