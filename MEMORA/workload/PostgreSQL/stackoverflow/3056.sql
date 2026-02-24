
WITH UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        AvgPostScore,
        RANK() OVER (ORDER BY TotalVotes DESC) AS UserRank
    FROM UserVoteStatistics
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    WHERE P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.TotalVotes,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.CommentCount,
    R.RelatedPostsCount,
    U.AvgPostScore
FROM TopUsers U
JOIN RecentPosts R ON U.UserId = R.OwnerUserId
WHERE U.UserRank <= 10
ORDER BY U.TotalVotes DESC, R.CreationDate DESC;
