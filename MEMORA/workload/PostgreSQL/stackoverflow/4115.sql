WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalCommentScore,
        TotalPosts,
        TotalVotes,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        UserActivity
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(MAX(V.UserId), -1) AS LastVoter,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
    GROUP BY 
        P.Id
)
SELECT 
    TU.DisplayName,
    TU.TotalViews,
    TU.TotalCommentScore,
    PD.Title AS PostTitle,
    PD.CreationDate AS PostCreationDate,
    PD.Score AS PostScore,
    PD.CommentCount,
    PD.PostStatus,
    TU.Rank
FROM 
    TopUsers TU
LEFT JOIN 
    PostDetails PD ON TU.UserId = PD.LastVoter
WHERE 
    TU.TotalPosts > 5
ORDER BY 
    TU.Rank, PD.CommentCount DESC
LIMIT 10;