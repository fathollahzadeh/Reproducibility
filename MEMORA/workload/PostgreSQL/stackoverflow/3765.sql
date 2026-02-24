WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeClass,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.AverageReputation,
        ur.TotalBadgeClass
    FROM 
        UserReputation ur
    WHERE 
        ur.AverageReputation > 1000 AND ur.TotalBadgeClass > 2
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(vs.VoteCount, 0) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId) c ON rp.PostId = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId) vs ON rp.PostId = vs.PostId
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    CASE 
        WHEN ps.ViewCount > 1000 THEN 'High Traffic'
        WHEN ps.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Traffic'
        ELSE 'Low Traffic' 
    END AS TrafficCategory,
    u.DisplayName
FROM 
    PostSummary ps
JOIN 
    Users u ON ps.PostId = u.Id
WHERE 
    EXISTS (
        SELECT 1
        FROM TopUsers tu
        WHERE tu.UserId = u.Id
    )
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;