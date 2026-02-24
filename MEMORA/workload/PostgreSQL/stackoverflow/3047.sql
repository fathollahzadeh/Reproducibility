WITH UserBadges AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionsAsked,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswersGiven,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.QuestionsAsked, 0) AS QuestionsAsked,
        COALESCE(ps.AnswersGiven, 0) AS AnswersGiven,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.CommentCount, 0) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    um.QuestionsAsked,
    um.AnswersGiven,
    um.TotalScore,
    um.CommentCount,
    CASE 
        WHEN um.TotalScore > 1000 THEN 'High Contributor'
        WHEN um.TotalScore BETWEEN 500 AND 1000 THEN 'Medium Contributor'
        ELSE 'Low Contributor'
    END AS ContributionLevel
FROM 
    UserMetrics um
WHERE 
    um.TotalScore IS NOT NULL
ORDER BY 
    um.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;
