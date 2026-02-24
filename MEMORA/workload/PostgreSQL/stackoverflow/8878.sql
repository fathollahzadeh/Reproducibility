WITH UserVotes AS (
    SELECT V.UserId, 
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes V
    GROUP BY V.UserId
),
PostStats AS (
    SELECT P.OwnerUserId, 
           COUNT(P.Id) AS TotalPosts, 
           SUM(P.Score) AS TotalScore, 
           SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostDetails AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COALESCE(UV.UpVotes, 0) AS UpVotes, 
           COALESCE(UV.DownVotes, 0) AS DownVotes, 
           COALESCE(PS.TotalPosts, 0) AS TotalPosts, 
           COALESCE(PS.TotalScore, 0) AS TotalScore, 
           COALESCE(PS.TotalViews, 0) AS TotalViews
    FROM Users U
    LEFT JOIN UserVotes UV ON U.Id = UV.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT U.DisplayName, 
       U.UpVotes, 
       U.DownVotes, 
       U.TotalPosts, 
       U.TotalScore, 
       U.TotalViews
FROM UserPostDetails U
WHERE U.TotalPosts > 0
ORDER BY U.TotalScore DESC, U.TotalViews DESC
LIMIT 10;
