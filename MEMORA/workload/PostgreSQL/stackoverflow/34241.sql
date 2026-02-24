WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.CreationDate,
        u.LastAccessDate,
        0 AS TotalPosts,
        0 AS TotalVotes,
        0 AS UserLevel
    FROM Users u
    WHERE u.Id IS NOT NULL
    UNION ALL
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalVotes,
        CASE 
            WHEN COUNT(p.Id) > 50 THEN 3 
            WHEN COUNT(p.Id) > 20 THEN 2 
            ELSE 1 
        END AS UserLevel
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views, u.CreationDate, u.LastAccessDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM Posts p
),
EngagementStats AS (
    SELECT 
        pd.*,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(ub.BadgeNames, 'No badges') AS UserBadges,
        pd.ViewCount * 1.0 / NULLIF(pd.CommentCount, 0) AS ViewPerComment,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.Score DESC) AS PostRank
    FROM PostDetails pd
    JOIN RecursiveUserStats us ON pd.OwnerUserId = us.UserId
    LEFT JOIN UserBadges ub ON us.UserId = ub.UserId
),
AggregatedData AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore,
        MAX(ViewPerComment) AS MaxViewPerComment,
        MIN(PostRank) AS BestPostRank
    FROM EngagementStats
    GROUP BY OwnerDisplayName
)
SELECT 
    ad.OwnerDisplayName,
    ad.TotalPosts,
    ad.TotalViews,
    ad.TotalScore,
    ad.MaxViewPerComment,
    ad.BestPostRank,
    CASE 
        WHEN ad.TotalPosts >= 100 THEN 'Expert' 
        WHEN ad.TotalPosts >= 50 THEN 'Veteran' 
        ELSE 'Novice' 
    END AS UserExperienceLevel
FROM AggregatedData ad
ORDER BY ad.TotalScore DESC, ad.TotalViews ASC;