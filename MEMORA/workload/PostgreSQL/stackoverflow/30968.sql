
WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AcceptedAnswer,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.AcceptedAnswerId
),
TopAuthors AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName AS Author,
    U.Reputation,
    UBC.GoldBadgeCount,
    UBC.SilverBadgeCount,
    UBC.BronzeBadgeCount,
    TA.PostCount,
    TA.TotalComments,
    PA.Title,
    PA.CommentCount,
    PA.UpVoteCount,
    PA.DownVoteCount,
    PA.CreationDate,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PA.PostId AND V.VoteTypeId = 2) AS TotalUpVotesOfPost,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PA.PostId AND V.VoteTypeId = 3) AS TotalDownVotesOfPost
FROM 
    UserBadgeCounts UBC
JOIN 
    Users U ON UBC.UserId = U.Id
JOIN 
    TopAuthors TA ON U.Id = TA.Id
JOIN 
    PostAnalytics PA ON PA.OwnerUserId = U.Id
WHERE 
    U.Reputation > 1000 
    AND (PA.CommentCount > 5 OR PA.UpVoteCount > PA.DownVoteCount) 
ORDER BY 
    U.Reputation DESC, 
    PA.UpVoteCount DESC;
