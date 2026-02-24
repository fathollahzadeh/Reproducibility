WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopUserPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        PostId
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    COALESCE(vc.Upvotes, 0) AS TotalUpvotes,
    COALESCE(vc.Downvotes, 0) AS TotalDownvotes,
    (COALESCE(vc.Upvotes, 0) - COALESCE(vc.Downvotes, 0)) AS NetVotes
FROM 
    TopUserPosts t
LEFT JOIN 
    VoteCounts vc ON t.PostId = vc.PostId
ORDER BY 
    t.OwnerDisplayName, t.Score DESC;