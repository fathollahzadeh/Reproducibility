
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        COUNT(DISTINCT CASE WHEN P.PostTypeId IN (4, 5) THEN P.Id END) AS TagWikis,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes, U.CreationDate
),
PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT PH.PostHistoryTypeId) AS UniqueEditTypes
    FROM PostHistory PH
    INNER JOIN Posts P ON P.Id = PH.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY PH.UserId, PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TagWikis,
    US.TotalUpVotes,
    US.TotalDownVotes,
    COALESCE(PH.EditCount, 0) AS EditCount,
    COALESCE(PH.UniqueEditTypes, 0) AS UniqueEditTypes,
    (SELECT COUNT(*) FROM PostHistory WHERE PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)) AS TotalHistoryRecords
FROM Users U
INNER JOIN UserStats US ON U.Id = US.UserId
LEFT JOIN PostHistoryCounts PH ON PH.UserId = U.Id
WHERE US.TotalPosts > 0
ORDER BY U.Reputation DESC, U.Views DESC;
