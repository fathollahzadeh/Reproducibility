WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        COUNT(COALESCE(C.Id, 0)) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.OwnerUserId
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LatestCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.NetVotes,
    COALESCE(TP.PostId, 0) AS TopPostId,
    COALESCE(TP.Title, 'No Posts') AS TopPostTitle,
    COALESCE(TP.Score, 0) AS TopPostScore,
    COALESCE(TP.ViewCount, 0) AS TopPostViewCount,
    CP.CloseCount,
    CP.LatestCloseDate
FROM 
    UserScores U
LEFT JOIN 
    TopPosts TP ON U.UserId = TP.OwnerUserId AND TP.PostRank = 1
LEFT JOIN 
    ClosedPostHistory CP ON TP.PostId = CP.PostId
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC, U.DisplayName;