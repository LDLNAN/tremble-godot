//! Core movement types, constants, and systems
use avian3d::debug_render::{PhysicsGizmos, PhysicsGizmoExt};
use avian3d::prelude::*;
use bevy::prelude::*;
use serde::{Deserialize, Serialize};
pub use crate::game::util::{print_parent_chain, sanity_check_transforms};

/// Marker component indicating whether the player is grounded.
///
/// `Grounded(true)` means the player is on the ground; `Grounded(false)` means airborne.
#[derive(Component, Debug, Clone, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct Grounded(pub bool);

/// Resource containing all movement configuration parameters for the player.
///
/// Used as a Bevy resource and can be loaded from a RON config file.
#[derive(Resource, Reflect, Serialize, Deserialize, Clone, Debug)]
#[reflect(Resource)]
pub struct MovementConfig {
    /// Maximum player speed (units/sec).
    pub speed: f32,
    /// Acceleration when on ground (units/sec^2).
    pub ground_accelerate: f32,
    /// Acceleration when in air (units/sec^2).
    pub air_accelerate: f32,
    /// Friction applied when on ground.
    pub friction: f32,
    /// Upward velocity applied when jumping.
    pub jump_power: f32,
    /// Downward acceleration due to gravity.
    pub gravity: f32,
    /// Maximum speed for climbing steps.
    pub step_climb_speed: f32,
    /// Multiplier for step speed when climbing.
    pub step_speed_multiplier: f32,
    /// Minimum speed for step climbing.
    pub min_step_speed: f32,
}
impl Default for MovementConfig {
    fn default() -> Self {
        Self {
            speed: 7.0,
            ground_accelerate: 10.0,
            air_accelerate: 1.0,
            friction: 6.0,
            jump_power: 5.0,
            gravity: 9.81,
            step_climb_speed: 1.5,
            step_speed_multiplier: 0.3,
            min_step_speed: 1.0,
        }
    }
}

/// Player velocity (in world space).
///
/// The inner `Vec3` represents the player's current velocity in world coordinates.
#[derive(Component, Debug, Clone, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct CharacterVelocity(pub Vec3);

/// Sticky wish direction for air control.
///
/// Stores the last intended movement direction while airborne for air control logic.
#[derive(Component, Default, Reflect, serde::Serialize, serde::Deserialize)]
#[reflect(Component)]
pub struct StickyWishDir(pub Vec3);

/// Accumulated velocity for the current frame.
#[derive(Component, Default, Reflect, serde::Serialize, serde::Deserialize)]
#[reflect(Component)]
pub struct TotalVelocity(pub Vec3);

// Player body/collider constants
/// Player capsule height (meters).
/// Used for all collision and cast calculations.
pub const PLAYER_HEIGHT: f32 = 1.85;
/// Player capsule radius (meters).
/// Used for all collision and cast calculations.
pub const BODY_RADIUS: f32 = 0.42;
/// Half-height of ground cast cylinder (meters).
/// Used for ground detection raycasts.
pub const GROUND_CAST_HALF_HEIGHT: f32 = 0.01;
/// Maximum step height (meters).
/// The maximum vertical distance the player can step up.
pub const MAX_STEP_HEIGHT: f32 = 0.55;
/// Half-height of player body (meters).
/// Used for capsule collider calculations.
pub const BODY_HALF_HEIGHT: f32 = (PLAYER_HEIGHT - MAX_STEP_HEIGHT - GROUND_CAST_HALF_HEIGHT) * 0.5;
/// Full height of player body (meters).
/// Used for capsule collider calculations.
pub const BODY_FULL_HEIGHT: f32 = BODY_HALF_HEIGHT * 2.0;
/// Radius of ground cast cylinder (meters).
/// Used for ground detection raycasts.
pub const GROUND_CAST_RADIUS: f32 = BODY_RADIUS * 0.9;
/// Extended step height (meters).
/// Slightly shorter than the maximum step height, used for extended collider.
pub const EXTENDED_STEP_HEIGHT: f32 = MAX_STEP_HEIGHT * 0.95;
/// Extended full height of player body (meters).
/// Slightly taller than the regular body height, used for extended collider.
pub const EXTENDED_BODY_FULL_HEIGHT: f32 = BODY_FULL_HEIGHT + EXTENDED_STEP_HEIGHT;

