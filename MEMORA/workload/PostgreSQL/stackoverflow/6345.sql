
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.CreationDate,
        us.PostCount,
        us.AnswerCount,
        us.QuestionCount,
        us.CommentCount,
        us.UpvoteCount,
        us.DownvoteCount,
        COALESCE(bs.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(bs.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(bs.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeStats bs ON us.UserId = bs.UserId
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.CreationDate,
    f.PostCount,
    f.AnswerCount,
    f.QuestionCount,
    f.CommentCount,
    f.UpvoteCount,
    f.DownvoteCount,
    f.GoldBadgeCount,
    f.SilverBadgeCount,
    f.BronzeBadgeCount,
    RANK() OVER (ORDER BY f.Reputation DESC) AS ReputationRank
FROM 
    FinalStats f
ORDER BY 
    ReputationRank
FETCH FIRST 100 ROWS ONLY;
