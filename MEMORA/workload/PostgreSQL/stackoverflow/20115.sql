WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(vBounty.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vBounty ON p.Id = vBounty.PostId AND vBounty.VoteTypeId IN (8, 9)
    GROUP BY 
        u.Id
),

PostActivity AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),

ActiveUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        COALESCE(pa.HistoryCount, 0) AS ChangeCount,
        CASE 
            WHEN (p.ViewCount + COALESCE(pa.HistoryCount, 0)) > 200 THEN 'High Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostActivity pa ON p.Id = pa.PostId
    WHERE 
        u.Reputation > 1000 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '3 months' 
),

FinalReport AS (
    SELECT 
        a.UserId,
        a.DisplayName,
        a.PostId,
        a.Title,
        a.ChangeCount,
        a.EngagementLevel,
        r.ViewCount AS RecentViewCount,
        r.Score AS RecentScore
    FROM 
        ActiveUserPosts a
    JOIN 
        RankedPosts r ON a.PostId = r.PostId
    WHERE 
        r.Rank <= 5
)

SELECT 
    f.UserId,
    f.DisplayName,
    f.PostId,
    f.Title,
    f.ChangeCount,
    f.EngagementLevel,
    COALESCE(u.TotalBounty, 0) AS UserTotalBounty,
    COALESCE(u.TotalPosts, 0) AS UserTotalPosts,
    COALESCE(u.PositiveScoreCount, 0) AS UserPositiveScoreCount
FROM 
    FinalReport f
LEFT JOIN 
    UserActivity u ON f.UserId = u.UserId
ORDER BY 
    f.EngagementLevel DESC,
    f.ChangeCount DESC;