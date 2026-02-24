
WITH RecursiveUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation,
        uv.TotalVotes,
        uv.UpVotes,
        uv.DownVotes,
        RANK() OVER (ORDER BY uv.TotalVotes DESC) AS Rank
    FROM Users u
    JOIN RecursiveUserVotes uv ON u.Id = uv.UserId
    WHERE u.Reputation > 1000
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(com.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COALESCE(p.ClosedDate, DATE '9999-12-31') AS ClosedDate 
    FROM Posts p
    LEFT JOIN Comments com ON p.Id = com.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score
),
ClosedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.CommentCount,
        ps.TotalUpvotes,
        ps.TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY ps.ClosedDate ORDER BY ps.Score DESC) AS Rank
    FROM PostStats ps
    WHERE ps.ClosedDate < TIMESTAMP '2024-10-01 12:34:56'
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    cp.Title,
    cp.Score,
    cp.CommentCount,
    cp.TotalUpvotes,
    cp.TotalDownvotes,
    CASE 
        WHEN cp.Score >= 10 THEN 'High Scorer'
        WHEN cp.Score BETWEEN 5 AND 9 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM ClosedPosts cp
INNER JOIN TopUsers tu ON cp.Rank <= 10
ORDER BY tu.Rank, cp.Score DESC;
