
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL AND U.Reputation > 0
),
TopPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate
),
UpvotedPosts AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(UP.Upvotes, 0) AS UpvoteCount,
        COALESCE(UP.Downvotes, 0) AS DownvoteCount,
        (COALESCE(UP.Upvotes, 0) - COALESCE(UP.Downvotes, 0)) AS NetVotes,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        U.Location AS OwnerLocation,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UpvotedPosts UP ON P.Id = UP.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Score,
    PD.UpvoteCount,
    PD.DownvoteCount,
    PD.NetVotes,
    PD.OwnerName,
    PD.OwnerReputation,
    PD.OwnerLocation,
    CASE 
        WHEN R.ReputationRank < 11 THEN 'Top User' 
        ELSE 'Regular User' 
    END AS UserCategory
FROM 
    PostDetails PD
LEFT JOIN 
    UserReputation R ON PD.OwnerUserId = R.UserId
WHERE 
    PD.Score > 10
ORDER BY 
    PD.NetVotes DESC, PD.Score DESC
LIMIT 50;
