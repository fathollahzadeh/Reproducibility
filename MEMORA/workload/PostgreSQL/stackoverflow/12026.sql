
WITH PostCounts AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY pt.Name
),
UserVotes AS (
    SELECT
        u.DisplayName AS UserDisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.DisplayName
),
BadgeCounts AS (
    SELECT
        u.DisplayName AS UserDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.DisplayName
)
SELECT 
    pc.PostType,
    pc.PostCount,
    pc.TotalScore,
    pc.TotalViews,
    pc.TotalAnswers,
    uv.UserDisplayName,
    uv.VoteCount,
    uv.UpVotes,
    uv.DownVotes,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount
FROM PostCounts pc
LEFT JOIN UserVotes uv ON 1=1 
LEFT JOIN BadgeCounts bc ON uv.UserDisplayName = bc.UserDisplayName
ORDER BY pc.PostType;
