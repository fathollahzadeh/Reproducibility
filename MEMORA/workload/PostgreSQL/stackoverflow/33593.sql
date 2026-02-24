
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    
    UNION ALL
    
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.ParentId,
        ph.Depth + 1
    FROM 
        Posts p2
    INNER JOIN PostHierarchy ph ON p2.ParentId = ph.PostId
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
        COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN UserVoteCounts uv ON u.Id = uv.UserId
    WHERE 
        u.Reputation >= 100 
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ph.Depth,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHierarchy ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, u.DisplayName, ph.Depth
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    tu.Rank,
    tu.DisplayName AS TopUserName,
    tu.Reputation AS TopUserReputation
FROM 
    PostStats ps
LEFT JOIN TopUsers tu ON ps.OwnerDisplayName = tu.DisplayName
WHERE 
    ps.Depth = 0 
ORDER BY 
    ps.VoteCount DESC, 
    ps.UpVoteCount DESC, 
    ps.CommentCount DESC
LIMIT 10;
