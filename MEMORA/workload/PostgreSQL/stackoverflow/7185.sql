WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(Id) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(Id) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN UserBadgeCounts b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.AnswerCount,
        ps.UserBadgeCount,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PostRank
    FROM PostStatistics ps
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    r.AnswerCount,
    r.UserBadgeCount
FROM RankedPosts r
WHERE r.PostRank <= 100
ORDER BY r.PostRank;