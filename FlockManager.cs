using Godot;
using System;
using System.Collections.Generic;

public partial class FlockManager : Node
{
	public static FlockManager Instance { get; private set; }

	// Hash grid parameters
	[Export] public float CellSize = 120f;

	private readonly HashSet<Boid2D> _boids = new();
	private readonly Dictionary<(int,int), List<Boid2D>> _grid = new();

	public Node2D Player { get; private set; }

	// chasing state
	private bool _chasing = false;
	private float _chaseWeight = 1.5f;

	public override void _EnterTree()
	{
		Instance = this;
		GD.Print(">>> FlockManager ENTER_TREE @ ", GetPath());
	}

	// Make sure to clear static instance on exit
	public override void _ExitTree()
	{
		if (Instance == this) Instance = null;
	}

	// Register a boid with the flock manager
	public void Register(Boid2D b)
	{
		if (_boids.Add(b))
			b.TreeExiting += () => Unregister(b);
	}

   // Unregister a boid
	public void Unregister(Boid2D b) => _boids.Remove(b);

	// Update the spatial hash and apply chase target if needed
	public override void _PhysicsProcess(double delta)
	{
		RebuildGrid();

		if (_chasing && Player != null)
		{
			foreach (var b in _boids)
			{
				b.TargetNode = Player;
				b.TargetPoint = null;
				b.TargetWeight = _chaseWeight;
			}
		}
	}

	// Rebuild the spatial hash grid
	private void RebuildGrid()
	{
		// Clear and rebuild the grid
		_grid.Clear();
		float inv = 1f / MathF.Max(CellSize, 1f);
		foreach (var b in _boids)
		{
			//	 Add to grid
			var key = ToCell(b.Position, inv);
			if (!_grid.TryGetValue(key, out var list))
			{
				// New cell
				list = new List<Boid2D>();
				_grid[key] = list;
			}
			list.Add(b);
		}
	}

	// Convert position to cell coordinates
	private (int, int) ToCell(Vector2 pos, float inv)
		=> ((int)MathF.Floor(pos.X * inv), (int)MathF.Floor(pos.Y * inv));

	// Get neighbors within a certain radius using the spatial hash
	public List<Boid2D> GetNeighbors(Boid2D boid, Vector2 pos, float radius)
	{
		var result = new List<Boid2D>(32);
		float inv = 1f / MathF.Max(CellSize, 1f);
		var c = ToCell(pos, inv);
		int r = Math.Max(1, (int)MathF.Ceiling(radius / CellSize));

		for (int y = -r; y <= r; y++)
			for (int x = -r; x <= r; x++)
			{
				var key = (c.Item1 + x, c.Item2 + y);
				if (_grid.TryGetValue(key, out var bucket))
					result.AddRange(bucket);
			}
		return result;
	}

	// Chase helpers
	public void EnableAlwaysOnChase(float targetWeight = 1.5f)
	{
		_chasing = true;
		_chaseWeight = targetWeight;
	}

	public void StartChase(float seconds, float targetWeight = 1.5f)
	{
		if (Player == null) return;
		_chasing = true;
		_chaseWeight = targetWeight;
		var t = GetTree().CreateTimer(seconds);
		t.Timeout += StopChase;
	}

	public void StopChase()
	{
		_chasing = false;
		foreach (var b in _boids)
			b.TargetNode = null;
	}

	// Set the player node to chase
	public void SetPlayer(Node2D player) => Player = player;
}
