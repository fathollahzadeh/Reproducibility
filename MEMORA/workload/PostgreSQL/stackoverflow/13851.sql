
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        PT.Name AS PostType,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        P.ViewCount,
        P.CreationDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        P.Id, PT.Name, P.ViewCount, P.CreationDate
),
PostStatistics AS (
    SELECT 
        PostType,
        COUNT(PostId) AS TotalPosts,
        AVG(CommentCount) AS AverageComments,
        AVG(VoteCount) AS AverageVotes,
        AVG(BadgeCount) AS AverageBadges,
        AVG(ViewCount) AS AverageViews
    FROM 
        PostMetrics
    GROUP BY 
        PostType
)
SELECT 
    P.*, 
    ROW_NUMBER() OVER (ORDER BY P.TotalPosts DESC) AS Rank
FROM 
    PostStatistics P
ORDER BY 
    P.TotalPosts DESC;
