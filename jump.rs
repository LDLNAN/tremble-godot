//! Jumping and fall timer logic for the player. Components and systems for jump/fall state.
//!
//! This module defines components and systems for tracking jump and fall timing for player movement.
use bevy::prelude::*;

/// Marker component for tracking the time since a player last jumped.
///
/// Used to prevent double-jumping and to time jump-related effects.
#[derive(Component, Default, Reflect, serde::Serialize, serde::Deserialize)]
#[reflect(Component)]
pub struct JustJumped {
    /// Seconds since the last jump. Resets to 0.0 on jump.
    pub timer: f32,
}
/// Component for tracking how long the player has been falling.
///
/// Used for landing logic and to distinguish between short hops and long falls.
#[derive(Component, Default, Reflect, serde::Serialize, serde::Deserialize)]
#[reflect(Component)]
pub struct FallTimer {
    /// Seconds spent falling (not grounded).
    pub timer: f32,
}
/// Component for storing the previous frame's fall timer value.
///
/// Used to detect landing events and for effects that depend on fall duration.
#[derive(Component, Default, Reflect, serde::Serialize, serde::Deserialize)]
#[reflect(Component)]
pub struct PreviousFallTimer {
    /// Previous fall timer value (copied from `FallTimer` each frame).
    pub timer: f32,
}

/// Updates the jump and fall timers for all players.
///
/// - Increments `JustJumped.timer` if less than f32::MAX.
/// - Resets `FallTimer` if grounded, otherwise increments it.
///
/// Should be run in `FixedUpdate` before movement logic.
pub fn update_jump_and_fall_timers(
    mut query: Query<(&mut JustJumped, &mut FallTimer, &crate::game::player::movement::core::CharacterVelocity, &crate::game::player::movement::core::Grounded), With<crate::game::player::Player>>,
    time: Res<Time>,
) {
    for (mut just_jumped, mut fall_timer, _velocity, grounded) in query.iter_mut() {
        if just_jumped.timer < f32::MAX {
            just_jumped.timer += time.delta_secs();
        }
        if grounded.0 {
            fall_timer.timer = 0.0;
        } else {
            fall_timer.timer += time.delta_secs();
        }
    }
}

/// Copies the current `FallTimer` value into `PreviousFallTimer` for all players.
///
/// Used to detect landing events and for effects that depend on fall duration.
pub fn update_previous_fall_timer(
    mut query: Query<(&FallTimer, &mut PreviousFallTimer), With<crate::game::player::Player>>,
) {
    for (fall_timer, mut prev) in query.iter_mut() {
        prev.timer = fall_timer.timer;
    }
}
