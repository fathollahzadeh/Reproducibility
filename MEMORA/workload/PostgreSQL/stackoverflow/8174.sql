
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(p.Score) AS ScoreTotal
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, pt.Name
),
UserActivity AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        ps.PostId,
        ps.Title AS PostTitle,
        ps.CreationDate AS PostCreationDate,
        ps.ViewCount AS PostViewCount,
        ps.Score AS PostScore,
        ps.CommentCount AS PostCommentCount,
        ps.Upvotes AS PostUpvotes,
        ps.Downvotes AS PostDownvotes
    FROM UserStats us
    JOIN Posts p ON us.UserId = p.OwnerUserId
    JOIN PostStats ps ON p.Id = ps.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.PostTitle,
    ua.PostCreationDate,
    ua.PostViewCount,
    ua.PostScore,
    ua.PostCommentCount,
    ua.PostUpvotes,
    ua.PostDownvotes,
    CASE 
        WHEN ua.Reputation > 1000 THEN 'Veteran'
        WHEN ua.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM UserActivity ua
WHERE ua.PostScore > 0
ORDER BY ua.Reputation DESC, ua.PostScore DESC
LIMIT 50;
