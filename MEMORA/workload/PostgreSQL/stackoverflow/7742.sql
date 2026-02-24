
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS PositivePostScores,
        SUM(CASE WHEN P.Score < 0 THEN P.Score ELSE 0 END) AS NegativePostScores
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) AS VoteCount,
        (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id) AS HistoryCount,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS Rnk
    FROM 
        PostAnalytics
)
SELECT 
    US.DisplayName AS UserDisplayName,
    US.Reputation,
    US.Views AS UserViews,
    US.TotalPosts,
    US.TotalComments,
    US.NetVotes,
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.VoteCount,
    TP.HistoryCount
FROM 
    UserScores US
JOIN 
    TopPosts TP ON US.UserId = TP.OwnerUserId
WHERE 
    TP.Rnk <= 10
ORDER BY 
    US.Reputation DESC, TP.Score DESC;
