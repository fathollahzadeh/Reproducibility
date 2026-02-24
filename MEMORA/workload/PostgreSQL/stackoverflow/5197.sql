WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        P.AcceptedAnswerId,
        COUNT(C.Id) AS CommentCount,
        COUNT(A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, P.AcceptedAnswerId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        UserStats U
    WHERE 
        U.Reputation > 1000
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    P.Title AS PostTitle,
    P.ViewCount AS PostViews,
    P.Score AS PostScore,
    P.CommentCount,
    P.AnswerCount,
    R.Rank
FROM 
    PostAnalysis P
JOIN 
    Users U ON P.AcceptedAnswerId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
JOIN 
    TopUsers R ON U.Id = R.UserId
ORDER BY 
    R.Rank, P.Score DESC
LIMIT 100;