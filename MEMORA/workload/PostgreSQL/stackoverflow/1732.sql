WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVoteCount
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.DisplayName,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(uv.UpvoteCount, 0) AS Upvotes,
    COALESCE(uv.DownvoteCount, 0) AS Downvotes,
    CASE 
        WHEN uf.UserPostRank = 1 THEN 'Most Recent Post'
        WHEN uf.UserPostRank < 5 THEN 'Top 5 Posts'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    Users u
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserVoteCounts uv ON uv.UserId = u.Id
LEFT JOIN 
    (SELECT DISTINCT ownerUserId, UserPostRank FROM RankedPosts) uf ON uf.OwnerUserId = p.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.DisplayName, p.CreationDate DESC;