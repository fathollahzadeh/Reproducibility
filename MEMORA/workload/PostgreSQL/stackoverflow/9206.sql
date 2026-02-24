WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostAnalytics AS (
    SELECT 
        up.UserId,
        COUNT(DISTINCT tp.Id) AS PostCount,
        SUM(tp.Score) AS TotalScore,
        AVG(tp.ViewCount) AS AverageViews,
        MAX(tp.Score) AS MaxScore,
        SUM(tp.AnswerCount) AS TotalAnswers
    FROM 
        TopPosts tp
    JOIN 
        UserBadges up ON tp.OwnerUserId = up.UserId
    WHERE 
        tp.ScoreRank <= 5 
    GROUP BY 
        up.UserId
)
SELECT 
    u.DisplayName,
    ua.BadgeCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    pa.PostCount,
    pa.TotalScore,
    pa.AverageViews,
    pa.MaxScore,
    pa.TotalAnswers
FROM 
    Users u
JOIN 
    UserBadges ua ON u.Id = ua.UserId
JOIN 
    PostAnalytics pa ON u.Id = pa.UserId
WHERE 
    ua.BadgeCount > 0 
ORDER BY 
    pa.TotalScore DESC, 
    u.Reputation DESC;