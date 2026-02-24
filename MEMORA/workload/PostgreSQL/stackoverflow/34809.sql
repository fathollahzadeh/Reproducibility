WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id,
        U.Reputation,
        U.DisplayName,
        0 AS Level,
        CAST(U.DisplayName AS VARCHAR(255)) AS Path
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 
    UNION ALL
    SELECT 
        U.Id,
        U.Reputation,
        U.DisplayName,
        C.Level + 1,
        CAST(C.Path || ' -> ' || U.DisplayName AS VARCHAR(255)) AS Path
    FROM 
        Users U
    INNER JOIN 
        Votes V ON U.Id = V.UserId
    INNER JOIN 
        UserReputationCTE C ON V.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = C.Id)
    WHERE 
        U.Reputation > C.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        P.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) as RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        RP.Title,
        RP.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN V.VoteTypeId = 2 THEN 'Upvote'
            WHEN V.VoteTypeId = 3 THEN 'Downvote'
            ELSE 'Other'
        END AS VoteType,
        PH.Comment AS CloseReason,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        RecentPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON RP.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON RP.Id = PH.PostId AND PH.PostHistoryTypeId = 10 
    LEFT JOIN 
        Comments C ON RP.Id = C.PostId
    WHERE 
        RP.RecentPostRank = 1
    GROUP BY 
        RP.Title, RP.CreationDate, U.DisplayName, V.VoteTypeId, PH.Comment
)
SELECT 
    PD.Title,
    PD.CreationDate,
    PD.OwnerDisplayName,
    COALESCE(PD.CloseReason, 'Not Closed') AS CloseReason,
    PD.CommentCount,
    PD.UpvoteCount,
    PD.DownvoteCount,
    (SELECT AVG(Reputation) FROM UserReputationCTE) AS AvgReputationOfActiveUsers
FROM 
    PostDetails PD
ORDER BY 
    PD.CreationDate DESC
LIMIT 100;