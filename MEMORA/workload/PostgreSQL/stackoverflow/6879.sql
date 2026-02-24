
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, P.Score
),
RankedPosts AS (
    SELECT 
        PA.*,
        RANK() OVER (ORDER BY PA.Score DESC) AS PostRank
    FROM 
        PostActivity PA
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.AcceptedAnswers,
    US.TotalBadges,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.LastActivityDate,
    RP.Score,
    RP.CommentCount,
    RP.VoteCount,
    RP.PostRank
FROM 
    UserStats US
JOIN 
    RankedPosts RP ON US.UserId = RP.PostId
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.Reputation DESC, RP.Score DESC
LIMIT 10;
