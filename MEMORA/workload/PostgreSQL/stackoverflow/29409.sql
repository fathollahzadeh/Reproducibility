
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.OwnerUserId, p.Tags, p.Score
),
RecentActivity AS (
    SELECT 
        PostId,
        MAX(LastActivityDate) AS MostRecentActivity
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),
CombinedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        ra.MostRecentActivity
    FROM 
        RankedPosts rp
    JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.OwnerDisplayName,
    cp.CommentCount,
    cp.VoteCount,
    CASE 
        WHEN cp.LastActivityDate < cp.MostRecentActivity THEN 'Updated'
        ELSE 'Stale'
    END AS PostStatus,
    INITCAP(SUBSTR(cp.Body, 1, 100)) AS PreviewBody  
FROM 
    CombinedPosts cp
WHERE 
    cp.VoteCount > 10  
ORDER BY 
    cp.CommentCount DESC,
    cp.VoteCount DESC;
