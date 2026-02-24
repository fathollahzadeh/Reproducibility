WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS ViewRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY V.PostId
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        PH.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11) 
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalViews,
    U.Questions,
    U.Answers,
    COALESCE(RV.UpVotes, 0) AS RecentUpVotes,
    COALESCE(RV.DownVotes, 0) AS RecentDownVotes,
    PD.Title,
    PD.CreationDate,
    PD.CloseReason,
    P.LastActivityDate,
    CASE 
        WHEN PD.HistoryRank = 1 THEN 'Latest Status'
        ELSE 'Historical Status'
    END AS StatusType
FROM UserStats U
LEFT JOIN RecentVotes RV ON RV.PostId = U.UserId
LEFT JOIN Posts P ON P.OwnerUserId = U.UserId 
LEFT JOIN PostDetails PD ON PD.PostId = P.Id
WHERE 
    U.Reputation > 10 AND
    (P.LastActivityDate IS NULL OR P.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months')
ORDER BY 
    U.ViewRank, U.Reputation DESC
LIMIT 100;