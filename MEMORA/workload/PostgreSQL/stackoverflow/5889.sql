
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(link.RelatedPostCount, 0) AS RelatedPostCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS RelatedPostCount
        FROM PostLinks
        GROUP BY PostId
    ) link ON p.Id = link.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.TotalBounty,
        us.BadgeCount,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.RelatedPostCount,
        ps.CommentCount
    FROM UserStats us
    JOIN PostStats ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalBounty,
    BadgeCount,
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    RelatedPostCount,
    CommentCount
FROM FinalStats
ORDER BY Reputation DESC, PostCount DESC, Score DESC
LIMIT 100;
