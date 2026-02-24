
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag, 
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),

TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgViewCount,
        AvgScore,
        RANK() OVER (ORDER BY AvgScore DESC) AS RankScore
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10 
),

PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        tt.Tag,
        tt.RankScore
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON tt.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><'))
    WHERE 
        rp.TagRank <= 3 
)

SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.Tag,
    pp.RankScore,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AvgBounty 
FROM 
    PopularPosts pp
LEFT JOIN 
    Comments c ON pp.PostId = c.PostId
LEFT JOIN 
    Votes v ON pp.PostId = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    pp.PostId, pp.Title, pp.ViewCount, pp.Score, pp.Tag, pp.RankScore
ORDER BY 
    pp.RankScore, pp.Score DESC;
