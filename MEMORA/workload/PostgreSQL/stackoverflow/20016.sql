
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.ViewCount ELSE 0 END), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS TotalGoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS TotalSilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS TotalBronzeBadges,
        COUNT(DISTINCT v.Id) AS TotalVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalViews DESC, TotalQuestions DESC) AS ViewRank,
        DENSE_RANK() OVER (ORDER BY TotalGoldBadges DESC, TotalSilverBadges DESC) AS BadgeRank
    FROM 
        UserPostStats
),
TopUsers AS (
    SELECT 
        *,
        CASE 
            WHEN ViewRank <= 10 AND BadgeRank <= 5 THEN 'Top Contributor'
            WHEN ViewRank <= 25 THEN 'Active Contributor'
            ELSE 'Novice Contributor'
        END AS ContributorStatus
    FROM 
        RankedUsers
    WHERE 
        TotalQuestions > 0
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalQuestions,
    up.TotalAnswers,
    up.TotalViews,
    up.TotalGoldBadges,
    up.TotalSilverBadges,
    up.TotalBronzeBadges,
    up.ContributorStatus,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS TotalCloseReopenActions,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    TopUsers up
LEFT JOIN 
    Posts p ON up.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
GROUP BY 
    up.UserId, up.DisplayName, up.TotalQuestions, up.TotalAnswers, up.TotalViews, up.TotalGoldBadges, up.TotalSilverBadges, up.TotalBronzeBadges, up.ContributorStatus
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    up.TotalViews DESC
LIMIT 50;
