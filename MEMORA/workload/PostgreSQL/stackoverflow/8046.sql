WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostTypeStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        MAX(P.ViewCount) AS MaxViewCount
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY PT.Name
),
UserAndPostStats AS (
    SELECT 
        US.DisplayName,
        US.PostCount,
        US.TotalBounty,
        US.UpVotes,
        US.DownVotes,
        US.BadgeCount,
        PTS.PostType,
        PTS.TotalPosts,
        PTS.AvgScore,
        PTS.MaxViewCount
    FROM UserScores US
    CROSS JOIN PostTypeStats PTS
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.TotalBounty,
    U.UpVotes,
    U.DownVotes,
    U.BadgeCount,
    U.PostType,
    U.TotalPosts,
    U.AvgScore,
    U.MaxViewCount
FROM UserAndPostStats U
ORDER BY U.PostCount DESC, U.UpVotes DESC
LIMIT 100;
