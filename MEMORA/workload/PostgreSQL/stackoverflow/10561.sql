
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate
    FROM 
        Posts P
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.VoteCount,
    U.BadgeCount,
    SUM(PS.Score) AS TotalScore,
    SUM(PS.ViewCount) AS TotalViewCount,
    SUM(PS.AnswerCount) AS TotalAnswerCount,
    SUM(PS.CommentCount) AS TotalCommentCount,
    SUM(PS.FavoriteCount) AS TotalFavoriteCount,
    COUNT(PS.PostId) AS TotalPosts,
    AVG(PS.Score) AS AvgScore,
    AVG(PS.ViewCount) AS AvgViewCount
FROM 
    UserStats U
LEFT JOIN 
    PostStats PS ON U.UserId = PS.OwnerUserId
GROUP BY 
    U.UserId, U.Reputation, U.PostCount, U.VoteCount, U.BadgeCount
ORDER BY 
    U.Reputation DESC;
