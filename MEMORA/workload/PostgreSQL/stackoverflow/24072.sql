WITH BadgesSummary AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS PositiveScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
UserVotingStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Votes v
    GROUP BY v.UserId
),
CombinedResults AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        bs.GoldBadges,
        bs.SilverBadges,
        bs.BronzeBadges,
        pa.PostCount,
        pa.TotalViews,
        pa.PositiveScore,
        uv.TotalUpVotes,
        uv.TotalDownVotes,
        GREATEST(
            COALESCE(bs.TotalBadges, 0), 
            COALESCE(pa.PostCount, 0), 
            COALESCE(uv.TotalUpVotes, 0) - COALESCE(uv.TotalDownVotes, 0)
        ) AS PerformanceMetric
    FROM Users u
    LEFT JOIN BadgesSummary bs ON u.Id = bs.UserId
    LEFT JOIN PostActivity pa ON u.Id = pa.OwnerUserId
    LEFT JOIN UserVotingStats uv ON u.Id = uv.UserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalViews,
    PositiveScore,
    TotalUpVotes,
    TotalDownVotes,
    PerformanceMetric
FROM CombinedResults
WHERE PerformanceMetric IS NOT NULL
ORDER BY PerformanceMetric DESC
LIMIT 10;