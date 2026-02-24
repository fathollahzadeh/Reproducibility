WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.Title,
        COUNT(C) AS CommentCount,
        SUM(COALESCE(PV.VoteValue, 0)) AS Score,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            UserId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteValue
         FROM 
            Votes 
         GROUP BY 
            UserId) PV ON PV.UserId = P.OwnerUserId
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId, P.Title
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.Location,
        US.Reputation,
        PS.Title,
        PS.CommentCount,
        PS.Score,
        COALESCE(PS.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY PS.PostId ORDER BY PS.Score DESC) AS Rank
    FROM 
        UserVoteSummary US
    JOIN 
        Posts P ON US.UserId = P.OwnerUserId
    JOIN 
        PostSummary PS ON P.Id = PS.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    DisplayName,
    Location,
    Reputation,
    Title,
    CommentCount,
    Score,
    BadgeCount
FROM 
    FinalReport
WHERE 
    Rank = 1
ORDER BY 
    Score DESC, Reputation DESC
LIMIT 100;