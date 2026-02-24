WITH RecursiveUserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(P.Id) AS PostsCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesGiven,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesGiven,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT UserId, SUM(Class) AS Class
        FROM Badges
        GROUP BY UserId
    ) B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
UserPostStats AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        PostsCount,
        TotalScore,
        UpVotesGiven,
        DownVotesGiven,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM RecursiveUserActivity
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        PostsCount,
        TotalScore,
        UpVotesGiven,
        DownVotesGiven,
        TotalBadges
    FROM UserPostStats
    WHERE Reputation > 100 AND PostsCount > 5
)

SELECT 
    FU.DisplayName,
    FU.Reputation,
    FU.PostsCount,
    FU.TotalScore,
    FU.UpVotesGiven,
    FU.DownVotesGiven,
    FU.TotalBadges,
    PT.Name AS PostType,
    COUNT(Ph.PostId) AS HistoryCount,
    COUNT(DISTINCT C.Id) AS CommentCount,
    AVG(COALESCE(PV.VotesPerPost, 0)) AS AverageVotesPerPost
FROM FilteredUsers FU
LEFT JOIN Posts P ON FU.UserId = P.OwnerUserId
LEFT JOIN PostHistory Ph ON P.Id = Ph.PostId
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN (
    SELECT PostId, COUNT(*) AS VotesPerPost
    FROM Votes
    GROUP BY PostId
) PV ON P.Id = PV.PostId
LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY FU.UserId, FU.DisplayName, FU.Reputation, FU.PostsCount, 
         FU.TotalScore, FU.UpVotesGiven, FU.DownVotesGiven, 
         FU.TotalBadges, PT.Name
HAVING COUNT(P.Id) > 3 AND SUM(PV.VotesPerPost) > 0
ORDER BY FU.TotalScore DESC, FU.Reputation DESC;
