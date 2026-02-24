
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        COUNT(C.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS SuggestedEdits
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.Score,
        PA.ViewCount,
        RANK() OVER (ORDER BY PA.Score DESC) AS PostRank
    FROM 
        PostActivity PA
)
SELECT 
    UE.UserId,
    UE.DisplayName,
    UE.Reputation,
    UE.Upvotes AS UserUpvotes,
    UE.Downvotes AS UserDownvotes,
    PA.Title AS PostTitle,
    PA.Score AS PostScore,
    PA.ViewCount AS PostViewCount,
    T.PostRank,
    CASE WHEN PA.Upvotes - PA.Downvotes < 0 THEN 'Negative Feedback' 
         WHEN PA.CloseVotes > 0 THEN 'Under Review' 
         ELSE 'Active' END AS PostStatus
FROM 
    UserEngagement UE
JOIN 
    PostActivity PA ON UE.UserId = PA.OwnerUserId
JOIN 
    TopPosts T ON PA.PostId = T.PostId
ORDER BY 
    UE.Reputation DESC, 
    PA.Score DESC;
