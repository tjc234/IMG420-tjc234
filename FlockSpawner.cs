using Godot;
using System;

public partial class FlockSpawner : Node2D
{
	[Export] public PackedScene BoidScene;
	[Export] public int Count = 40;
	[Export] public Rect2 SpawnRect = new Rect2(-100, -100, 200, 200);
	[Export] public Rect2 WorldBounds = new Rect2(0, 0, 480, 720);

	public override void _Ready()
	{
		// Default world bounds to window size
		WorldBounds = new Rect2(Vector2.Zero, DisplayServer.WindowGetSize());

		// Spawn initial flock
		GD.Print(">>> FlockSpawner READY @ ", GetPath());
		if (BoidScene == null)
		{
			GD.PushWarning(">>> BoidScene not assigned.");
			return;
		}
		Spawn();
	}

// Spawn the boids
public void Spawn()
	{
		GD.Print(">>> Spawn() CALLED");
		if (BoidScene == null) { GD.PushError(">>> BoidScene is NULL"); return; }

		var inst = BoidScene.Instantiate();
		GD.Print(">>> Instantiated type = ", inst?.GetType().FullName ?? "null");

		// Make sure the scene root is a Boid2D
		var boid = inst as Boid2D;
		if (boid == null) { GD.PushError(">>> BoidScene root is NOT Boid2D"); return; }

		// Clear existing boids
		RemoveChild(inst); 
		for (int i = 0; i < Count; i++) // Spawn boids in random positions within spawn rect
		{
			var b = (Boid2D)BoidScene.Instantiate();
			b.Position = GlobalPosition + new Vector2(
				(float)GD.RandRange(SpawnRect.Position.X, SpawnRect.End.X),
				(float)GD.RandRange(SpawnRect.Position.Y, SpawnRect.End.Y)
			);
			b.WorldBounds = WorldBounds;
			AddChild(b);
			FlockManager.Instance?.Register(b);
		}
		GD.Print($">>> Spawned {Count} boids.");
	}

	// Despawn all boids
	public void DespawnAll()
	{
		foreach (var child in GetChildren())
		{
			if (child is Boid2D b)
				b.QueueFree();
		}
	}
}
