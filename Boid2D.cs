using Godot;
using System;
using System.Collections.Generic;

public partial class Boid2D : Node2D
{
	// Set up paramters for manipulation in editor
	[Export] public float MaxSpeed = 160f;
	[Export] public float MaxForce = 220f;
	[Export] public float NeighborRadius = 100f;
	[Export] public float SeparationRadius = 55f;

	[Export] public float WeightSeparation = 1.8f;
	[Export] public float WeightAlignment  = 1.0f;
	[Export] public float WeightCohesion   = 0.9f;

	[Export] public Rect2 WorldBounds = new Rect2(-9999, -9999, 19999, 19999);
	[Export] public float BoundsPadding = 64f;
	[Export] public float BoundsForce = 200f;


	public Vector2? TargetPoint = null;
	public Node2D TargetNode = null;
	public float TargetWeight = 1.5f;

	public Vector2 Velocity;
	private Vector2 _accel;


	public override void _EnterTree()
	{
		// Register with the flock manager
		FlockManager.Instance?.Register(this);
	}

	public override void _ExitTree()
	{
		// Make sure to unregister from the flock manager
		FlockManager.Instance?.Unregister(this);
	}

	public override void _Ready()
	{
		// Random initial velocity
		var rng = GD.RandRange(0, Mathf.Tau);
		Velocity = new Vector2(Mathf.Cos((float)rng), Mathf.Sign((float)Math.Sin(rng))) * (MaxSpeed * 0.5f);

		// Put boid in mob group
		AddToGroup("mobs");
		// Set up our area for neighbor detection
		var a = GetNodeOrNull<Area2D>("Area2D");
		if (a != null)
		{
			a.Monitoring = true;
			a.Monitorable = true;

			a.AddToGroup("mobs");

			// Set collision
			a.CollisionLayer = 1 << 1;
			a.CollisionMask  = 1 << 0;
		}
	}


	public override void _PhysicsProcess(double delta)
	{
		float dt = (float)delta;
		var flock = FlockManager.Instance;
		if (flock == null) return;

		// set up flocking
		List<Boid2D> neighbors = flock.GetNeighbors(this, Position, NeighborRadius);
		Vector2 sep = Separation(neighbors) * WeightSeparation; 
		Vector2 ali = Alignment(neighbors)  * WeightAlignment;
		Vector2 coh = Cohesion(neighbors)   * WeightCohesion;

		_accel = sep + ali + coh;

		// Setup chasing target
		if (TargetNode != null) 
			_accel += Seek(TargetNode.GlobalPosition) * TargetWeight;
		else if (TargetPoint.HasValue)
			_accel += Seek(TargetPoint.Value) * TargetWeight;

		// Stay in bounds
		_accel += BoundsSteer() * (BoundsForce / MathF.Max(MaxSpeed, 1f));

		//  Determine new velocity
		Velocity += _accel * dt;
		if (Velocity.LengthSquared() > MaxSpeed * MaxSpeed)
			Velocity = Velocity.Normalized() * MaxSpeed;

		Position += Velocity * dt;
		if (Velocity.LengthSquared() > 1f)
			Rotation = Velocity.Angle();
	}

	private Vector2 Separation(List<Boid2D> neighbors)
	{
		Vector2 steer = Vector2.Zero;
		int count = 0;
		float sepR2 = SeparationRadius * SeparationRadius;

		// For every nearby boid, calculate a vector away from it
		foreach (var other in neighbors)
		{
			if (other == this) continue;
			Vector2 diff = Position - other.Position;
			float d2 = diff.LengthSquared();
			if (d2 > 0f && d2 < sepR2)
			{
				// Weight by distance
				steer += diff / MathF.Max(d2, 0.0001f);
				count++;
			}
		}
		if (count > 0) steer /= count;

		if (steer == Vector2.Zero) return Vector2.Zero;
		steer = steer.Normalized() * MaxSpeed - Velocity;
		return steer.LimitLength(MaxForce);
	}

	private Vector2 Alignment(List<Boid2D> neighbors)
	{
		Vector2 avgVel = Vector2.Zero;
		int count = 0;
		foreach (var other in neighbors)
		{
			if (other == this) continue;
			avgVel += other.Velocity;
			count++;
		}
		if (count == 0) return Vector2.Zero;

		avgVel /= count;
		avgVel = avgVel.LimitLength(MaxSpeed);
		Vector2 steer = avgVel - Velocity;
		return steer.LimitLength(MaxForce);
	}

	private Vector2 Cohesion(List<Boid2D> neighbors)
	{
		Vector2 center = Vector2.Zero;
		int count = 0;
		foreach (var other in neighbors)
		{
			if (other == this) continue;
			center += other.Position;
			count++;
		}
		if (count == 0) return Vector2.Zero;

		center /= count;
		return Seek(center);
	}

	private Vector2 Seek(Vector2 target)
	{
		Vector2 desired = (target - Position);
		if (desired == Vector2.Zero) return Vector2.Zero;
		desired = desired.Normalized() * MaxSpeed;
		Vector2 steer = desired - Velocity;
		return steer.LimitLength(MaxForce);
	}

	private Vector2 BoundsSteer()
	{
		if (WorldBounds.Size == Vector2.Zero) return Vector2.Zero;

		Vector2 steer = Vector2.Zero;
		if (Position.X < WorldBounds.Position.X + BoundsPadding) steer.X = +1f;
		else if (Position.X > WorldBounds.End.X - BoundsPadding)  steer.X = -1f;

		if (Position.Y < WorldBounds.Position.Y + BoundsPadding) steer.Y = +1f;
		else if (Position.Y > WorldBounds.End.Y - BoundsPadding)  steer.Y = -1f;

		if (steer == Vector2.Zero) return Vector2.Zero;
		steer = steer.Normalized() * MaxSpeed - Velocity;
		return steer.LimitLength(MaxForce);
	}
}
