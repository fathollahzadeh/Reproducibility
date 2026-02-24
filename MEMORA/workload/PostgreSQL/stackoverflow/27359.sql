
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
UserScore AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.UpVotes,
        ua.DownVotes,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        ua.CommentCount,
        (ua.UpVotes - ua.DownVotes) AS VoteScore,
        (ua.QuestionCount * 2 + ua.AnswerCount + ua.GoldBadges * 10 + ua.SilverBadges * 5 + ua.BronzeBadges * 2 + ua.CommentCount * 0.5) AS PrestigeScore
    FROM 
        UserActivity ua
),
Ranking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PrestigeScore DESC) AS Rank
    FROM 
        UserScore
)

SELECT 
    r.Rank,
    r.DisplayName,
    r.PostCount,
    r.QuestionCount,
    r.AnswerCount,
    r.UpVotes,
    r.DownVotes,
    r.GoldBadges,
    r.SilverBadges,
    r.BronzeBadges,
    r.CommentCount,
    r.VoteScore,
    r.PrestigeScore
FROM 
    Ranking r
WHERE 
    r.Rank <= 10 
ORDER BY 
    r.Rank;
