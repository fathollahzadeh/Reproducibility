
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS TotalEdits,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY ph.PostId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        ActivityRank
    FROM UserActivity
    WHERE ActivityRank <= 10
),
PostsStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(ph.FirstEditDate, p.CreationDate) AS EffectiveCreationDate,
        ps.TotalEdits,
        ps.UniqueEditors,
        t.TagName
    FROM Posts p
    LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS TotalEdits,
            COUNT(DISTINCT UserId) AS UniqueEditors
        FROM PostHistory 
        WHERE PostHistoryTypeId IN (4, 5, 24)
        GROUP BY PostId
    ) ps ON p.Id = ps.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    tu.DisplayName AS TopUser,
    ps.Title AS PostTitle,
    ps.EffectiveCreationDate,
    ps.TotalEdits,
    ps.UniqueEditors,
    ps.TagName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM TopUsers tu
JOIN PostsStatistics ps ON RANDOM() < 0.1 
ORDER BY tu.ActivityRank, ps.EffectiveCreationDate DESC;
