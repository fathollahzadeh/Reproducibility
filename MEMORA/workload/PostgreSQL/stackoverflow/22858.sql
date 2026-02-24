
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        ROW_NUMBER() OVER(PARTITION BY U.Id ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostInformation AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(PA.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS CommentRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts PA ON P.AcceptedAnswerId = PA.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, PA.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.CreationDate,
        PI.OwnerUserId,
        UA.DisplayName,
        UA.Upvotes,
        UA.Downvotes,
        PI.CommentCount,
        RANK() OVER (PARTITION BY PI.OwnerUserId ORDER BY PI.CommentCount DESC) AS RankByComments
    FROM 
        PostInformation PI
    JOIN 
        UserActivity UA ON PI.OwnerUserId = UA.UserId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.DisplayName,
    RP.Upvotes,
    RP.Downvotes,
    RP.CommentCount,
    CASE 
        WHEN RP.RankByComments = 1 THEN 'Most Commented'
        ELSE 'Less Commented'
    END AS CommentCategory
FROM 
    RankedPosts RP
WHERE 
    (RP.Upvotes - RP.Downvotes) > 10 AND 
    RP.CommentCount > 0 
ORDER BY 
    RP.Upvotes DESC, 
    RP.CommentCount DESC
FETCH FIRST 100 ROWS ONLY;
