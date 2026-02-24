WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(CASE 
            WHEN V.VoteTypeId = 1 THEN 1 
            WHEN V.VoteTypeId = 8 THEN 1 
            ELSE 0 
        END), 0) AS SpecialVotes,
        COUNT(DISTINCT P.Id) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserScores
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        R.UserRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        RankedUsers R ON U.Id = R.UserId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
        AND P.PostTypeId IN (1, 2) 
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.OwnerDisplayName,
    RU.Reputation,
    RU.UpvoteCount,
    RU.DownvoteCount,
    RU.SpecialVotes,
    RU.AnswerCount,
    RU.CommentCount,
    CASE 
        WHEN RU.UserRank <= 10 THEN 'Top Contributor'
        WHEN RU.UserRank <= 50 THEN 'Valued Contributor'
        ELSE 'New Contributor'
    END AS ContributorCategory
FROM 
    RecentPosts RP
JOIN 
    RankedUsers RU ON RP.OwnerDisplayName = RU.DisplayName
ORDER BY 
    RP.CreationDate DESC,
    RU.Reputation DESC
LIMIT 100;