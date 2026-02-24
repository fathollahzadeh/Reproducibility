
WITH CTE_UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
CTE_BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CTE_PostHistory AS (
    SELECT 
        p.OwnerUserId,
        COUNT(ph.Id) AS TotalEdits,
        COUNT(DISTINCT ph.PostId) AS TotalEditedPosts,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        p.OwnerUserId
),
CTE_FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalScore,
        us.TotalCommentScore,
        COALESCE(bs.TotalBadges, 0) AS TotalBadges,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ph.TotalEdits, 0) AS TotalEdits,
        COALESCE(ph.TotalEditedPosts, 0) AS TotalEditedPosts,
        ph.LastEditDate
    FROM 
        CTE_UserStats us
    LEFT JOIN 
        CTE_BadgeStats bs ON us.UserId = bs.UserId
    LEFT JOIN 
        CTE_PostHistory ph ON us.UserId = ph.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalCommentScore,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalEdits,
    TotalEditedPosts,
    LastEditDate
FROM 
    CTE_FinalStats
WHERE 
    TotalPosts > 10
ORDER BY 
    TotalScore DESC, Reputation DESC;
