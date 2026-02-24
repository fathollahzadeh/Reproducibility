WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate, u.DisplayName
),
PostsStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostsStatistics ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    up.TotalScore,
    up.AvgViewCount,
    up.BadgeCount,
    STRING_AGG(CASE 
        WHEN up.GoldBadges > 0 THEN 'Gold'
        WHEN up.SilverBadges > 0 THEN 'Silver'
        WHEN up.BronzeBadges > 0 THEN 'Bronze'
        ELSE NULL END, ', ') AS BadgeTypes
FROM 
    UserPerformance up
WHERE 
    up.Reputation IS NOT NULL
    AND up.PostCount > (SELECT AVG(PostCount) FROM PostsStatistics)
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, up.PostCount, up.QuestionCount, 
    up.AnswerCount, up.TotalScore, up.AvgViewCount, up.BadgeCount
ORDER BY 
    up.Reputation DESC, up.TotalScore DESC, up.PostCount DESC
FETCH FIRST 10 ROWS ONLY;