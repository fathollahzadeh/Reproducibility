WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT BA.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges BA ON U.Id = BA.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalViews,
        CommentCount,
        BadgeCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        PostStats
)

SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.PostCount,
    TU.TotalScore,
    TU.TotalViews,
    TU.CommentCount,
    TU.BadgeCount,
    TP.PostId,
    TP.Title AS PostTitle,
    TP.CreationDate AS PostCreationDate,
    TP.Score AS PostScore,
    TP.ViewCount AS PostViewCount,
    TP.CommentCount AS PostCommentCount,
    TP.VoteCount AS PostVoteCount
FROM 
    TopUsers TU
JOIN 
    TopPosts TP ON TU.UserId = (SELECT OwnerUserId FROM Posts ORDER BY Score DESC LIMIT 1)
WHERE 
    TU.ScoreRank <= 10     
    AND TP.ScoreRank <= 10;