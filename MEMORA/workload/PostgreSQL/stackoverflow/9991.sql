
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.WikiCount,
        us.Upvotes,
        us.Downvotes,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeStats bs ON us.UserId = bs.UserId
)
SELECT 
    c.UserId,
    c.PostCount,
    c.QuestionCount,
    c.AnswerCount,
    c.WikiCount,
    c.Upvotes,
    c.Downvotes,
    c.BadgeCount,
    c.GoldBadges,
    c.SilverBadges,
    c.BronzeBadges,
    RANK() OVER (ORDER BY (c.Upvotes - c.Downvotes) DESC) AS UserRank
FROM 
    CombinedStats c
WHERE 
    c.PostCount > 0
ORDER BY 
    UserRank
FETCH FIRST 10 ROWS ONLY;
