
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 2000
),
UserPostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 10 THEN 1 ELSE 0 END) AS HighScoredPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    t.UserId,
    t.DisplayName,
    t.Reputation,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.HighScoredPosts, 0) AS TopScoredPosts,
    CASE 
        WHEN rp.AcceptedAnswerId <> -1 THEN 'Accepted Answer Exists' 
        ELSE 'No Accepted Answer' 
    END AS AcceptanceStatus
FROM 
    RecentPosts rp
JOIN 
    TopUsers t ON rp.RecentPostRank = 1
LEFT JOIN 
    UserPostCounts up ON t.UserId = up.OwnerUserId
WHERE 
    (rp.UpVotes - rp.DownVotes) > 0
    AND (rp.CommentCount > 5 OR rp.Score > 15)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