/// Main player movement system. Handles input, friction, acceleration, and jumping.
///
/// - Reads input from NetworkedPlayerInput and updates velocity based on ground/air state.
/// - Applies friction and acceleration.
/// - Handles jump input and sets vertical velocity.
///
/// Should be run in `FixedUpdate`.
pub fn movement(
    mut query: Query<(
        &mut CharacterVelocity,
        &crate::game::player::input::NetworkedPlayerInput,
        &mut Grounded,
        Option<&mut StickyWishDir>,
        Option<&mut crate::game::player::movement::jump::JustJumped>,
        Option<&mut TotalVelocity>,
        Entity,
    ), With<crate::game::player::Player>>,
    mut commands: Commands,
    config: Res<MovementConfig>,
    time: Res<Time>,
) {
    let Ok((mut velocity, networked_input, mut grounded, sticky_wish_dir, mut just_jumped, total_velocity, entity)) = query.get_single_mut() else {
        return;
    };

    // Read movement input from networked input component instead of ActionState
    let wish_vel = Vec3::new(networked_input.movement_direction.x, 0.0, -networked_input.movement_direction.y).normalize_or_zero();
    // Use networked yaw rotation for consistent movement direction calculation across clients
    let wish_dir = (Quat::from_rotation_y(networked_input.yaw_rotation) * wish_vel).normalize_or_zero();
    let wish_speed = networked_input.movement_magnitude * config.speed;

    // Sticky wish_dir logic
    if wish_dir.length_squared() > 0.001 {
        if let Some(mut sticky) = sticky_wish_dir {
            sticky.0 = wish_dir;
        } else {
            commands.entity(entity).insert(StickyWishDir(wish_dir));
        }
    }

    // Instead of directly modifying velocity.0, accumulate into total_velocity
    let mut frame_delta = Vec3::ZERO;
    if grounded.0 {
        apply_friction(&mut velocity.0, &config, &time);
        accelerate(
            &mut velocity.0,
            wish_dir,
            wish_speed,
            config.ground_accelerate,
            &time,
        );
    } else {
        accelerate(
            &mut velocity.0,
            wish_dir,
            wish_speed,
            config.air_accelerate,
            &time,
        );
    }
    // Read jump input from networked input component instead of ActionState
    if networked_input.jump_pressed && grounded.0 {
        velocity.0.y = config.jump_power;
        grounded.0 = false; // Immediately become ungrounded when jumping
        // Reset JustJumped timer on jump
        if let Some(jj) = just_jumped.as_deref_mut() {
            jj.timer = 0.0;
        }
    }
    frame_delta += velocity.0;
    if let Some(mut total) = total_velocity {
        total.0 += frame_delta;
    } else {
        commands.entity(entity).insert(TotalVelocity(frame_delta));
    }
}

/// Kinematic movement system for the player. Applies gravity, handles ground/step detection, and collision response.
///
/// - Applies gravity if not grounded.
/// - Performs ground/step detection and normalization.
/// - Handles collision and sliding along surfaces.
///
/// Should be run in `FixedUpdate` after `movement`.
pub fn kinematic_movement(
    mut query: Query<
        (
            Entity,
            &mut Transform,
            &mut CharacterVelocity,
            &Children,
            &mut Grounded,
            Option<&crate::game::player::movement::jump::JustJumped>,
            Option<&crate::game::player::movement::jump::FallTimer>,
            Option<&crate::game::player::movement::jump::PreviousFallTimer>,
            Option<&mut TotalVelocity>,
        ),
        With<crate::game::player::Player>,
    >,
    spatial_query: SpatialQuery,
    time: Res<Time>,
    config: Res<MovementConfig>,
    mut gizmos: Gizmos<'_, '_, PhysicsGizmos>,
) {
    for (entity, mut transform, mut velocity, children, mut grounded, just_jumped, fall_timer, _, total_velocity) in query.iter_mut() {
        let mut frame_delta = Vec3::ZERO;
        apply_gravity(&mut velocity, &grounded, &config, &time);
        let ground_cast_distance = ground_and_step_normalization(
            entity,
            &mut transform,
            &mut velocity,
            &mut grounded,
            just_jumped,
            fall_timer,
            &spatial_query,
            &config,
            &time,
            &mut gizmos,
        );
        // Compute air_time for collision_and_slide
        let air_time = fall_timer.map_or(0.0, |f| f.timer);
        collision_and_slide(
            entity,
            &mut transform,
            &mut velocity,
            &children,
            &mut grounded,
            &spatial_query,
            &time,
            air_time,
            ground_cast_distance,
            &mut gizmos,
        );
        frame_delta += velocity.0;
        if let Some(mut total) = total_velocity {
            total.0 += frame_delta;
        }
    }
}

