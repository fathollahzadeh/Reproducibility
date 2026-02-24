
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(ut.UpVotes, 0) AS UserUpVotes,
        COALESCE(ut.DownVotes, 0) AS UserDownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) ut ON p.Id = ut.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
),
RecentPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.UserUpVotes,
        pm.UserDownVotes,
        CASE 
            WHEN pm.UserUpVotes IS NULL THEN 'No votes yet'
            ELSE 'Votes recorded'
        END AS VoteStatus
    FROM PostMetrics pm
    WHERE pm.rn <= 10
)
SELECT 
    u.DisplayName AS UserName,
    r.Title,
    r.Score AS PostScore,
    r.ViewCount,
    r.UserUpVotes,
    r.UserDownVotes,
    r.VoteStatus,
    CASE 
        WHEN r.UserUpVotes > r.UserDownVotes THEN 'Positive Engagement'
        WHEN r.UserUpVotes < r.UserDownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus
FROM UserActivity u
JOIN RecentPosts r ON u.PostCount > 0
ORDER BY u.PostCount DESC, r.ViewCount DESC;
