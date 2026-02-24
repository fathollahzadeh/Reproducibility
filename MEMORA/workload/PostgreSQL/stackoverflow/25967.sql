WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),

PostVoteSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ubc.BadgeCount,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    pvs.VoteCount,
    pvs.UpVotes,
    pvs.DownVotes,
    ps.PostCount,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.AvgScore,
    ps.LastPostDate
FROM 
    Users u
JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
JOIN 
    PostVoteSummary pvs ON u.Id = pvs.OwnerUserId
JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    u.DisplayName ASC;