/// Applies gravity to the player if not grounded.
fn apply_gravity(velocity: &mut CharacterVelocity, grounded: &Grounded, config: &MovementConfig, time: &Time) {
    if !grounded.0 {
        velocity.0.y -= config.gravity * time.delta_secs();
    }
}

/// Handles ground detection and step normalization, including debug shape emission.
fn ground_and_step_normalization(
    entity: Entity,
    transform: &mut Transform,
    velocity: &mut CharacterVelocity,
    grounded: &mut Grounded,
    just_jumped: Option<&crate::game::player::movement::jump::JustJumped>,
    fall_timer: Option<&crate::game::player::movement::jump::FallTimer>,
    spatial_query: &SpatialQuery,
    config: &MovementConfig,
    time: &Time,
    gizmos: &mut Gizmos<'_, '_, PhysicsGizmos>,
) -> Option<f32> {
    // Use only the jump timer to determine if we should skip ground logic
    let just_jumped_active = just_jumped.map_or(false, |j| j.timer < 0.05); // Increased threshold for proper jump grace period
    let mut ground_cast_distance = None;
    if !just_jumped_active {
        if crate::game::player::movement::debug::is_debug_shape_casts() {
            let cast_start = transform.translation - Vec3::Y * (BODY_FULL_HEIGHT * 0.5);
            let cast_direction = Dir3::NEG_Y;
            let max_step_distance = MAX_STEP_HEIGHT * 2.0;
            let ground_shape = Collider::cylinder(GROUND_CAST_RADIUS, GROUND_CAST_HALF_HEIGHT);
            let filter = SpatialQueryFilter::from_excluded_entities(vec![entity]);
            let cast_config = ShapeCastConfig {
                max_distance: max_step_distance,
                ..Default::default()
            };
            let ground_hit = spatial_query.cast_shape(
                &ground_shape,
                cast_start,
                Quat::default(),
                cast_direction,
                &cast_config,
                &filter,
            );
            // Use Avian3D's built-in debug rendering
            gizmos.draw_shapecast(
                &ground_shape,
                cast_start,
                Quat::default(),
                cast_direction,
                max_step_distance,
                &[],
                Color::srgb(0.0, 1.0, 1.0), // ray_color
                Color::srgb(1.0, 1.0, 0.0), // shape_color
                Color::srgb(1.0, 0.0, 0.0), // point_color
                Color::srgb(0.0, 1.0, 0.0), // normal_color
                1.0,
            );
        }
    }
    // Movement logic
    if just_jumped_active {
        grounded.0 = false;
    } else {
        // Always compute the cast origin relative to the player body collider center.
        // The cast origin is the center of the player collider minus half the collider height on Y.
        // This ensures the ground cast is always aligned with the collider, regardless of state.
        let collider_center = transform.translation; // Assumes transform.translation is the collider center
        let cast_start = collider_center - Vec3::Y * (BODY_FULL_HEIGHT * 0.5);
        let cast_direction = Dir3::NEG_Y;
        let max_step_distance = MAX_STEP_HEIGHT * 2.0;
        let ground_shape = Collider::cylinder(GROUND_CAST_RADIUS, GROUND_CAST_HALF_HEIGHT);
        let filter = SpatialQueryFilter::from_excluded_entities(vec![entity]);
        let cast_config = ShapeCastConfig {
            max_distance: max_step_distance,
            ..Default::default()
        };
        let ground_hit = spatial_query.cast_shape(
            &ground_shape,
            cast_start,
            Quat::default(),
            cast_direction,
            &cast_config,
            &filter,
        );
        if let Some(hit) = &ground_hit {
            ground_cast_distance = Some(hit.distance);
            let diff = MAX_STEP_HEIGHT - hit.distance;
            let air_time = fall_timer.map_or(0.0, |f| f.timer);
            let base_landing_threshold = 0.015;
            let dynamic_landing_threshold = velocity.0.y.abs() * time.delta_secs() + base_landing_threshold;
            // --- FIX: Robust landing logic ---
            if hit.distance <= MAX_STEP_HEIGHT && air_time > 0.05 {
                // Snap player so ground cast distance is exactly MAX_STEP_HEIGHT
                let correction = cast_direction * (hit.distance - MAX_STEP_HEIGHT);
                transform.translation += correction;
                velocity.0.y = 0.0;
                grounded.0 = true;
            } else if air_time <= 0.01 && diff.abs() > 0.01 {
                // Only allow step smoothing if not falling
                let horizontal_speed = velocity.0.xz().length();
                let calculated_step_speed = config.step_climb_speed + (horizontal_speed * horizontal_speed * 0.07);
                let dynamic_step_speed = calculated_step_speed.max(config.min_step_speed);
                let max_step_delta = dynamic_step_speed * time.delta_secs();
                let movement_to_apply = if diff > 0.0 {
                    diff.min(max_step_delta)
                } else {
                    diff.max(-max_step_delta)
                };
                velocity.0.y = movement_to_apply / time.delta_secs();
            } else if diff.abs() <= 0.01 {
                velocity.0.y = 0.0;
                grounded.0 = true;
            }
        } else {
            // If no ground hit, grounded.0 should be true if ground_cast_distance is Some and <= MAX_STEP_HEIGHT
            if let Some(dist) = ground_cast_distance {
                grounded.0 = dist <= MAX_STEP_HEIGHT;
            } else {
                grounded.0 = false;
            }
        }
    }
    ground_cast_distance
}

