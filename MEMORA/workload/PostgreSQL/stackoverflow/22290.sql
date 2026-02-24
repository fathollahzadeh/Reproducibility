
WITH UserMeta AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
UserActivity AS (
    SELECT 
        UM.UserId,
        UM.DisplayName,
        SUM(COALESCE(RP.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(RP.Score, 0)) AS TotalScore,
        COUNT(DISTINCT RP.PostId) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade
    FROM 
        UserMeta UM
    LEFT JOIN 
        RecentPosts RP ON UM.UserId = RP.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = UM.UserId
    GROUP BY 
        UM.UserId, UM.DisplayName
)
SELECT 
    UA.DisplayName,
    UA.TotalViews,
    UA.TotalScore,
    UA.PostsCreated,
    UA.CommentsMade,
    U.Reputation,
    U.CreationDate,
    CASE 
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    (SELECT 
        STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM 
        Posts P
     JOIN 
        UNNEST(string_to_array(P.Tags, ',')) AS Tag ON TRUE
     JOIN 
        Tags T ON T.TagName = Tag 
     WHERE 
        P.OwnerUserId = UA.UserId
    ) AS TagsUsed
FROM 
    UserActivity UA
JOIN 
    Users U ON UA.UserId = U.Id
WHERE 
    UA.PostsCreated > 0
ORDER BY 
    UA.TotalScore DESC, UA.TotalViews DESC
LIMIT 10;
