
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        MAX(H.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        PostHistory H ON P.Id = H.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        SUM(U.Views) AS TotalViews,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.LastEditDate,
    US.UserId,
    US.TotalViews,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.BadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId = U.Id 
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.ViewCount DESC,
    PS.Score DESC
LIMIT 100;
