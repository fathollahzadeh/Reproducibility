
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
QuestionActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 3600) AS AvgHoursToFirstVote
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE p.PostTypeId = 1  
    GROUP BY p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        COALESCE(qa.CommentCount, 0) AS CommentCount,
        COALESCE(qa.VoteCount, 0) AS VoteCount,
        COALESCE(qa.AvgHoursToFirstVote, 0) AS AvgHoursToFirstVote,
        (us.GoldBadges + us.SilverBadges + us.BronzeBadges) AS TotalBadges
    FROM UserStatistics us
    LEFT JOIN QuestionActivity qa ON us.UserId = qa.OwnerUserId
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostCount DESC, AvgHoursToFirstVote ASC) AS Rank
    FROM UserPostStats
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.CommentCount,
    u.VoteCount,
    u.AvgHoursToFirstVote,
    u.TotalBadges
FROM RankedUsers u
WHERE 
    u.Rank <= 10 
    AND u.TotalBadges > (
        SELECT AVG(TotalBadges) FROM UserPostStats
    )
ORDER BY u.PostCount DESC;