/// Performs collision detection and sliding for the player capsule.
///
/// This function:
/// - Applies robust penetration correction (magenta debug shape when airborne, red when grounded).
/// - Performs a shape cast for collide-and-slide (yellow debug shape), using the same center and height as the collider.
/// - Ensures debug shapes and shape casts are visually and logically aligned in both grounded and airborne states.
/// - Prevents velocity snapping/zeroing when moving upward (only applies when falling).
/// - All debug shapes are offset by `-Vec3::Y * (cast_height * 0.5)` for correct mesh alignment.
///
/// # Parameters
/// - `entity`: The player entity.
/// - `transform`: The player's transform (mutated in-place).
/// - `velocity`: The player's velocity (mutated in-place).
/// - `children`: The player's child entities (for exclusion in collision).
/// - `grounded`: Whether the player is grounded (mutated in-place).
/// - `spatial_query`: The spatial query interface for collision.
/// - `time`: Time resource for delta time.
/// - `air_time`: Time spent airborne (used for airborne logic).
/// - `debug_shape_events`: Event writer for debug shape emission.
fn collision_and_slide(
    entity: Entity,
    transform: &mut Transform,
    velocity: &mut CharacterVelocity,
    children: &Children,
    grounded: &mut Grounded,
    spatial_query: &SpatialQuery,
    time: &Time,
    air_time: f32,
    ground_cast_distance: Option<f32>,
    gizmos: &mut Gizmos<'_, '_, PhysicsGizmos>,
) {
    // --- Begin robust collide-and-slide logic (reference-inspired) ---
    const EPSILON: f32 = 1e-5; // Increased for more robust overlap detection
    const MAX_COLLISION_ITERATIONS: u32 = 5;
    const PENETRATION_OFFSET: f32 = 0.002; // Smaller offset to reduce jitter
    let mut iterations = 0;
    let mut vel = velocity.0 * time.delta_secs();

    // Penetration correction (Linahan)
    let mut excluded_entities = vec![entity];
    excluded_entities.extend(children.iter());
    let filter = SpatialQueryFilter::from_excluded_entities(excluded_entities.clone());
    // Use the extended collider for penetration correction and debug shapes
    let use_extended_collider = should_use_extended_collider(air_time, grounded, velocity, ground_cast_distance);
    if crate::game::player::movement::debug::is_debug_shape_casts() {
        // Show the penetration correction collider (magenta if airborne, red if grounded)
        let (color, center, height) = if use_extended_collider {
            (
                Color::srgb(1.0, 0.0, 1.0),
                transform.translation - Vec3::Y * (EXTENDED_STEP_HEIGHT * 0.5),
                EXTENDED_BODY_FULL_HEIGHT,
            )
        } else {
            (
                Color::srgb(1.0, 0.0, 0.0),
                transform.translation,
                BODY_FULL_HEIGHT,
            )
        };
        let collider = Collider::cylinder(BODY_RADIUS, height);
        gizmos.draw_shapecast(
            &collider,
            center - Vec3::Y * (height * 0.5),
            Quat::default(),
            Dir3::Y,
            0.0,
            &[],
            color,
            Color::srgb(1.0, 1.0, 0.0),
            Color::srgb(1.0, 0.0, 0.0),
            Color::srgb(0.0, 1.0, 0.0),
            1.0,
        );
    }
    let (collider, collider_origin) = if use_extended_collider {
        (
            Collider::cylinder(BODY_RADIUS, EXTENDED_BODY_FULL_HEIGHT),
            transform.translation - Vec3::Y * (EXTENDED_STEP_HEIGHT * 0.5),
        )
    } else {
        (
            Collider::cylinder(BODY_RADIUS, BODY_FULL_HEIGHT),
            transform.translation,
        )
    };
    let contacts = spatial_query.shape_hits(
        &collider,
        collider_origin,
        transform.rotation,
        Dir3::NEG_Y,
        8, // max_results: u32 (was 0.0 for distance)
        &ShapeCastConfig { max_distance: 0.0, ..Default::default() },
        &filter,
    );
    if !contacts.is_empty() {
        let mut max_penetration = 0.0;
        let mut correction = Vec3::ZERO;
        for contact in &contacts {
            // avian3d 0.3.x: use contact.distance instead of time_of_impact
            if contact.distance < -EPSILON && -contact.distance > max_penetration {
                max_penetration = -contact.distance;
                correction = contact.normal2 * (max_penetration + PENETRATION_OFFSET);
            }
        }
        if max_penetration > EPSILON {
            transform.translation += correction;
        }
    }

    // Use the extended collider for collision/slide debug and shape casts
    let use_extended_collider = should_use_extended_collider(air_time, grounded, velocity, ground_cast_distance);
    while vel.length() > EPSILON && iterations < MAX_COLLISION_ITERATIONS {
        let direction = vel.normalize_or_zero();
        let distance = vel.length();
        if direction.length_squared() == 0.0 {
            break;
        }
        let filter = SpatialQueryFilter::from_excluded_entities(excluded_entities.clone());
        if crate::game::player::movement::debug::is_debug_shape_casts() {
            let (cast_origin, cast_height) = if use_extended_collider {
                (
                    transform.translation - Vec3::Y * (EXTENDED_STEP_HEIGHT * 0.5),
                    EXTENDED_BODY_FULL_HEIGHT,
                )
            } else {
                (
                    transform.translation,
                    BODY_FULL_HEIGHT,
                )
            };
            let cast_collider = Collider::cylinder(BODY_RADIUS, cast_height);
            gizmos.draw_shapecast(
                &cast_collider,
                cast_origin - Vec3::Y * (cast_height * 0.5),
                Quat::default(),
                Dir3::new_unchecked(direction),
                distance,
                &[],
                Color::srgb(0.0, 1.0, 1.0), // ray_color
                Color::srgb(1.0, 1.0, 0.0), // shape_color
                Color::srgb(1.0, 0.0, 0.0), // point_color
                Color::srgb(0.0, 1.0, 0.0), // normal_color
                1.0,
            );
        }
        let (cast_collider, cast_origin) = if use_extended_collider {
            (
                Collider::cylinder(BODY_RADIUS, EXTENDED_BODY_FULL_HEIGHT),
                transform.translation - Vec3::Y * (EXTENDED_STEP_HEIGHT * 0.5),
            )
        } else {
            (
                Collider::cylinder(BODY_RADIUS, BODY_FULL_HEIGHT),
                transform.translation,
            )
        };
        let hits = spatial_query.shape_hits(
            &cast_collider,
            cast_origin,
            transform.rotation,
            Dir3::new_unchecked(direction),
            8, // max_results: u32 (was distance * 1.1)
            &ShapeCastConfig { max_distance: distance * 1.1, ..Default::default() },
            &filter,
        );
        if !hits.is_empty() {
            // Treat all collisions as a perfectly flat, straight vertical wall (use the horizontal component of the average normal)
            let mut avg_normal = Vec3::ZERO;
            let mut min_dist = f32::MAX;
            let mut hit_count = 0;
            let mut collision_point = transform.translation;
            for hit in &hits {
                if hit.distance < min_dist && hit.distance >= 0.0 {
                    min_dist = hit.distance;
                    collision_point = transform.translation + direction * hit.distance;
                }
                avg_normal += hit.normal1;
                hit_count += 1;
            }
            // Flatten the normal: ignore Y, only use XZ (horizontal) component
            let mut flat_normal = if hit_count > 0 {
                let n = avg_normal / hit_count as f32;
                Vec3::new(n.x, 0.0, n.z).normalize_or_zero()
            } else {
                Vec3::new(direction.x, 0.0, direction.z).normalize_or_zero()
            };
            // If the flat normal is zero (e.g. running into a perfectly vertical wall), fallback to X+
            if flat_normal.length_squared() < EPSILON {
                flat_normal = Vec3::X;
            }
            let collision_time = min_dist / distance;
            if collision_time > 1.0 || collision_time < -EPSILON {
                transform.translation += vel;
                break;
            }
            transform.translation = collision_point + flat_normal * PENETRATION_OFFSET;
            let destination = transform.translation + vel * (1.0 - collision_time);
            let slide_distance = destination - transform.translation;
            // Project velocity onto the plane perpendicular to the (flattened) collision normal
            let slide_velocity = slide_distance - flat_normal * slide_distance.dot(flat_normal);
            let original_speed = vel.length();
            let slide_speed = slide_velocity.length();
            let slide_velocity = if slide_speed > EPSILON {
                slide_velocity * (original_speed / slide_speed).min(1.0)
            } else {
                Vec3::ZERO
            };
            // Quake 3–style velocity clipping: project velocity onto the plane perpendicular to the collision normal
            let collision_normal = if hit_count > 0 {
                (avg_normal / hit_count as f32).normalize_or_zero()
            } else {
                direction.normalize_or_zero()
            };
            let speed = velocity.0.dot(collision_normal);
            if speed < 0.0 {
                velocity.0 -= speed * collision_normal;
            }
            // Continue with slide logic as before
            vel = slide_velocity;
            if flat_normal.y > 0.7 && velocity.0.y < 0.0 {
                grounded.0 = true;
            }
            iterations += 1;
        } else {
            transform.translation += vel;
            break;
        }
    }
    // Clamp Y for safety
    if transform.translation.y < -100.0 { transform.translation.y = -100.0; }
    if transform.translation.y > 1000.0 { transform.translation.y = 1000.0; }
    assert!(transform.translation.is_finite(), "Player transform is not finite after movement: {:?}", transform.translation);
    assert!(velocity.0.is_finite(), "Player velocity is not finite after movement: {:?}", velocity.0);
    if grounded.0 {
        velocity.0.y = 0.0;
        let ground_y = (transform.translation.y / 0.01).round() * 0.01;
        if (transform.translation.y - ground_y).abs() < 0.02 {
            transform.translation.y = ground_y;
        }
    }
}

