
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS RecentPostCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.Reputation,
    um.PostCount,
    um.QuestionCount,
    um.AnswerCount,
    um.UpvoteCount,
    um.DownvoteCount,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    rpm.RecentPostCount,
    rpm.LastPostDate
FROM 
    UserMetrics um
LEFT JOIN 
    RecentPostMetrics rpm ON um.UserId = rpm.OwnerUserId
WHERE 
    um.Reputation > 1000
ORDER BY 
    um.Reputation DESC, 
    rpm.LastPostDate DESC
LIMIT 50;
