WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS INT), 0) AS UpVotes,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS INT), 0) AS DownVotes,
        b.Name AS BadgeName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Class = 1
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, b.Name
),
RankedPosts AS (
    SELECT 
        ps.*,
        COUNT(*) OVER (PARTITION BY ps.UserPostRank) AS TotalPostsByUser
    FROM 
        PostStats ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.BadgeName,
    rp.UserPostRank,
    rp.TotalPostsByUser
FROM 
    RankedPosts rp
WHERE 
    (rp.Score > 10 OR rp.UpVotes > 5)
    AND NOT EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = rp.PostId AND c.Score < 0
    )
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 100;