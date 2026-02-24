WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostTypeName,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(V.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
),

UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    PE.PostId,
    PE.Title,
    PE.PostTypeName,
    PE.OwnerDisplayName,
    PE.CreationDate,
    PE.Score,
    PE.ViewCount,
    PE.CommentCount,
    PE.UpVoteCount,
    PE.DownVoteCount,
    UE.UserId,
    UE.TotalPosts,
    UE.TotalViews,
    UE.TotalScore,
    UE.TotalComments
FROM 
    PostEngagement PE
JOIN 
    UserEngagement UE ON PE.OwnerDisplayName = UE.DisplayName
ORDER BY 
    PE.Score DESC, PE.ViewCount DESC;