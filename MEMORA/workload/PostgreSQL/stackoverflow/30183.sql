WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id AS UserId,
        (U.Reputation + 100) AS Reputation,
        Level + 1
    FROM 
        Users U
    INNER JOIN UserReputation UR ON U.Id = UR.UserId
    WHERE 
        Level < 5
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(CASE WHEN P.OwnerUserId = U.Id THEN 1 ELSE 0 END), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN PS.CommentCount > 0 THEN 1 ELSE 0 END), 0) AS PostsWithComments,
        AVG(PS.CommentCount) AS AvgCommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostStats PS ON P.Id = PS.PostId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    UR.Reputation AS Reputation,
    UPS.PostCount,
    UPS.PostsWithComments,
    UPS.AvgCommentCount,
    P.Title,
    P.CreationDate,
    P.LastActivityDate
FROM 
    Users U
JOIN 
    UserReputation UR ON U.Id = UR.UserId
JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
LEFT OUTER JOIN 
    Posts P ON P.OwnerUserId = U.Id AND P.Id IN (
        SELECT 
            Id FROM Posts ORDER BY Score DESC LIMIT 5
    )
WHERE 
    UR.Level >= 1
ORDER BY 
    UR.Reputation DESC, UPS.PostCount DESC;