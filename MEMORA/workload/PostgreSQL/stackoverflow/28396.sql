WITH UserDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount
),

RecentActivity AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        P.Title AS PostTitle,
        P.Score AS PostScore,
        P.ViewCount AS PostViewCount,
        PH.Comment
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    ORDER BY 
        PH.CreationDate DESC
)

SELECT 
    UD.UserId,
    UD.DisplayName,
    UD.Reputation,
    UD.TotalPosts,
    UD.TotalComments,
    UD.TotalUpvotes,
    UD.TotalDownvotes,
    UD.TotalGoldBadges,
    UD.TotalSilverBadges,
    UD.TotalBronzeBadges,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.ViewCount AS PostViewCount,
    PS.Score AS PostScore,
    PS.AnswerCount AS PostAnswerCount,
    PS.CommentCount AS PostCommentCount,
    PS.Tags AS PostTags,
    RA.CreationDate AS RecentActivityDate,
    RA.UserDisplayName AS ActivityUser,
    RA.Comment AS RecentActivityComment
FROM 
    UserDetails UD
LEFT JOIN 
    PostStatistics PS ON UD.UserId = PS.PostId
LEFT JOIN 
    RecentActivity RA ON PS.PostId = RA.PostId
ORDER BY 
    UD.Reputation DESC, PS.Score DESC, RA.CreationDate DESC;