/// Accelerates the player velocity in the given wish direction.
///
/// # Parameters
/// - `velocity`: The player's velocity vector (mutated in-place).
/// - `wish_dir`: The desired movement direction (normalized).
/// - `wish_speed`: The desired speed in the wish direction.
/// - `accel`: Acceleration rate.
/// - `time`: Time resource for delta time.
pub fn accelerate(
    velocity: &mut Vec3,
    wish_dir: Vec3,
    wish_speed: f32,
    accel: f32,
    time: &Res<Time>,
) {
    let current_speed = velocity.dot(wish_dir);
    let add_speed = wish_speed - current_speed;

    if add_speed <= 0.0 {
        return;
    }

    let accel_speed = accel * wish_speed * time.delta_secs();
    let accel_speed = accel_speed.min(add_speed);

    velocity.x += accel_speed * wish_dir.x;
    velocity.z += accel_speed * wish_dir.z;
}

/// Applies friction to the player velocity when grounded.
///
/// # Parameters
/// - `velocity`: The player's velocity vector (mutated in-place).
/// - `config`: The movement configuration.
/// - `time`: Time resource for delta time.
pub fn apply_friction(
    velocity: &mut Vec3,
    config: &MovementConfig,
    time: &Res<Time>,
) {
    let speed = velocity.length();
    if speed <= 0.0 {
        return;
    }

    let drop = speed * config.friction * time.delta_secs();
    let new_speed = (speed - drop).max(0.0);

    if speed > 0.0 {
        let speed_ratio = new_speed / speed;
        velocity.x *= speed_ratio;
        velocity.z *= speed_ratio;
    }
}

