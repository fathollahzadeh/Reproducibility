WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        rp.Rank <= 5  
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.CreationDate, rp.Score, rp.ViewCount, u.DisplayName
),
AggregatedData AS (
    SELECT 
        Tags,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        AVG(CommentCount) AS AvgComments,
        AVG(BadgeCount) AS AvgBadges
    FROM 
        TopPosts
    GROUP BY 
        Tags
)
SELECT 
    ad.Tags,
    ad.PostCount,
    ad.TotalScore,
    ad.TotalViews,
    ad.AvgComments,
    ad.AvgBadges,
    STRING_AGG(tp.Title, ', ') AS TopPostTitles
FROM 
    AggregatedData ad
JOIN 
    TopPosts tp ON tp.Tags = ad.Tags
GROUP BY 
    ad.Tags, ad.PostCount, ad.TotalScore, ad.TotalViews, ad.AvgComments, ad.AvgBadges
ORDER BY 
    ad.TotalScore DESC, 
    ad.TotalViews DESC;