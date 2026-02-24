
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(V.UpModCount, 0)) AS TotalUpvotes,
        SUM(COALESCE(V.DownModCount, 0)) AS TotalDownvotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpModCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownModCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostsWithTags AS (
    SELECT 
        P.*,
        STRING_AGG(T.TagName, ', ') AS TagsAggregated
    FROM Posts P
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName
    ) T ON TRUE
    GROUP BY P.Id
),
TopPosts AS (
    SELECT 
        PW.*,
        RANK() OVER (PARTITION BY PW.OwnerUserId ORDER BY PW.ViewCount DESC) AS Rank
    FROM PostsWithTags PW
    WHERE PW.ViewCount IS NOT NULL
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.TotalUpvotes,
    UA.TotalDownvotes,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    TP.Title,
    TP.ViewCount,
    TP.CreationDate,
    TP.TagsAggregated
FROM UserActivity UA
JOIN TopPosts TP ON UA.UserId = TP.OwnerUserId
WHERE UA.Reputation > 1000 
    AND TP.Rank <= 3
    AND (TP.ClosedDate IS NULL OR 
    (TP.ClosedDate IS NOT NULL AND TP.CreationDate < '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'))
ORDER BY UA.Reputation DESC, TP.ViewCount DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
