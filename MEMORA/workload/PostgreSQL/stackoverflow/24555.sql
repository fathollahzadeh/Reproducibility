
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(V.VoteCount, 0) AS VoteCount,
        COALESCE(C.CommentCount, 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' OR P.Score > 100
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.CreationDate,
        PD.LastActivityDate,
        PD.VoteCount,
        PD.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN PD.Score > 50 THEN 'High Score' ELSE 'Low Score' END 
                           ORDER BY PD.Score DESC) AS PostRank
    FROM 
        PostDetail PD
)
SELECT 
    US.DisplayName, 
    US.Reputation, 
    US.PostCount,
    US.TotalViews,
    US.BadgeCount,
    RP.Title,
    RP.Score,
    RP.CreationDate,
    RP.LastActivityDate,
    RP.VoteCount,
    RP.CommentCount
FROM 
    UserStats US
JOIN 
    RankedPosts RP ON US.UserId = RP.PostId
WHERE 
    (US.Reputation > 1000 AND US.PostCount > 5) 
    OR RP.PostRank <= 5
ORDER BY 
    US.Reputation DESC, 
    RP.Score DESC;
