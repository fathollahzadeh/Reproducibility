WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND (V.VoteTypeId = 8 OR V.VoteTypeId = 9) 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount
),
UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        SUM(PM.Score) AS TotalPostScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostMetrics PM ON P.Id = PM.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UM.UserId,
    UM.DisplayName,
    UM.TotalBadges,
    UM.TotalUpVotes,
    UM.TotalDownVotes,
    UM.TotalPostScore,
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.Score,
    PM.ViewCount,
    PM.AnswerCount,
    PM.CommentCount,
    PM.TotalBounty
FROM 
    UserMetrics UM
JOIN 
    PostMetrics PM ON UM.UserId = PM.PostId
ORDER BY 
    UM.TotalPostScore DESC, PM.Score DESC;