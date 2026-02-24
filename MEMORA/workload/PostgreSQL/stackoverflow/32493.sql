
WITH RecursiveUserVotes AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalVotes DESC) AS UserRank
    FROM 
        RecursiveUserVotes
    WHERE 
        TotalVotes > 0
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT V.UserId), 0) AS VoteCount,
        SUM(CASE WHEN PH.Comment IS NOT NULL THEN 1 ELSE 0 END) AS HistoryEditCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.ViewCount > 100 AND P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        PS.CommentCount,
        PS.VoteCount,
        PS.HistoryEditCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM P.CreationDate) ORDER BY P.CreationDate DESC) AS YearlyRanking
    FROM 
        Posts P
    JOIN 
        PostStatistics PS ON P.Id = PS.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.CommentCount,
    RP.VoteCount,
    RP.HistoryEditCount
FROM 
    TopUsers T
JOIN 
    Users U ON T.UserId = U.Id
CROSS JOIN 
    RecentPosts RP
WHERE 
    T.UserRank <= 5 AND RP.YearlyRanking <= 10
ORDER BY 
    U.Reputation DESC, RP.VoteCount DESC;
