
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserStatistics
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(ph.Comment, 'No comment') AS HistoryComment,
        pt.Name AS PostType
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    pd.Title,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.PostType,
    tu.ScoreRank,
    CASE 
        WHEN pd.CommentCount > 0 THEN 'Active Discussion'
        ELSE 'No Activity'
    END AS DiscussionStatus
FROM TopUsers tu
JOIN PostDetails pd ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)
WHERE tu.ScoreRank <= 10  
ORDER BY tu.ScoreRank, pd.ViewCount DESC;
