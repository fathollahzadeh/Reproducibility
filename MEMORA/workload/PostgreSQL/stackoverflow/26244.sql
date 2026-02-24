
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        U1.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN Users U1 ON p.OwnerUserId = U1.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    INNER JOIN Tags t ON tag = t.TagName
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, U1.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TagPopularity AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM
        Tags t
    LEFT JOIN Posts p ON t.Id = p.Id  
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        t.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagPopularity
    WHERE
        PostCount > 0
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.TotalScore
FROM
    RankedPosts rp
JOIN
    TopTags tt ON tt.TagName = ANY(rp.Tags)
WHERE
    rp.Rank <= 10  
ORDER BY
    rp.Score DESC, tt.TotalViews DESC;
