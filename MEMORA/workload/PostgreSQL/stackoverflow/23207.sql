
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 0
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.CreationDate,
        P.Title,
        P.Tags AS PostTags,
        COUNT(C.CommentId) AS CommentCount
    FROM Posts P
    LEFT JOIN (
        SELECT 
            C.Id AS CommentId,
            C.PostId
        FROM Comments C
        WHERE C.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    ) AS C ON P.Id = C.PostId
    WHERE P.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months') 
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId, P.CreationDate, P.Title, P.Tags
),
UserPostStats AS (
    SELECT 
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePosts,
        COALESCE(SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativePosts,
        COALESCE(AVG(P.Score), 0) AS AvgScore,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, ',')) AS TagName
    ) AS T ON TRUE
    GROUP BY U.DisplayName
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.ReputationRank,
    UPS.TotalPosts,
    UPS.PositivePosts,
    UPS.NegativePosts,
    UPS.AvgScore,
    UPS.TagsUsed,
    RP.PostId,
    RP.Title,
    RP.PostTags,
    RP.CommentCount
FROM RankedUsers RU
LEFT JOIN UserPostStats UPS ON RU.DisplayName = UPS.DisplayName
LEFT JOIN RecentPosts RP ON RP.OwnerUserId = RU.UserId
WHERE RU.ReputationRank <= 10 
AND (UPS.TotalPosts IS NULL OR (UPS.PositivePosts * 1.0 / NULLIF(UPS.TotalPosts, 0)) >= 0.5) 
ORDER BY RU.Reputation DESC, UPS.AvgScore DESC;
