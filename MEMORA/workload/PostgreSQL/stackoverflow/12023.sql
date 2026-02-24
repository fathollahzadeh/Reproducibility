WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.FavoriteCount) AS TotalFavorites
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        AVG(Ps.TotalViews) AS AveragePostViews,
        SUM(Ps.TotalFavorites) AS TotalPostFavorites
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostStats Ps ON U.Id = Ps.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    Ps.CommentCount,
    Ps.VoteCount,
    Ps.AverageScore,
    Ps.TotalViews,
    Ps.TotalFavorites,
    U.TotalBadges,
    U.AveragePostViews,
    U.TotalPostFavorites
FROM 
    PostStats Ps
JOIN 
    Posts P ON Ps.PostId = P.Id
JOIN 
    UserStats U ON Ps.OwnerUserId = U.UserId
ORDER BY 
    Ps.AverageScore DESC, Ps.TotalViews DESC;