/// Updates the WasGroundedLastFrame component for all players.
///
/// Copies the current grounded state into the `WasGroundedLastFrame` component for use in landing/jump logic.
pub fn update_was_grounded_last_frame(
    mut query: Query<(&Grounded, &mut crate::game::player::movement::plugin::WasGroundedLastFrame), With<crate::game::player::Player>>,
) {
    for (grounded, mut was_grounded) in query.iter_mut() {
        was_grounded.0 = grounded.0;
    }
}

/// Loads the movement config from a RON file at startup.
///
/// If the file exists and is valid, overwrites the default config resource.
/// Otherwise, logs a warning and uses the default config.
pub fn load_movement_config_from_ron(
    mut config_res: ResMut<MovementConfig>,
) {
    use std::path::Path;
    let path = "assets/configs/movement/default.ron";
    
    if Path::new(path).exists() {
        match crate::game::config::load_ron_config::<MovementConfig>(path) {
            Ok(cfg) => {
                *config_res = cfg;
                info!("Loaded MovementConfig from {}", path);
            },
            Err(e) => {
                warn!("{}", e);
                info!("Using default MovementConfig");
            },
        }
    } else {
        info!("No movement config file found at {}, using default.", path);
    }
}

/// System to apply the accumulated TotalVelocity to the player's transform or physics, then reset it.
pub fn apply_total_velocity(
    mut query: Query<(&mut Transform, &mut TotalVelocity, Option<&mut LinearVelocity>), With<crate::game::player::Player>>,
) {
    for (mut transform, mut total_velocity, linear_velocity) in query.iter_mut() {
        // If the player has a physics body, set its LinearVelocity from TotalVelocity
        if let Some(mut lv) = linear_velocity {
            *lv = LinearVelocity::from(total_velocity.0);
        } else {
            // For kinematic bodies, update the transform directly
            info!("NO LINEARVELOCITY");
            transform.translation += total_velocity.0;
        }
        total_velocity.0 = Vec3::ZERO;
    }
}

