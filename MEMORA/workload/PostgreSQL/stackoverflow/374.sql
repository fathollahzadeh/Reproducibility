
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 5 THEN 1 END) AS FavoriteVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(C) AS CommentCount,
        SUM(COALESCE(PH.PostHistoryTypeId, 0)) AS PostEditCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
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
    RP.CreationDate,
    UVC.DisplayName AS PostOwner,
    UVC.UpVotesCount,
    UVC.DownVotesCount,
    UVC.FavoriteVotesCount,
    T.UserRank,
    RP.CommentCount,
    RP.PostEditCount
FROM 
    RecentPosts RP
JOIN 
    UserVoteCounts UVC ON RP.OwnerUserId = UVC.UserId
JOIN 
    TopUsers T ON RP.OwnerUserId = T.Id
WHERE 
    RP.CommentCount > 5 
    AND (UVC.UpVotesCount - UVC.DownVotesCount) > 10
ORDER BY 
    RP.CreationDate DESC
LIMIT 50;
