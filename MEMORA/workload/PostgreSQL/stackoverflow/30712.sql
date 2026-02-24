
WITH RecursiveBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS BadgeRank
    FROM Badges
    GROUP BY UserId
),
QuestionPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount
        FROM Votes
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
RankedQuestions AS (
    SELECT 
        qp.PostId,
        qp.Title,
        qp.OwnerUserId,
        qp.ViewCount,
        qp.UpVoteCount,
        qp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY qp.ViewCount DESC, qp.UpVoteCount DESC) AS Rank
    FROM QuestionPosts qp
    LEFT JOIN ClosedQuestions cq ON qp.PostId = cq.PostId
    WHERE cq.ClosedDate IS NULL
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        CONCAT(u.DisplayName, ' - Reputation: ', CAST(u.Reputation AS VARCHAR)) AS UserInfo,
        rb.BadgeCount AS BadgeCount
    FROM Users u
    JOIN RecursiveBadgeCounts rb ON u.Id = rb.UserId
    WHERE rb.BadgeCount > 0
)
SELECT 
    rq.Rank,
    rq.Title,
    rq.ViewCount,
    rq.UpVoteCount,
    rq.CommentCount,
    u.UserInfo
FROM RankedQuestions rq
JOIN UsersWithBadges u ON rq.OwnerUserId = u.UserId
WHERE rq.Rank <= 10
ORDER BY rq.Rank;
