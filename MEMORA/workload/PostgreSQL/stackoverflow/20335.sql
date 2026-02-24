
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation IS NOT NULL
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        UserRank
    FROM UserStatistics
    WHERE UserRank <= 10 
),

PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(CASE WHEN vs.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Votes vs ON p.AcceptedAnswerId = vs.PostId AND vs.VoteTypeId = 1
    WHERE p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY p.Id, p.Title
),

PostSummary AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CommentCount,
        pa.UpVoteCount,
        pa.DownVoteCount,
        pa.HasAcceptedAnswer,
        ROW_NUMBER() OVER (ORDER BY pa.UpVoteCount - pa.DownVoteCount DESC) AS PostRank
    FROM PostActivity pa
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    ps.Title AS PostTitle,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.HasAcceptedAnswer,
    (CASE 
        WHEN ps.HasAcceptedAnswer = 1 THEN 'Yes' 
        ELSE 'No' 
    END) AS AcceptedAnswer,
    (CASE 
        WHEN ps.CommentCount > 0 THEN 'Active Discussion' 
        ELSE 'No Comments' 
    END) AS DiscussionStatus
FROM TopUsers tu
JOIN PostSummary ps ON tu.UserId = (
    SELECT OwnerUserId
    FROM Posts
    WHERE Title = ps.Title
    LIMIT 1
)
WHERE ps.PostRank <= 5
ORDER BY tu.Reputation DESC, ps.UpVoteCount DESC;
