WITH UserBadgeCounts AS (
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
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.QuestionsCount, 0) AS QuestionsCount,
        COALESCE(ps.AnswersCount, 0) AS AnswersCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        ps.LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserPostStats ps ON u.Id = ps.OwnerUserId
), 
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalScore DESC, TotalViews DESC) AS Rank
    FROM 
        TopUsers
)
SELECT 
    u.Rank,
    u.DisplayName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.QuestionsCount,
    u.AnswersCount,
    u.TotalViews,
    u.TotalScore,
    u.LastPostDate
FROM 
    RankedUsers u
WHERE 
    u.Rank <= 10 
    AND u.TotalViews IS NOT NULL
    AND u.LastPostDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    u.Rank;