WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) OVER (PARTITION BY P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate,
        STRING_AGG(CT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::INTEGER = CT.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId, PH.CreationDate
),
ActiveBadges AS (
    SELECT 
        U.Id AS UserId, 
        B.Name AS BadgeName, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    JOIN 
        Users U ON B.UserId = U.Id
    WHERE 
        B.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        U.Id, B.Name
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.CommentCount,
    CP.CloseReasons,
    TB.UserId AS TopUserId,
    TB.DisplayName AS TopUserName,
    TB.Reputation AS TopUserReputation,
    AB.BadgeName,
    AB.BadgeCount
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
LEFT JOIN 
    ActiveBadges AB ON RP.PostId = AB.UserId
LEFT JOIN 
    TopUsers TB ON AB.UserId = TB.UserId
WHERE 
    RP.RankByScore <= 5 
    AND (CP.CloseReasons IS NOT NULL OR AB.BadgeCount > 0)
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;