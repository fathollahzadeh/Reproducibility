WITH PostTagCounts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerDisplayName,
        P.ViewCount,
        COUNT(T.TagName) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM
        Posts P
    LEFT JOIN
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS tag (TagName) ON TRUE
    LEFT JOIN
        Tags T ON T.TagName = tag.TagName
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.OwnerDisplayName, P.ViewCount
),
RecentClosedPosts AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        U.DisplayName AS ClosedBy
    FROM
        PostHistory PH
    JOIN
        Posts P ON PH.PostId = P.Id
    JOIN
        Users U ON PH.UserId = U.Id
    WHERE
        PH.PostHistoryTypeId = 10 
        AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '30 days'
),
TopContributors AS (
    SELECT
        U.Id,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        U.Id, U.DisplayName
    ORDER BY
        QuestionCount DESC
    LIMIT 10
)

SELECT
    PTC.PostId,
    PTC.Title,
    PTC.CreationDate,
    PTC.OwnerDisplayName,
    PTC.TagCount,
    PTC.TagList,
    RCP.CreationDate AS ClosedDate,
    RCP.ClosedBy,
    TCC.DisplayName AS TopContributor,
    TCC.QuestionCount,
    TCC.TotalViews
FROM
    PostTagCounts PTC
LEFT JOIN
    RecentClosedPosts RCP ON PTC.PostId = RCP.PostId
LEFT JOIN
    TopContributors TCC ON PTC.OwnerDisplayName = TCC.DisplayName
ORDER BY
    PTC.CreationDate DESC
LIMIT 50;