
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        Upvotes,
        Downvotes
    FROM 
        UserEngagement
    WHERE 
        PostRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(CNT.CommentCount, 0) AS CommentCount,
        COALESCE(AV.AvgViewCount, 0) AS AvgViewCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) CNT ON P.Id = CNT.PostId
    LEFT JOIN (
        SELECT
            PostId,
            AVG(ViewCount) AS AvgViewCount
        FROM 
            Posts
        GROUP BY 
            PostId
    ) AV ON P.Id = AV.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
PostInteractions AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.CommentCount,
        PU.UserId,
        PU.DisplayName
    FROM 
        PostDetails PD
    JOIN 
        Posts P ON PD.PostId = P.Id
    JOIN 
        TopUsers PU ON P.OwnerUserId = PU.UserId
)
SELECT 
    PI.Title,
    PI.CreationDate,
    PI.Score,
    PI.CommentCount,
    CONCAT('User: ', PI.DisplayName, ' (Posts: ', TU.TotalPosts, ', Comments: ', TU.TotalComments, ', Upvotes: ', TU.Upvotes, ', Downvotes: ', TU.Downvotes, ')') AS UserEngagementDetails
FROM 
    PostInteractions PI
JOIN 
    TopUsers TU ON PI.UserId = TU.UserId
ORDER BY 
    PI.Score DESC, PI.CommentCount DESC
LIMIT 20 OFFSET 0;
