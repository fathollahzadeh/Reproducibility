WITH RankedPostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        Rank,
        TotalPosts,
        UserReputation
    FROM 
        RankedPostScores
    WHERE 
        Rank = 1
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.UserReputation,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = t.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 3) AS DownvoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = t.PostId) AS EditCount
FROM 
    TopRankedPosts t
ORDER BY 
    t.UserReputation DESC, t.Score DESC;