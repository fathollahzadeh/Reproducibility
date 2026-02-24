WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostCloseReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
),
UserPostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(V.CreationDate IS NOT NULL::int) AS VoteCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Posts p
    LEFT JOIN Votes V ON p.Id = V.PostId
    GROUP BY p.OwnerUserId
)
SELECT
    up.DisplayName AS UserName,
    up.Reputation,
    rb.PostId,
    rb.Title,
    rb.Score,
    rb.ViewCount,
    COALESCE(bd.BadgeCount, 0) AS BadgeCount,
    bd.BadgeNames,
    s.PostCount AS TotalPosts,
    s.VoteCount AS TotalVotes,
    s.QuestionCount AS TotalQuestions,
    s.AnswerCount AS TotalAnswers,
    COALESCE(cr.CloseReasons, 'No close reasons') AS PostCloseReasons
FROM Users up
JOIN UserBadges bd ON up.Id = bd.UserId
JOIN RankedPosts rb ON up.Id = rb.Rank 
JOIN UserPostStats s ON up.Id = s.OwnerUserId
LEFT JOIN PostCloseReasons cr ON rb.PostId = cr.PostId
WHERE bd.BadgeCount > 0
    AND s.PostCount > 2
    AND rb.Rank <= 5
ORDER BY rb.Score DESC, up.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;