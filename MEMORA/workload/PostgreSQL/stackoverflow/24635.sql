WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NULL THEN 0 ELSE p.Score END) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ProminentUsers AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.TotalScore,
        ua.UpVotes,
        ua.DownVotes
    FROM UserActivity ua
    WHERE ua.PostRank <= 10
), 
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        c.Id AS CommentId,
        c.Text AS CommentText,
        ph.UserId AS EditorId,
        ph.Comment AS EditComment,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
    WHERE p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, c.Id, c.Text, ph.UserId, ph.Comment
),
PostSummary AS (
    SELECT 
        pe.PostId,
        pe.Title,
        COALESCE(SUM(pe.TotalComments), 0) AS CommentCount,
        COALESCE(MIN(pe.EditComment), 'No edits') AS LatestEditComment
    FROM PostEngagement pe
    GROUP BY pe.PostId, pe.Title
)
SELECT 
    pu.DisplayName,
    pu.Reputation,
    ps.Title,
    ps.CommentCount,
    ps.LatestEditComment,
    CASE 
        WHEN ps.CommentCount >= 5 THEN 'Highly Engaged'
        WHEN ps.CommentCount BETWEEN 1 AND 4 THEN 'Moderately Engaged'
        ELSE 'No Engagement'
    END AS EngagementLevel,
    CONCAT('User: ', pu.DisplayName, ' has a total reputation of ', pu.Reputation, 
           ' and posts titled "', ps.Title, '" with comment count: ', ps.CommentCount)
    AS EngagementSummary
FROM ProminentUsers pu
JOIN PostSummary ps ON pu.UserId = ps.PostId
ORDER BY pu.Reputation DESC, ps.CommentCount DESC;