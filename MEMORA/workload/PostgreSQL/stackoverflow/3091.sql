WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN p.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes, 
        DownVotes, 
        CommentCount, 
        PostCount,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS VoteRank
    FROM UserEngagement
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.LastActivityDate, 
        COALESCE(
            (SELECT COUNT(*) 
             FROM Comments c 
             WHERE c.PostId = p.Id), 0) AS TotalComments
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        ap.PostId, 
        ap.Title, 
        ap.CreationDate, 
        ap.LastActivityDate, 
        ap.TotalComments,
        COALESCE(
            (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
             FROM Tags t 
             WHERE t.WikiPostId = ap.PostId), 'No Tags') AS Tags
    FROM ActivePosts ap
)
SELECT 
    tu.DisplayName, 
    p.Title, 
    p.TotalComments, 
    tu.UpVotes, 
    tu.DownVotes, 
    tu.VoteRank,
    CASE 
        WHEN p.TotalComments > 10 THEN 'High Engagement'
        WHEN p.TotalComments BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM TopUsers tu
JOIN PostDetails p ON tu.UserId = p.PostId
WHERE tu.VoteRank <= 10
ORDER BY tu.VoteRank, p.TotalComments DESC;