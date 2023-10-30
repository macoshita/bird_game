import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

enum BallType {
  hachidori(1, Colors.pink),
  suzume(2, Colors.red),
  tsubame(3, Colors.deepOrange),
  mukudori(4, Colors.orange),
  hiyodori(5, Colors.amber),
  kijibato(6, Colors.yellow),
  kogamo(7, Colors.lime),
  karasu(8, Colors.lightGreen),
  karugamo(9, Colors.green),
  tobi(10, Colors.teal),
  taka(11, Colors.cyan),
  washi(12, Colors.lightBlue),
  ;

  final double radius;
  final Color color;
  const BallType(this.radius, this.color);
}

void main() {
  runApp(const GameWidget.controlled(gameFactory: Game.new));
}

class Game extends Forge2DGame {
  Game() : super(gravity: Vector2(0, 50.0), world: World());

  @override
  Color backgroundColor() {
    return Colors.white;
  }
}

class World extends Forge2DWorld
    with TapCallbacks, HasGameReference<Forge2DGame> {
  CircleComponent? _nextBall;
  BallType? _nextBallType;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _nextBallType = BallType.values[Random().nextInt(5)];
    addAll(createBoundaries());

    final visibleRect = game.camera.visibleWorldRect;
    add(TextComponent(
      text: "NEXT",
      position: visibleRect.topRight.toVector2() + Vector2(-15, 5),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 4,
          color: Colors.black,
        ),
      ),
    ));
    _addNextSprite();
  }

  void _addNextSprite() async {
    if (_nextBall != null) {
      remove(_nextBall!);
    }
    final visibleRect = game.camera.visibleWorldRect;
    _nextBall = CircleComponent(
      position: visibleRect.topRight.toVector2() +
          Vector2(-10, 15) -
          Vector2.all(_nextBallType!.radius),
      radius: _nextBallType!.radius,
      paint: Paint()..color = _nextBallType!.color,
    );
    add(_nextBall!);
  }

  List<Component> createBoundaries() {
    final visibleRect = game.camera.visibleWorldRect;
    final topLeft = visibleRect.topLeft.toVector2();
    final topRight = visibleRect.topRight.toVector2();
    final bottomRight = visibleRect.bottomRight.toVector2();
    final bottomLeft = visibleRect.bottomLeft.toVector2();

    return [
      Wall(topLeft, topRight),
      Wall(topRight, bottomRight),
      Wall(bottomLeft, bottomRight),
      Wall(topLeft, bottomLeft),
    ];
  }

  @override
  void onTapDown(TapDownEvent event) async {
    super.onTapDown(event);
    final visibleRect = game.camera.visibleWorldRect;
    add(Ball(
      Vector2(event.localPosition.x, visibleRect.top),
      _nextBallType!,
    ));
    _nextBallType = BallType.values[Random().nextInt(5)];
    _addNextSprite();
  }
}

class Ball extends BodyComponent with ContactCallbacks {
  final int _createdAt;
  final Vector2 _position;
  final BallType _ballType;
  final bool hit;

  Ball(
    this._position,
    this._ballType, {
    this.hit = true,
  }) : _createdAt = DateTime.now().microsecondsSinceEpoch;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = _ballType.radius;

    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.4,
      density: 1.0,
      friction: 0.4,
    );

    final bodyDef = BodyDef(
      userData: this,
      angularDamping: 0.8,
      position: _position,
      type: BodyType.dynamic,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Ball && other._ballType == _ballType) {
      world.remove(this);
      world.remove(other);
      if (_createdAt < other._createdAt) {
        if (_ballType.index == BallType.values.length - 1) {
          return;
        }
        final ballType = BallType.values[_ballType.index + 1];
        final pos = (contact.bodyA.worldCenter + contact.bodyB.worldCenter) / 2;
        world.add(Ball(pos, ballType));
      }
    }
  }

  @override
  void renderCircle(Canvas canvas, Offset center, double radius) {
    super.renderCircle(canvas, center, radius);
    canvas.drawCircle(
      center,
      radius,
      paint..color = _ballType.color,
    );
  }
}

class Wall extends BodyComponent {
  final Vector2 _start;
  final Vector2 _end;

  Wall(this._start, this._end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(_start, _end);
    final fixtureDef = FixtureDef(shape, friction: 0.3);
    final bodyDef = BodyDef(position: Vector2.zero());

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
