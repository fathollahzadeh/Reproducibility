
WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
RecentPostHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.CreationDate AS HistoryDate,
        PH.Comment,
        DENSE_RANK() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS RecentHistoryRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        PH.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.UserRank,
    RP.PostId,
    RP.Title,
    RP.CreationDate AS PostCreationDate,
    RP.HistoryDate,
    RP.Comment AS RecentHistoryComment
FROM 
    RecursiveUserActivity UA
LEFT JOIN 
    RecentPostHistory RP ON UA.UserId = RP.PostId
WHERE 
    UA.TotalPosts > 5
ORDER BY 
    UA.UserRank, RP.HistoryDate DESC;
