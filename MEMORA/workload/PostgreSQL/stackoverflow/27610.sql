
WITH TagStats AS (
    SELECT
        UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
PopularTags AS (
    SELECT
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagStats
    WHERE
        PostCount > 5  
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS Owner
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
        AND p.PostTypeId = 1  
),
TagPostMapping AS (
    SELECT
        tp.Tag AS PopularTag,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostType,
        rp.Owner
    FROM
        PopularTags tp
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%', tp.Tag, '%')
    JOIN
        RecentPosts rp ON rp.PostId = p.Id
),
FinalResults AS (
    SELECT
        tpm.PopularTag,
        COUNT(tpm.PostId) AS RelatedPostCount,
        STRING_AGG(rp.Title, '; ') AS RelatedPostTitles,
        MAX(rp.CreationDate) AS LatestPostDate
    FROM
        TagPostMapping tpm
    JOIN
        RecentPosts rp ON tpm.PostId = rp.PostId
    GROUP BY
        tpm.PopularTag
)

SELECT
    *,
    DENSE_RANK() OVER (ORDER BY RelatedPostCount DESC) AS TagPopularityRank
FROM
    FinalResults
ORDER BY
    RelatedPostCount DESC;
