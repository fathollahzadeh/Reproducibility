WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months')
    GROUP BY 
        b.UserId
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.BadgeCount, 0) AS RecentBadges,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(v.VoteAmount, 0)) AS AverageVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS VoteAmount 
         FROM 
            Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
    GROUP BY 
        u.Id, u.DisplayName, rb.BadgeCount
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.RecentBadges,
    us.TotalViews,
    us.TotalScore,
    us.AverageVotes,
    COUNT(DISTINCT r.PostId) AS NumberOfQuestions,
    MAX(r.CreationDate) AS LastPostDate
FROM 
    AggregatedUserStats us
LEFT JOIN 
    RankedPosts r ON us.UserId = r.OwnerUserId
GROUP BY 
    us.UserId, us.DisplayName, us.RecentBadges, us.TotalViews, us.TotalScore, us.AverageVotes
HAVING 
    COUNT(DISTINCT r.PostId) > 5 
ORDER BY 
    us.TotalViews DESC, us.TotalScore DESC;