// Returns true if the player should use the extended collider for collision/slide and penetration correction.
// This is true if:
// - The player is airborne for a while (air_time > 0.2)
// - OR the player is not grounded and is moving downward (velocity.0.y < 0.0)
// - AND the ground cast is None or >= MAX_STEP_HEIGHT
fn should_use_extended_collider(
    air_time: f32,
    grounded: &Grounded,
    velocity: &CharacterVelocity,
    ground_cast_distance: Option<f32>,
) -> bool {
    // Only use extended collider if there is NO ground within step height, or the ground is farther than or equal to MAX_STEP_HEIGHT
    let airborne = (air_time > 0.15) && (!grounded.0);
    airborne
}

/// Position-based version of ground_and_step_normalization that works with Avian's Position component
fn ground_and_step_normalization_position(
    entity: Entity,
    position: &mut Position,
    velocity: &mut CharacterVelocity,
    grounded: &mut Grounded,
    just_jumped: Option<&crate::game::player::movement::jump::JustJumped>,
    fall_timer: Option<&crate::game::player::movement::jump::FallTimer>,
    spatial_query: &SpatialQuery,
    config: &MovementConfig,
    time: &Res<Time>,
    _gizmos: &mut Gizmos<'_, '_, PhysicsGizmos>,
) -> Option<f32> {
    // Ground detection using Position instead of Transform
    let ground_cast_origin = position.0 + Vec3::new(0.0, MAX_STEP_HEIGHT, 0.0);
    let ground_cast_direction = Dir3::NEG_Y;
    let ground_cast_distance = MAX_STEP_HEIGHT + GROUND_CAST_HALF_HEIGHT;
    
    let ground_collider = Collider::cylinder(GROUND_CAST_RADIUS, GROUND_CAST_HALF_HEIGHT);
    let filter = SpatialQueryFilter::default().with_excluded_entities([entity]);
    
    if let Some(ground_hit) = spatial_query.cast_shape(
        &ground_collider,
        ground_cast_origin,
        Quat::IDENTITY,
        ground_cast_direction,
        &ShapeCastConfig { max_distance: ground_cast_distance, ..Default::default() },
        &filter,
    ) {
        let ground_distance = ground_hit.distance;
        let ground_point = ground_cast_origin + ground_cast_direction.as_vec3() * ground_distance;
        let ground_normal = ground_hit.normal1;
        
        // Update grounded state
        if ground_distance <= MAX_STEP_HEIGHT && ground_normal.y > 0.7 {
            grounded.0 = true;
            
            // Step up logic using Position
            let target_y = ground_point.y + GROUND_CAST_HALF_HEIGHT;
            if position.0.y < target_y {
                position.0.y = target_y;
            }
            
            // Zero out downward velocity when grounded
            if velocity.0.y < 0.0 {
                velocity.0.y = 0.0;
            }
        } else {
            grounded.0 = false;
        }
        
        Some(ground_distance)
    } else {
        grounded.0 = false;
        None
    }
}

