WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
TopPosters AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Users U
    INNER JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(P.Id) > 10
),
CombinedStats AS (
    SELECT 
        UV.UserId,
        UV.DisplayName,
        UV.UpVotes,
        UV.DownVotes,
        TP.TotalPosts,
        TP.TotalViews,
        TP.TotalScore
    FROM UserVotes UV
    JOIN TopPosters TP ON UV.UserId = TP.UserId
)
SELECT 
    DisplayName,
    UpVotes,
    DownVotes,
    TotalPosts,
    TotalViews,
    TotalScore,
    (UpVotes * 1.0 / NULLIF(DownVotes, 0)) AS VoteRatio,
    (TotalScore * 1.0 / NULLIF(TotalPosts, 0)) AS AvgScorePerPost
FROM CombinedStats
ORDER BY VoteRatio DESC, TotalScore DESC
LIMIT 10;
