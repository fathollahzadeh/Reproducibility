
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        CARDINALITY(string_to_array(p.Tags, '><')) AS TagCount,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
PostUserDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.TagCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users pu ON pu.Id = (
            SELECT OwnerUserId 
            FROM Posts 
            WHERE Id = rp.PostId
        )
    WHERE 
        rp.Rank <= 3 
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10 
)

SELECT 
    pud.OwnerDisplayName,
    pud.Title,
    pud.ViewCount,
    pud.TagCount,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews
FROM 
    PostUserDetails pud
JOIN 
    TagStatistics ts ON ts.PostCount > 0
ORDER BY 
    ts.TotalViews DESC, 
    pud.ViewCount DESC;