/// Position-based version of collision_and_slide that works with Avian's Position component
fn collision_and_slide_position(
    entity: Entity,
    position: &mut Position,
    velocity: &mut CharacterVelocity,
    _children: &Children,
    grounded: &mut Grounded,
    spatial_query: &SpatialQuery,
    time: &Res<Time>,
    air_time: f32,
    ground_cast_distance: Option<f32>,
    _gizmos: &mut Gizmos<'_, '_, PhysicsGizmos>,
) {
    const MAX_ITERATIONS: usize = 5;
    const EPSILON: f32 = 0.001;
    const PENETRATION_OFFSET: f32 = 0.002;

    let mut vel = velocity.0 * time.delta_secs();
    let mut iterations = 0;
    
    // Choose collider based on air time and ground distance
    let use_extended = should_use_extended_collider(air_time, grounded, velocity, ground_cast_distance);
    let collider = if use_extended {
        Collider::cylinder(BODY_RADIUS, EXTENDED_BODY_FULL_HEIGHT)
    } else {
        Collider::cylinder(BODY_RADIUS, BODY_FULL_HEIGHT)
    };
    
    let filter = SpatialQueryFilter::default().with_excluded_entities([entity]);

    while iterations < MAX_ITERATIONS && vel.length_squared() > EPSILON * EPSILON {
        let direction = vel.normalize_or_zero();
        let distance = vel.length();
        
        let cast_origin = position.0;
        
        let hits = spatial_query.shape_hits(
            &collider,
            cast_origin,
            Quat::IDENTITY,
            Dir3::new_unchecked(direction),
            8, // max_results
            &ShapeCastConfig { max_distance: distance * 1.1, ..Default::default() },
            &filter,
        );
        
        if !hits.is_empty() {
            // Process collision using Position instead of Transform
            let mut avg_normal = Vec3::ZERO;
            let mut min_dist = f32::MAX;
            let mut hit_count = 0;
            let mut collision_point = position.0;
            
            for hit in &hits {
                if hit.distance < min_dist && hit.distance >= 0.0 {
                    min_dist = hit.distance;
                    collision_point = position.0 + direction * hit.distance;
                }
                avg_normal += hit.normal1;
                hit_count += 1;
            }
            
            // Flatten the normal: ignore Y, only use XZ (horizontal) component
            let mut flat_normal = if hit_count > 0 {
                let n = avg_normal / hit_count as f32;
                Vec3::new(n.x, 0.0, n.z).normalize_or_zero()
            } else {
                Vec3::new(direction.x, 0.0, direction.z).normalize_or_zero()
            };
            
            if flat_normal.length_squared() < EPSILON {
                flat_normal = Vec3::X;
            }
            
            let collision_time = min_dist / distance;
            if collision_time > 1.0 || collision_time < -EPSILON {
                position.0 += vel;
                break;
            }
            
            position.0 = collision_point + flat_normal * PENETRATION_OFFSET;
            let destination = position.0 + vel * (1.0 - collision_time);
            let slide_distance = destination - position.0;
            
            // Project velocity onto the plane perpendicular to the (flattened) collision normal
            let slide_velocity = slide_distance - flat_normal * slide_distance.dot(flat_normal);
            let original_speed = vel.length();
            let slide_speed = slide_velocity.length();
            let slide_velocity = if slide_speed > EPSILON {
                slide_velocity * (original_speed / slide_speed).min(1.0)
            } else {
                Vec3::ZERO
            };
            
            // Quake 3–style velocity clipping
            let collision_normal = if hit_count > 0 {
                (avg_normal / hit_count as f32).normalize_or_zero()
            } else {
                direction.normalize_or_zero()
            };
            let speed = velocity.0.dot(collision_normal);
            if speed < 0.0 {
                velocity.0 -= speed * collision_normal;
            }
            
            vel = slide_velocity;
            if flat_normal.y > 0.7 && velocity.0.y < 0.0 {
                grounded.0 = true;
            }
            iterations += 1;
        } else {
            position.0 += vel;
            break;
        }
    }
    
    // Clamp Y for safety
    if position.0.y < -100.0 { position.0.y = -100.0; }
    if position.0.y > 1000.0 { position.0.y = 1000.0; }
    
    assert!(position.0.is_finite(), "Player position is not finite after movement: {:?}", position.0);
    assert!(velocity.0.is_finite(), "Player velocity is not finite after movement: {:?}", velocity.0);
    
    if grounded.0 {
        velocity.0.y = 0.0;
        let ground_y = (position.0.y / 0.01).round() * 0.01;
        if (position.0.y - ground_y).abs() < 0.02 {
            position.0.y = ground_y;
        }
    }
}