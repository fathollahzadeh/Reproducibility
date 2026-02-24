WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        P.OwnerUserId, 
        R.ReputationRank
    FROM 
        Posts P
    JOIN 
        RankedUsers R ON P.OwnerUserId = R.UserId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostStats AS (
    SELECT 
        RP.*, 
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.PostId), 0) AS CommentCount
    FROM 
        RecentPosts RP
)
SELECT 
    PS.PostId, 
    PS.Title, 
    PS.ViewCount, 
    PS.Score, 
    PS.UpVoteCount, 
    PS.DownVoteCount, 
    PS.CommentCount,
    R.DisplayName AS OwnerName,
    PS.ReputationRank
FROM 
    PostStats PS
LEFT JOIN 
    Users R ON PS.OwnerUserId = R.Id
WHERE 
    PS.CommentCount > 0
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC;