
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.Location
),
PostsStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        ps.OwnerUserId, 
        ps.PostCount, 
        ps.QuestionCount, 
        ps.AnswerCount, 
        ps.TotalScore, 
        ps.AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS PostRank
    FROM 
        PostsStats ps
),
CombinedStats AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.Reputation, 
        us.BadgeCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.UserRank,
        rp.PostCount,
        rp.QuestionCount,
        rp.AnswerCount,
        rp.TotalScore,
        rp.AvgViewCount,
        COALESCE(rp.PostRank, 0) AS PostRank
    FROM 
        UserStats us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    cs.BadgeCount,
    CASE 
        WHEN cs.Reputation >= 1000 THEN 'Active User'
        WHEN cs.Reputation BETWEEN 500 AND 999 THEN 'Intermediate User'
        ELSE 'New User'
    END AS UserCategory,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    cs.UserRank,
    cs.PostCount,
    COALESCE(cs.QuestionCount, 0) AS QuestionCount,
    COALESCE(cs.AnswerCount, 0) AS AnswerCount,
    COALESCE(cs.TotalScore, 0) AS TotalScore,
    ROUND(COALESCE(cs.AvgViewCount, 0), 2) AS AvgViewCount,
    CASE 
        WHEN cs.PostRank = 0 AND cs.UserRank < 10 THEN NULL 
        ELSE cs.PostRank 
    END AS ValidPostRank
FROM 
    CombinedStats cs
WHERE 
    cs.Reputation IS NOT NULL
ORDER BY 
    cs.UserRank ASC, 
    cs.Reputation DESC;
