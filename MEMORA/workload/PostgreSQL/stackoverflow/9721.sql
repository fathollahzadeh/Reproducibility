WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    pt.TagCount,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    CASE 
        WHEN rp.RankByScore <= 5 THEN 'Top 5 by Score'
        WHEN rp.RankByViews <= 5 THEN 'Top 5 by Views'
        ELSE 'Other'
    END AS RankCategory
FROM 
    RankedPosts rp
JOIN 
    PostTagCounts pt ON rp.PostId = pt.PostId
JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.RankByScore <= 10 OR rp.RankByViews <= 10
ORDER BY 
    rp.RankByScore, rp.RankByViews;