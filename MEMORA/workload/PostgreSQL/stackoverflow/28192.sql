
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.PostType,
        rp.TagCount
    FROM
        RankedPosts rp
    WHERE
        rp.UserPostRank <= 5 
),

TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(f.PostId) AS PostCount,
        SUM(f.ViewCount) AS TotalViews,
        SUM(f.Score) AS TotalScore
    FROM
        Users u
    JOIN
        FilteredPosts f ON u.Id = f.PostId
    GROUP BY
        u.Id, u.DisplayName
    ORDER BY
        PostCount DESC, TotalViews DESC
    LIMIT 10
)

SELECT
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.TotalScore,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CreationDate
FROM
    TopUsers tu
JOIN
    FilteredPosts fp ON tu.UserId = fp.PostId
ORDER BY
    tu.TotalScore DESC, fp.ViewCount DESC;
