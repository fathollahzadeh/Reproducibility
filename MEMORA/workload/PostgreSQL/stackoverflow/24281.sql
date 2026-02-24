WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        
        RANK() OVER (ORDER BY u.Reputation DESC, u.CreationDate ASC) AS ReputationRank
    FROM
        Users u
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM
        Posts p
    GROUP BY
        p.OwnerUserId
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),
PostHistorySummary AS (
    SELECT
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedPosts,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenedPosts,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletedUndeletedPosts,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditsApplied
    FROM
        PostHistory ph
    GROUP BY
        ph.UserId
)
SELECT
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(phs.ClosedPosts, 0) AS ClosedPosts,
    COALESCE(phs.ReopenedPosts, 0) AS ReopenedPosts,
    COALESCE(phs.DeletedUndeletedPosts, 0) AS DeletedUndeletedPosts,
    COALESCE(phs.SuggestedEditsApplied, 0) AS SuggestedEditsApplied,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'No Activity'
        WHEN ur.Reputation < 50 THEN 'Newbie'
        WHEN ur.Reputation >= 50 AND ur.Reputation < 1000 THEN 'Contributor'
        WHEN ur.Reputation >= 1000 THEN 'Expert'
        ELSE 'Unknown'
    END AS UserStatus
FROM
    UserReputation ur
LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
LEFT JOIN PostHistorySummary phs ON ur.UserId = phs.UserId
WHERE
    ur.Reputation > 100 
    OR (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = ur.UserId) > 0
ORDER BY
    ur.Reputation DESC,
    ur.DisplayName ASC;