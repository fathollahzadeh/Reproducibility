
WITH TagFrequencies AS (
    SELECT
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
FrequentTags AS (
    SELECT
        TagName,
        PostCount
    FROM
        TagFrequencies
    WHERE
        PostCount > 5 
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        U.Reputation > 1000 
    GROUP BY
        U.Id, U.DisplayName
),
TaggedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        F.TagName,
        P.OwnerUserId
    FROM
        Posts P
    JOIN
        FrequentTags F ON F.TagName = ANY(string_to_array(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><'))
    WHERE
        P.PostTypeId = 1 
)
SELECT
    TU.DisplayName,
    COUNT(DISTINCT TP.PostId) AS TaggedPostCount,
    SUM(TP.ViewCount) AS TotalViewsFromTaggedPosts,
    SUM(TP.Score) AS TotalScoreFromTaggedPosts,
    SUM(TU.TotalViews) AS TotalViewsByUser,
    SUM(TU.TotalScore) AS TotalScoreByUser,
    TU.TotalComments
FROM
    TopUsers TU
JOIN
    TaggedPosts TP ON TU.UserId = TP.OwnerUserId
GROUP BY
    TU.DisplayName, TU.TotalViews, TU.TotalScore, TU.TotalComments
ORDER BY
    TaggedPostCount DESC, TotalViewsFromTaggedPosts DESC;
