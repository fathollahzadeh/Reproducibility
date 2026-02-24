WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredRanks AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COUNT(*) OVER (PARTITION BY rp.RankByViews) AS TotalPosts
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 3
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Body,
    fr.ViewCount,
    fr.OwnerDisplayName,
    (SELECT 
        STRING_AGG(DISTINCT c.Text, '; ') 
     FROM 
        Comments c 
     WHERE 
        c.PostId = fr.PostId) AS CommentsText,
    fr.TotalPosts,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = fr.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = fr.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    FilteredRanks fr
ORDER BY 
    fr.ViewCount DESC;