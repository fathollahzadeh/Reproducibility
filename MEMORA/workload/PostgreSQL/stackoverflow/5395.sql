WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        RANK() OVER (ORDER BY UpVotes DESC, PostCount DESC) AS Rank
    FROM UserVoteCounts
    WHERE PostCount > 0
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 1 END) AS RecentPostCount,
        AVG(P.Score) AS AvgScore
    FROM Posts P
    WHERE P.OwnerUserId IS NOT NULL
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    R.RecentPostCount,
    R.AvgScore
FROM TopUsers U
JOIN RecentPostStats R ON U.UserId = R.OwnerUserId
WHERE U.Rank <= 10
ORDER BY U.UpVotes DESC, R.AvgScore DESC;