
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COALESCE(PT.Name, 'Unknown') AS PostType,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, PT.Name
),
TopPosters AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 10
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PH.PostHistoryTypeId
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    AND 
        PH.PostHistoryTypeId IN (10, 11, 12, 13)
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.PostType,
    PS.Score,
    PS.ViewCount,
    PS.Upvotes,
    PS.Downvotes,
    PS.CommentCount,
    T.DisplayName AS TopPoster,
    T.PostCount,
    T.TotalScore,
    RPH.UserId AS RecentUserId,
    RPH.CreationDate AS RecentActionDate,
    RPH.Comment AS RecentComment
FROM 
    PostStats PS
LEFT JOIN 
    TopPosters T ON PS.UserPostRank = 1
LEFT JOIN 
    RecentPostHistory RPH ON PS.PostId = RPH.PostId
ORDER BY 
    PS.Score DESC, PS.CreationDate DESC
LIMIT 50;
