
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation >= 10000 THEN 'Platinum'
            WHEN Reputation >= 1000 THEN 'Gold'
            WHEN Reputation >= 100 THEN 'Silver'
            ELSE 'Bronze'
        END AS Badge
    FROM Users
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN CloseReasonTypes crt ON CAST(ph.Comment AS INTEGER) = crt.Id
    WHERE p.PostTypeId IN (1, 2)  
    GROUP BY p.Id, p.Title
),
TopCloseReasons AS (
    SELECT 
        CloseReasons,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS ReasonRank
    FROM (
        SELECT CloseReasons FROM ClosedPosts
    ) AS RankedReasons
    GROUP BY CloseReasons
),
PostWithMostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
    ORDER BY TotalComments DESC
    LIMIT 1
),
UserVotesSummary AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
)
SELECT 
    u.DisplayName,
    u.CreationDate,
    ur.Badge,
    cp.Title AS ClosedPostTitle,
    cp.CloseReasonCount,
    cp.CloseReasons,
    p.TotalComments AS CommentsOnMostCommentedPost,
    uvs.TotalVotes,
    uvs.UpVotes,
    uvs.DownVotes
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN ClosedPosts cp ON cp.PostId IN (SELECT PostId FROM PostWithMostComments)
LEFT JOIN PostWithMostComments p ON p.PostId = cp.PostId
LEFT JOIN UserVotesSummary uvs ON u.Id = uvs.UserId
WHERE u.Reputation > 100  
ORDER BY u.Reputation DESC;
