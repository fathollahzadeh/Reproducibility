
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(c.Score) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate < '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
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
EngagementSummary AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalQuestions,
        ue.TotalAnswers,
        ue.TotalCommentScore,
        ue.VoteCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserEngagement ue
    LEFT JOIN 
        UserBadges ub ON ue.UserId = ub.UserId
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalCommentScore,
    VoteCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    RANK() OVER (ORDER BY TotalPosts DESC, TotalQuestions DESC, TotalAnswers DESC) AS EngagementRank
FROM 
    EngagementSummary
WHERE 
    TotalPosts > 0
ORDER BY 
    EngagementRank
FETCH FIRST 100 ROWS ONLY;
