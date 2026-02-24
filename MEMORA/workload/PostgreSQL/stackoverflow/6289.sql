
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopBadges AS (
    SELECT 
        b.UserId, 
        b.Name AS BadgeName, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Name
),
RankedBadges AS (
    SELECT 
        UserId, 
        BadgeName, 
        BadgeCount, 
        RANK() OVER (PARTITION BY UserId ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        TopBadges
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    rb.BadgeName,
    rb.BadgeCount
FROM 
    UserStats us
LEFT JOIN 
    RankedBadges rb ON us.UserId = rb.UserId AND rb.BadgeRank = 1
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
