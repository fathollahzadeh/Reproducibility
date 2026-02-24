
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months' 
        AND ph.PostHistoryTypeId IN (10, 11, 12) 
),
LatestPostComments AS (
    SELECT 
        c.PostId,
        MAX(c.CreationDate) AS LatestCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.PostTypeId,
        COALESCE(lp.LatestCommentDate, '1970-01-01') AS LatestCommentDate,
        RANK() OVER (ORDER BY p.Score DESC, lp.LatestCommentDate DESC) AS PopularityRank
    FROM 
        RankedPosts p
    LEFT JOIN 
        LatestPostComments lp ON p.PostId = lp.PostId
    WHERE 
        p.Rank <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.PopularityRank,
    ur.Reputation,
    ub.BadgeCount,
    COALESCE(FPH.Comment, 'No recent history') AS RecentHistoryComment,
    FPH.CreationDate AS HistoryDate,
    CASE 
        WHEN pp.PopularityRank < 3 THEN 'Low Popularity'
        WHEN pp.PopularityRank BETWEEN 3 AND 5 THEN 'Medium Popularity'
        ELSE 'High Popularity'
    END AS PopularityStatus
FROM 
    PostDetails pp
LEFT JOIN 
    UserReputation ur ON pp.PostId IN (SELECT ParentId FROM Posts WHERE Id = pp.PostId)
LEFT JOIN 
    UserBadges ub ON ur.UserId = ub.UserId
LEFT JOIN 
    FilteredPostHistory FPH ON pp.PostId = FPH.PostId 
WHERE 
    pp.Score < (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
ORDER BY 
    pp.PopularityRank, ur.Reputation DESC;
