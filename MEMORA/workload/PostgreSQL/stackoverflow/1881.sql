WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score > 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)
SELECT 
    ue.DisplayName AS User,
    rp.Title AS RecentlyCreatedPost,
    rp.CreationDate AS PostDate,
    rp.Score AS PostScore,
    ue.TotalPosts,
    ue.TotalCommentScore,
    ue.TotalBadges,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    rv.LastVoteDate
FROM 
    RankedPosts rp
JOIN 
    UserEngagement ue ON rp.PostId = ue.UserId
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    ue.TotalPosts DESC, rv.LastVoteDate DESC NULLS LAST
LIMIT 50;