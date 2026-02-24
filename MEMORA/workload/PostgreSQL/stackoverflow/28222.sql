
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))) AS TagCount
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1  
        AND u.Reputation > 50  
),
PopularTags AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS TagFrequency
    FROM
        Posts
    WHERE
        PostTypeId = 1
    GROUP BY
        Tag
    ORDER BY
        TagFrequency DESC
    LIMIT 10
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        pt.Tag AS PopularTag
    FROM
        RankedPosts rp
    JOIN
        PopularTags pt ON pt.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
    WHERE
        rp.Rank = 1  
)

SELECT
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagCount,
    pd.PopularTag
FROM
    PostDetails pd
ORDER BY
    pd.Score DESC, pd.ViewCount DESC;
