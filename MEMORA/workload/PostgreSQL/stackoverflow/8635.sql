
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        pt.Name AS PostType,
        COALESCE(ph.Comment, '') AS CloseReason
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, pt.Name, ph.Comment
),
FinalReport AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.AnswerCount,
        us.UpVotes,
        us.DownVotes,
        us.BadgeCount,
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        pa.CommentCount,
        pa.PostType,
        pa.CloseReason
    FROM UserStats us
    JOIN PostAnalytics pa ON us.UserId = pa.PostId
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    PostId,
    Title,
    CreationDate,
    Score,
    CommentCount,
    PostType,
    CloseReason
FROM FinalReport
ORDER BY QuestionCount DESC, AnswerCount DESC;
